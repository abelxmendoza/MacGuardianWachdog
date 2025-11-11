import SwiftUI

struct ExecutionHistoryView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var selectedExecution: CommandExecution?
    @State private var searchText: String = ""
    @State private var filterStatus: ExecutionFilter = .all
    
    var body: some View {
        HSplitView {
            // History List
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    LogoView(size: 32)
                    Text("Execution History")
                        .font(.headline)
                        .foregroundColor(.themeText)
                    Spacer()
                    Text("\(workspace.executionHistory.count)")
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
                .padding()
                
                // Filter buttons
                HStack(spacing: 8) {
                    FilterButton(title: "All", filter: .all, selected: $filterStatus)
                    FilterButton(title: "Success", filter: .success, selected: $filterStatus)
                    FilterButton(title: "Failed", filter: .failed, selected: $filterStatus)
                }
                .padding(.horizontal)
                
                SearchField(text: $searchText, placeholder: "Search history...")
                    .padding(.horizontal)
                
                List(selection: $selectedExecution) {
                    ForEach(filteredExecutions) { execution in
                        ExecutionRow(execution: execution)
                            .tag(execution)
                    }
                }
                .listStyle(.sidebar)
                .background(Color.themeDarkGray)
            }
            .frame(minWidth: 300, idealWidth: 350)
            .background(Color.themeDarkGray)
            
            // Execution Details
            if let execution = selectedExecution {
                ExecutionDetailView(execution: execution)
            } else {
                ContentUnavailableView(
                    "Select an Execution",
                    systemImage: "clock",
                    description: Text("Choose an execution from the history to view details")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBlack)
            }
        }
        .background(Color.themeBlack)
    }
    
    private var filteredExecutions: [CommandExecution] {
        var executions = workspace.executionHistory
        
        // Apply status filter
        switch filterStatus {
        case .all:
            break
        case .success:
            executions = executions.filter {
                if case .finished = $0.state { return true }
                return false
            }
        case .failed:
            executions = executions.filter {
                if case .failed = $0.state { return true }
                return false
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            executions = executions.filter {
                $0.tool.name.localizedCaseInsensitiveContains(searchText) ||
                $0.tool.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return executions
    }
}

enum ExecutionFilter {
    case all, success, failed
}

struct FilterButton: View {
    let title: String
    let filter: ExecutionFilter
    @Binding var selected: ExecutionFilter
    
    var body: some View {
        Button {
            selected = filter
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(selected == filter ? .themePurple : .gray)
    }
}

struct ExecutionRow: View {
    let execution: CommandExecution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(execution.tool.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.themeText)
                Spacer()
            }
            
            Text(formatDate(execution.startedAt))
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
            
            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
                Spacer()
                if let finishedAt = execution.finishedAt {
                    Text(formatDuration(execution.startedAt, finishedAt))
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch execution.state {
        case .finished: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        default: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch execution.state {
        case .finished: return .green
        case .failed: return .red
        case .running: return .themePurple
        default: return .themeTextSecondary
        }
    }
    
    private var statusText: String {
        switch execution.state {
        case .finished: return "Success"
        case .failed: return "Failed"
        case .running: return "Running"
        default: return "Idle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ start: Date, _ end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else if duration < 3600 {
            return String(format: "%.1fm", duration / 60)
        } else {
            return String(format: "%.1fh", duration / 3600)
        }
    }
}

struct ExecutionDetailView: View {
    let execution: CommandExecution
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        LogoView(size: 40)
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(execution.tool.name)
                                .font(.title.bold())
                                .foregroundColor(.themeText)
                            Text(execution.tool.description)
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.themePurpleDark)
                    
                    // Execution Info
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Status", value: statusText, color: statusColor)
                        InfoRow(label: "Started", value: formatDate(execution.startedAt))
                        if let finishedAt = execution.finishedAt {
                            InfoRow(label: "Finished", value: formatDate(finishedAt))
                            InfoRow(label: "Duration", value: formatDuration(execution.startedAt, finishedAt))
                        }
                        InfoRow(label: "Script", value: execution.tool.relativePath)
                    }
                }
                .padding()
                .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.themePurpleDark, lineWidth: 1)
                )
                
                // Output Log
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Output Log")
                            .font(.headline)
                            .foregroundColor(.themeText)
                        Spacer()
                        Button {
                            copyLog()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .tint(.themePurple)
                    }
                    
                    ScrollView {
                        Text(execution.log.isEmpty ? "No output" : execution.log)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.themeText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 400)
                    .background(Color.themeBlack, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.themePurpleDark, lineWidth: 1)
                )
            }
            .padding()
        }
        .background(Color.themeBlack)
    }
    
    private var statusIcon: String {
        switch execution.state {
        case .finished: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        default: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch execution.state {
        case .finished: return .green
        case .failed: return .red
        case .running: return .themePurple
        default: return .themeTextSecondary
        }
    }
    
    private var statusText: String {
        switch execution.state {
        case .finished: return "Completed Successfully"
        case .failed(let error): return "Failed: \(error)"
        case .running: return "Running"
        default: return "Idle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ start: Date, _ end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        if duration < 60 {
            return String(format: "%.2f seconds", duration)
        } else if duration < 3600 {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        } else {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
    
    private func copyLog() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(execution.log, forType: .string)
        #endif
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var color: Color = .themeText
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

