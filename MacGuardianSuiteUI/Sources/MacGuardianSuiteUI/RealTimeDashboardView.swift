import SwiftUI

struct RealTimeDashboardView: View {
    @StateObject private var monitorService = RealTimeMonitorService()
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
    
    var filteredEvents: [ThreatEvent] {
        let events = monitorService.events
        
        switch selectedFilter {
        case .all:
            return events
        case .critical:
            return events.filter { $0.severity == "critical" }
        case .high:
            return events.filter { $0.severity == "high" }
        case .medium:
            return events.filter { $0.severity == "medium" }
        case .filesystem:
            return events.filter { $0.type == "filesystem" }
        case .process:
            return events.filter { $0.type == "process" }
        case .network:
            return events.filter { $0.type == "network" }
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
                    
                    // Monitoring status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(monitorService.isMonitoring ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(monitorService.isMonitoring ? "Monitoring" : "Stopped")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                .padding(.horizontal)
                
                // Stats cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total Events",
                        value: "\(monitorService.events.count)",
                        icon: "bell.fill",
                        color: .themePurple
                    )
                    StatCard(
                        title: "Critical",
                        value: "\(monitorService.criticalEvents.count)",
                        icon: "exclamationmark.octagon.fill",
                        color: .red
                    )
                    StatCard(
                        title: "High Severity",
                        value: "\(monitorService.highSeverityEvents.count)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                    StatCard(
                        title: "Last Update",
                        value: monitorService.lastUpdate != nil ? formatTime(monitorService.lastUpdate!) : "Never",
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
                    
                    // Start/Stop monitoring
                    Button {
                        if monitorService.isMonitoring {
                            monitorService.stopMonitoring()
                        } else {
                            monitorService.startMonitoring()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: monitorService.isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                            Text(monitorService.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                        }
                        .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(monitorService.isMonitoring ? .red : .green)
                    
                    // Refresh button
                    Button {
                        monitorService.loadEvents()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.themePurple)
                    
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
                            ThreatEventRow(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.themeBlack)
        .onAppear {
            monitorService.startMonitoring()
        }
        .onDisappear {
            // Keep monitoring running in background
            // monitorService.stopMonitoring()
        }
        .alert("Clear All Events?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                monitorService.clearEvents()
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

struct ThreatEventRow: View {
    let event: ThreatEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Severity indicator
                Circle()
                    .fill(severityColor)
                    .frame(width: 12, height: 12)
                
                // Type badge
                Text(event.type.uppercased())
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
                    .background(severityColor)
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
                    if let pid = event.details.pid {
                        DetailRow(label: "PID", value: "\(pid)")
                    }
                    if let process = event.details.process {
                        DetailRow(label: "Process", value: process)
                    }
                    if let cpu = event.details.cpu_percent {
                        DetailRow(label: "CPU", value: String(format: "%.1f%%", cpu))
                    }
                    if let port = event.details.port {
                        DetailRow(label: "Port", value: "\(port)")
                    }
                    if let remote = event.details.remote {
                        DetailRow(label: "Remote", value: remote)
                    }
                    if let ip = event.details.ip {
                        DetailRow(label: "IP", value: ip)
                    }
                    if let directory = event.details.directory {
                        DetailRow(label: "Directory", value: directory)
                    }
                    if let fileCount = event.details.file_count {
                        DetailRow(label: "Files Changed", value: "\(fileCount)")
                    }
                    if let files = event.details.files, !files.isEmpty {
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
                .stroke(severityColor.opacity(0.5), lineWidth: 2)
        )
    }
    
    private var severityColor: Color {
        switch event.severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
    
    private var typeColor: Color {
        switch event.type.lowercased() {
        case "filesystem": return .blue
        case "process": return .purple
        case "network": return .cyan
        case "system": return .gray
        default: return .themePurple
        }
    }
    
    private var hasDetails: Bool {
        event.details.pid != nil ||
        event.details.process != nil ||
        event.details.cpu_percent != nil ||
        event.details.port != nil ||
        event.details.remote != nil ||
        event.details.ip != nil ||
        event.details.directory != nil ||
        event.details.file_count != nil ||
        (event.details.files != nil && !event.details.files!.isEmpty)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
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

