import SwiftUI

struct IncidentTimelineView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var timelineData: TimelineData?
    @State private var selectedFilter: TimelineFilter = .all
    @State private var isLoading = false
    
    enum TimelineFilter: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case high = "High"
        case process = "Process"
        case network = "Network"
        case filesystem = "Filesystem"
        case ids = "IDS"
    }
    
    var filteredEvents: [TimelineEvent] {
        guard let timeline = timelineData else { return [] }
        var events = timeline.timeline
        
        switch selectedFilter {
        case .all:
            break
        case .critical:
            events = events.filter { $0.severity.lowercased() == "critical" }
        case .high:
            events = events.filter { $0.severity.lowercased() == "high" }
        case .process:
            events = events.filter { $0.type == "process" }
        case .network:
            events = events.filter { $0.type == "network" }
        case .filesystem:
            events = events.filter { $0.type == "fs" || $0.type == "filesystem" }
        case .ids:
            events = events.filter { $0.type == "ids" || $0.type == "correlation" }
        }
        
        return events
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title)
                    .foregroundColor(.themePurple)
                VStack(alignment: .leading) {
                    Text("Incident Timeline")
                        .font(.title.bold())
                    Text("Chronological security events")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Button {
                    loadTimeline()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.themePurple)
                .disabled(isLoading)
            }
            .padding()
            
            Divider()
            
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TimelineFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Timeline
            if isLoading {
                ProgressView("Loading timeline...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let timeline = timelineData {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Statistics
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Total Events",
                                value: "\(timeline.totalEvents)",
                                icon: "list.bullet",
                                color: .themePurple
                            )
                            StatCard(
                                title: "Critical",
                                value: "\(timeline.severityCounts["critical"] ?? 0)",
                                icon: "exclamationmark.triangle.fill",
                                color: .red
                            )
                            StatCard(
                                title: "High",
                                value: "\(timeline.severityCounts["high"] ?? 0)",
                                icon: "exclamationmark.circle.fill",
                                color: .orange
                            )
                        }
                        .padding()
                        
                        // Events grouped by date
                        ForEach(groupedEvents, id: \.date) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.date)
                                    .font(.headline.bold())
                                    .foregroundColor(.themeTextSecondary)
                                    .padding(.horizontal)
                                
                                ForEach(group.events) { event in
                                    TimelineEventRow(event: event)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "clock",
                    title: "No timeline data",
                    message: "Load timeline to view security events"
                )
            }
        }
        .background(Color.themeBlack)
        .onAppear {
            loadTimeline()
        }
    }
    
    private var groupedEvents: [EventGroup] {
        let events = filteredEvents
        let grouped = Dictionary(grouping: events) { event in
            event.time.prefix(10) // Date part
        }
        
        return grouped.map { date, events in
            EventGroup(date: String(date), events: events)
        }.sorted { $0.date > $1.date }
    }
    
    private func loadTimeline() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let timelinePath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".macguardian/timeline.json")
            
            if let data = try? Data(contentsOf: timelinePath),
               let timeline = try? JSONDecoder().decode(TimelineData.self, from: data) {
                DispatchQueue.main.async {
                    self.timelineData = timeline
                    self.isLoading = false
                }
            } else {
                // Try to generate timeline
                let scriptPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/outputs/timeline_formatter.py"
                let eventDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".macguardian/events")
                let outputPath = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".macguardian/timeline.json")
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
                process.arguments = [scriptPath, eventDir.path, outputPath.path]
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    if let data = try? Data(contentsOf: outputPath),
                       let timeline = try? JSONDecoder().decode(TimelineData.self, from: data) {
                        DispatchQueue.main.async {
                            self.timelineData = timeline
                            self.isLoading = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

struct TimelineData: Codable {
    let timestamp: String
    let totalEvents: Int
    let eventTypes: [String: Int]
    let severityCounts: [String: Int]
    let timeline: [TimelineEvent]
    
    enum CodingKeys: String, CodingKey {
        case timestamp, totalEvents = "total_events"
        case eventTypes = "event_types"
        case severityCounts = "severity_counts"
        case timeline
    }
}

struct TimelineEvent: Codable, Identifiable {
    let id = UUID()
    let time: String
    let type: String
    let severity: String
    let message: String
    let details: [String: AnyCodable]
}

struct EventGroup {
    let date: String
    let events: [TimelineEvent]
}

struct TimelineEventRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.type.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.themeTextSecondary)
                    Spacer()
                    Text(formatTime(event.time))
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
                
                Text(event.message)
                    .font(.subheadline)
                    .foregroundColor(.themeText)
                
                if event.severity.lowercased() != "info" {
                    HStack {
                        Image(systemName: severityIcon)
                            .font(.caption2)
                        Text(event.severity.uppercased())
                            .font(.caption2.bold())
                    }
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(10)
    }
    
    private var severityColor: Color {
        switch event.severity.lowercased() {
        case "critical": return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
        case "high": return Color(red: 0.8, green: 0.3, blue: 0.5) // Purple-red blend
        case "warning", "medium": return .themePurpleLight // Lighter purple
        default: return .themePurple // Base purple
        }
    }
    
    private var severityIcon: String {
        switch event.severity.lowercased() {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func formatTime(_ time: String) -> String {
        // Extract time from ISO8601 timestamp
        if time.count > 10 {
            return String(time.dropFirst(11).prefix(5)) // HH:MM
        }
        return time
    }
}

