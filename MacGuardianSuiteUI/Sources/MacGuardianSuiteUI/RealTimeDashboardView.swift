import SwiftUI

struct RealTimeDashboardView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var selectedFilter: EventFilter = .all
    @State private var showClearConfirmation = false
    
    enum EventFilter: String, CaseIterable {
        case all = "All Events"
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case filesystem = "Filesystem"
        case process = "Process"
        case network = "Network"
    }
    
    var filteredEvents: [MacGuardianEvent] {
        let events = liveService.events
        
        switch selectedFilter {
        case .all:
            return events
        case .critical:
            return liveService.criticalEvents
        case .high:
            return liveService.highSeverityEvents
        case .medium:
            return events.filter { $0.severity.lowercased() == "medium" }
        case .filesystem:
            return liveService.filesystemEvents
        case .process:
            return liveService.processEvents
        case .network:
            return liveService.networkEvents
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    LogoView(size: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Real-Time Threat Monitor")
                            .font(.title.bold())
                            .foregroundColor(.themeText)
                        Text("Live security event feed from monitoring daemon")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    
                    // Connection status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(liveService.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(liveService.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                .padding(.horizontal)
                
                // Stats cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total Events",
                        value: "\(liveService.events.count)",
                        icon: "bell.fill",
                        color: .themePurple
                    )
                    StatCard(
                        title: "Critical",
                        value: "\(liveService.criticalEvents.count)",
                        icon: "exclamationmark.octagon.fill",
                        color: Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
                    )
                    StatCard(
                        title: "High Severity",
                        value: "\(liveService.highSeverityEvents.count)",
                        icon: "exclamationmark.triangle.fill",
                        color: Color(red: 0.8, green: 0.3, blue: 0.5) // Purple-red blend
                    )
                    StatCard(
                        title: "Last Update",
                        value: liveService.lastUpdate != nil ? formatTime(liveService.lastUpdate!) : "Never",
                        icon: "clock.fill",
                        color: .themePurple
                    )
                }
                .padding(.horizontal)
                
                // Controls
                HStack(spacing: 12) {
                    // Filter picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(EventFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 200)
                    
                    Spacer()
                    
                    // Clear events
                    Button {
                        showClearConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Clear")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.horizontal)
                
                // Event list
                if filteredEvents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green.opacity(0.5))
                        Text("No events found")
                            .font(.headline)
                            .foregroundColor(.themeTextSecondary)
                        Text("Security events will appear here when detected by the monitoring daemon")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredEvents.prefix(100)) { event in
                            EventRowView(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.themeBlack)
        .alert("Clear All Events?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await liveService.clearEvents()
                }
            }
        } message: {
            Text("This will permanently delete all events. This action cannot be undone.")
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EventRowView: View {
    let event: MacGuardianEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Severity indicator
                Circle()
                    .fill(event.severityColor)
                    .frame(width: 12, height: 12)
                
                // Type badge
                Text(event.event_type.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor)
                    .cornerRadius(6)
                
                // Severity badge
                Text(event.severity.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.severityColor)
                    .cornerRadius(6)
                
                Spacer()
                
                // Timestamp
                if let date = event.date {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
            }
            
            // Message
            Text(event.message)
                .font(.subheadline.bold())
                .foregroundColor(.themeText)
            
            // Details
            if hasDetails {
                VStack(alignment: .leading, spacing: 6) {
                    if let pid = event.context["pid"]?.value as? Int {
                        MonitorDetailRow(label: "PID", value: "\(pid)")
                    }
                    if let process = event.context["process"]?.value as? String ?? event.context["process_name"]?.value as? String {
                        MonitorDetailRow(label: "Process", value: process)
                    }
                    if let cpu = event.context["cpu_percent"]?.value as? Double ?? event.context["cpu"]?.value as? Double {
                        MonitorDetailRow(label: "CPU", value: String(format: "%.1f%%", cpu))
                    }
                    if let port = event.context["port"]?.value as? Int {
                        MonitorDetailRow(label: "Port", value: "\(port)")
                    }
                    if let remote = event.context["remote"]?.value as? String ?? event.context["remote_ip"]?.value as? String {
                        MonitorDetailRow(label: "Remote", value: remote)
                    }
                    if let ip = event.context["ip"]?.value as? String ?? event.context["local_ip"]?.value as? String {
                        MonitorDetailRow(label: "IP", value: ip)
                    }
                    if let directory = event.context["directory"]?.value as? String ?? event.context["path"]?.value as? String {
                        MonitorDetailRow(label: "Directory", value: directory)
                    }
                    if let fileCount = event.context["file_count"]?.value as? Int {
                        MonitorDetailRow(label: "Files Changed", value: "\(fileCount)")
                    }
                    if let files = event.context["files"]?.value as? [String] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Files:")
                                .font(.caption.bold())
                                .foregroundColor(.themeTextSecondary)
                            ForEach(files.prefix(5), id: \.self) { file in
                                Text(file)
                                    .font(.caption)
                                    .foregroundColor(.themeTextSecondary)
                                    .lineLimit(1)
                            }
                            if files.count > 5 {
                                Text("... and \(files.count - 5) more")
                                    .font(.caption)
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.themeDarkGray.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(event.severityColor.opacity(0.5), lineWidth: 2)
        )
    }
    
    private var typeColor: Color {
        switch event.event_type.lowercased() {
        case "file_change", "filesystem": return .themePurple
        case "process_spawn", "process": return .themePurpleLight
        case "network_connection", "network": return .themePurple
        case "system": return .themeTextSecondary
        default: return .themePurple
        }
    }
    
    private var hasDetails: Bool {
        event.context["pid"]?.value != nil ||
        event.context["process"]?.value != nil ||
        event.context["process_name"]?.value != nil ||
        event.context["cpu_percent"]?.value != nil ||
        event.context["cpu"]?.value != nil ||
        event.context["port"]?.value != nil ||
        event.context["remote"]?.value != nil ||
        event.context["remote_ip"]?.value != nil ||
        event.context["ip"]?.value != nil ||
        event.context["local_ip"]?.value != nil ||
        event.context["directory"]?.value != nil ||
        event.context["path"]?.value != nil ||
        event.context["file_count"]?.value != nil ||
        (event.context["files"]?.value as? [String] != nil)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MonitorDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption.bold())
                .foregroundColor(.themeTextSecondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.themeText)
            Spacer()
        }
    }
}

#Preview {
    RealTimeDashboardView()
}

