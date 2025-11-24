import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var securityScore: Int = 85
    @State private var lastScanDate: Date? = nil
    @State private var activeThreats: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Logo
                HStack {
                    LogoView(size: 80)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MacGuardian Suite")
                            .font(.title.bold())
                            .foregroundColor(.themeText)
                        Text("Security Dashboard")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Security Score Card
                SecurityScoreCard(score: securityScore)
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatCard(
                        title: "Active Threats",
                        value: "\(activeThreats)",
                        icon: "exclamationmark.triangle.fill",
                        color: activeThreats > 0 ? .red : .green
                    )
                    StatCard(
                        title: "Last Scan",
                        value: lastScanDate != nil ? formatDate(lastScanDate!) : "Never",
                        icon: "clock.fill",
                        color: .themePurple
                    )
                    StatCard(
                        title: "Total Scans",
                        value: "\(workspace.executionHistory.count)",
                        icon: "chart.bar.fill",
                        color: .themePurple
                    )
                }
                
                // Recent Scans
                RecentScansCard(executions: Array(workspace.executionHistory.prefix(5)))
                
                // Quick Actions
                QuickActionsCard(workspace: workspace)
                
                // Process Killer Quick Access
                ProcessKillerQuickAccess()
                    .environmentObject(workspace)
                
                // Cache Cleaner Quick Access
                CacheCleanerQuickAccess()
                    .environmentObject(workspace)
                
                // System Health
                SystemHealthCard()
            }
            .padding()
        }
        .background(Color.themeBlack)
        .onAppear {
            loadDashboardData()
        }
    }
    
    private func loadDashboardData() {
        // Find last scan date
        lastScanDate = workspace.executionHistory
            .first { $0.finishedAt != nil }?
            .finishedAt
        
        // Calculate security score (simplified)
        let successfulScans = workspace.executionHistory.filter {
            if case .finished = $0.state { return true }
            return false
        }.count
        let totalScans = max(workspace.executionHistory.count, 1)
        securityScore = Int((Double(successfulScans) / Double(totalScans)) * 100)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SecurityScoreCard: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Security Score")
                    .font(.headline)
                    .foregroundColor(.themeText)
                Spacer()
            }
            
            ZStack {
                Circle()
                    .stroke(Color.themePurpleDark, lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: score)
                
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(scoreColor)
                    Text("%")
                        .font(.title3)
                        .foregroundColor(.themeTextSecondary)
                }
            }
            
            Text(scoreDescription)
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private var scoreDescription: String {
        if score >= 80 { return "System is secure" }
        if score >= 60 { return "Some issues detected" }
        return "Action required"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.themeText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

struct RecentScansCard: View {
    let executions: [CommandExecution]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                    .foregroundColor(.themeText)
                Spacer()
            }
            
            if executions.isEmpty {
                Text("No scans yet")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(executions) { execution in
                    ScanRow(execution: execution)
                }
            }
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

struct ScanRow: View {
    let execution: CommandExecution
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(execution.tool.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.themeText)
                Text(formatDate(execution.startedAt))
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
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
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct QuickActionsCard: View {
    @ObservedObject var workspace: WorkspaceState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.themeText)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Security Scan",
                    icon: "shield.checkered",
                    color: .themePurple
                ) {
                    // Navigate to tools and find security scan
                    workspace.selectedView = .tools
                }
                
                QuickActionButton(
                    title: "Generate Report",
                    icon: "doc.text.fill",
                    color: .themePurple
                ) {
                    // Navigate to reports
                    workspace.selectedView = .reports
                }
                
                QuickActionButton(
                    title: "View Reports",
                    icon: "folder.fill",
                    color: .themePurple
                ) {
                    workspace.selectedView = .reports
                }
                
                QuickActionButton(
                    title: "Kill Processes",
                    icon: "xmark.circle.fill",
                    color: .red
                ) {
                    workspace.showProcessKiller = true
                }
                
                QuickActionButton(
                    title: "Clean Cache",
                    icon: "trash.fill",
                    color: .orange
                ) {
                    workspace.showCacheCleaner = true
                }
            }
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

struct ProcessKillerQuickAccess: View {
    @EnvironmentObject var workspace: WorkspaceState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Process Killer")
                    .font(.headline)
                    .foregroundColor(.themeText)
                Spacer()
                Button {
                    workspace.showProcessKiller = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Open Process Killer")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            
            Text("Quickly close applications that won't quit normally. Especially useful for Cursor, Firefox, Slack, Discord, and other stubborn apps.")
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

struct CacheCleanerQuickAccess: View {
    @EnvironmentObject var workspace: WorkspaceState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cache Cleaner")
                    .font(.headline)
                    .foregroundColor(.themeText)
                Spacer()
                Button {
                    workspace.showCacheCleaner = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Open Cache Cleaner")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            
            Text("Safely clear browser caches (Safari, Chrome, Firefox, Edge) and system caches to free up disk space. Preview before cleaning.")
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.themeText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.themeBlack, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct SystemHealthCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(.headline)
                .foregroundColor(.themeText)
            
            HealthIndicator(title: "File Integrity", status: .good)
            HealthIndicator(title: "Antivirus", status: .good)
            HealthIndicator(title: "Firewall", status: .warning)
            HealthIndicator(title: "Backups", status: .good)
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

struct HealthIndicator: View {
    let title: String
    let status: HealthStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.themeText)
            Spacer()
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .good: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch status {
        case .good: return "OK"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

enum HealthStatus {
    case good, warning, error
}

