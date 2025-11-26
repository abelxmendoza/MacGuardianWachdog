import SwiftUI

struct UserAccountSecurityView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var auditResult: UserAccountAuditResult?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.title)
                        .foregroundColor(.themePurple)
                    VStack(alignment: .leading) {
                        Text("User Accounts")
                            .font(.title.bold())
                        Text("Monitor user accounts and privileges")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Button {
                        runAudit()
                    } label: {
                        Label("Run Audit", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.themePurple)
                    .disabled(isLoading)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    ProgressView("Running user account audit...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let audit = auditResult {
                    // Statistics
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Total Users",
                            value: "\(audit.currentUserCount)",
                            icon: "person.3.fill",
                            color: .themePurple
                        )
                        StatCard(
                            title: "Admin Accounts",
                            value: "\(audit.adminAccounts)",
                            icon: "key.fill",
                            color: audit.adminAccounts > 1 ? .orange : .themePurple
                        )
                        StatCard(
                            title: "Root Accounts",
                            value: "\(audit.rootAccounts)",
                            icon: "exclamationmark.shield.fill",
                            color: audit.rootAccounts > 0 ? .red : .themePurple
                        )
                    }
                    .padding()
                    
                    // Issues
                    if audit.issuesFound > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Security Issues")
                                .font(.headline.bold())
                            
                            if audit.currentUserCount != audit.baselineUserCount {
                                IssueCard(
                                    title: "User Count Changed",
                                    message: "\(audit.baselineUserCount) → \(audit.currentUserCount)",
                                    severity: .warning
                                )
                            }
                            
                            if audit.rootAccounts > 0 {
                                IssueCard(
                                    title: "UID 0 Accounts Detected",
                                    message: "Root-level accounts found",
                                    severity: .critical
                                )
                            }
                            
                            if audit.adminAccounts != audit.baselineAdminCount {
                                IssueCard(
                                    title: "Admin Count Changed",
                                    message: "\(audit.baselineAdminCount) → \(audit.adminAccounts)",
                                    severity: .warning
                                )
                            }
                        }
                        .padding()
                        .background(Color.themeDarkGray)
                        .cornerRadius(12)
                    }
                    
                    // User List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Users")
                            .font(.headline.bold())
                        
                        // Would load actual user list here
                        Text("User enumeration would appear here")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding()
                    .background(Color.themeDarkGray)
                    .cornerRadius(12)
                } else {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No audit results",
                        message: "Run an audit to check user account security"
                    )
                }
            }
        }
        .background(Color.themeBlack)
        .onAppear {
            loadLatestAudit()
        }
    }
    
    private func runAudit() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let scriptPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/auditors/user_account_auditor.sh"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath, "audit"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let auditDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".macguardian/audits")
                
                if let files = try? FileManager.default.contentsOfDirectory(at: auditDir, includingPropertiesForKeys: [.creationDateKey]),
                   let latestFile = files.filter({ $0.lastPathComponent.contains("user_accounts") })
                       .sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
                       .first,
                   let data = try? Data(contentsOf: latestFile),
                   let audit = try? JSONDecoder().decode(UserAccountAuditResult.self, from: data) {
                    DispatchQueue.main.async {
                        self.auditResult = audit
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
    
    private func loadLatestAudit() {
        let auditDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".macguardian/audits")
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: auditDir, includingPropertiesForKeys: [.creationDateKey]),
              let latestFile = files.filter({ $0.lastPathComponent.contains("user_accounts") })
                  .sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
                  .first,
              let data = try? Data(contentsOf: latestFile),
              let audit = try? JSONDecoder().decode(UserAccountAuditResult.self, from: data) else {
            return
        }
        
        auditResult = audit
    }
}

struct UserAccountAuditResult: Codable {
    let timestamp: String
    let auditType: String
    let issuesFound: Int
    let currentUserCount: Int
    let baselineUserCount: Int
    let adminAccounts: Int
    let rootAccounts: Int
    let baselineAdminCount: Int
    
    enum CodingKeys: String, CodingKey {
        case timestamp, auditType = "audit_type", issuesFound = "issues_found"
        case currentUserCount = "current_user_count", baselineUserCount = "baseline_user_count"
        case adminAccounts = "admin_accounts", rootAccounts = "root_accounts"
        case baselineAdminCount = "baseline_admin_count"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(12)
    }
}

struct IssueCard: View {
    let title: String
    let message: String
    let severity: IssueSeverity
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline.bold())
                Text(message)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.themeBlack.opacity(0.5))
        .cornerRadius(8)
    }
    
    private var severityColor: Color {
        switch severity {
        case .critical: return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
        case .warning: return .themePurpleLight // Lighter purple
        case .info: return .themePurple // Base purple
        }
    }
    
    private var severityIcon: String {
        switch severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

enum IssueSeverity {
    case critical, warning, info
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.themeTextSecondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

