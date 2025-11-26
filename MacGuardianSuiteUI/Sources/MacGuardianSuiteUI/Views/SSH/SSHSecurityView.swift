import SwiftUI

struct SSHSecurityView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var auditResult: SSHAuditResult?
    @State private var isLoading = false
    @State private var showBaselineAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "key.fill")
                        .font(.title)
                        .foregroundColor(.themePurple)
                    VStack(alignment: .leading) {
                        Text("SSH Security")
                            .font(.title.bold())
                        Text("Monitor SSH keys and configuration")
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
                    ProgressView("Running SSH audit...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let audit = auditResult {
                    // Audit Results
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Issues Found")
                                    .font(.headline)
                                    .foregroundColor(.themeTextSecondary)
                                Text("\(audit.issuesFound)")
                                    .font(.title.bold())
                                    .foregroundColor(audit.issuesFound > 0 ? .red : .green)
                            }
                            Spacer()
                            Button {
                                showBaselineAlert = true
                            } label: {
                                Label("Update Baseline", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color.themeDarkGray)
                        .cornerRadius(12)
                        
                        // Findings
                        if audit.issuesFound > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Findings")
                                    .font(.headline.bold())
                                
                                ForEach(audit.findings, id: \.id) { finding in
                                    FindingRow(finding: finding)
                                }
                            }
                            .padding()
                            .background(Color.themeDarkGray)
                            .cornerRadius(12)
                        }
                        
                        // File Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("File Status")
                                .font(.headline.bold())
                            
                            FileStatusRow(
                                name: "Authorized Keys",
                                path: audit.authorizedKeysFile,
                                status: audit.authorizedKeysStatus
                            )
                            
                            FileStatusRow(
                                name: "SSH Config",
                                path: audit.configFile,
                                status: audit.configStatus
                            )
                            
                            FileStatusRow(
                                name: "Known Hosts",
                                path: audit.knownHostsFile,
                                status: audit.knownHostsStatus
                            )
                        }
                        .padding()
                        .background(Color.themeDarkGray)
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "key")
                            .font(.system(size: 60))
                            .foregroundColor(.themeTextSecondary)
                        Text("No audit results")
                            .font(.headline)
                        Text("Run an audit to check SSH security")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .background(Color.themeBlack)
        .onAppear {
            loadLatestAudit()
        }
        .alert("Update Baseline", isPresented: $showBaselineAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Update") {
                updateBaseline()
            }
        } message: {
            Text("This will update the SSH baseline with current configuration. Continue?")
        }
    }
    
    private func runAudit() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let scriptPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/auditors/ssh_auditor.sh"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath, "audit"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                // Parse audit output and find latest JSON file
                let auditDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".macguardian/audits")
                
                if let files = try? FileManager.default.contentsOfDirectory(at: auditDir, includingPropertiesForKeys: [.creationDateKey]),
                   let latestFile = files.filter({ $0.lastPathComponent.contains("ssh_audit") })
                       .sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
                       .first,
                   let data = try? Data(contentsOf: latestFile),
                   let audit = try? JSONDecoder().decode(SSHAuditResult.self, from: data) {
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
              let latestFile = files.filter({ $0.lastPathComponent.contains("ssh_audit") })
                  .sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
                  .first,
              let data = try? Data(contentsOf: latestFile),
              let audit = try? JSONDecoder().decode(SSHAuditResult.self, from: data) else {
            return
        }
        
        auditResult = audit
    }
    
    private func updateBaseline() {
        let scriptPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/auditors/ssh_auditor.sh"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath, "baseline"]
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? process.run()
            process.waitUntilExit()
        }
    }
}

struct SSHAuditResult: Codable {
    let timestamp: String
    let auditType: String
    let issuesFound: Int
    let findings: [SSHFinding]
    let authorizedKeysFile: String
    let configFile: String
    let knownHostsFile: String
    
    var authorizedKeysStatus: FileStatus {
        issuesFound > 0 ? .modified : .ok
    }
    
    var configStatus: FileStatus {
        issuesFound > 0 ? .modified : .ok
    }
    
    var knownHostsStatus: FileStatus {
        issuesFound > 0 ? .modified : .ok
    }
    
    enum CodingKeys: String, CodingKey {
        case timestamp, auditType = "audit_type", issuesFound = "issues_found"
        case findings, authorizedKeysFile = "authorized_keys_file"
        case configFile = "config_file", knownHostsFile = "known_hosts_file"
    }
}

struct SSHFinding: Codable, Identifiable {
    let id = UUID()
    let type: String
    let message: String
    let severity: String
}

enum FileStatus {
    case ok, modified, missing
}

struct FindingRow: View {
    let finding: SSHFinding
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
            VStack(alignment: .leading) {
                Text(finding.message)
                    .font(.subheadline.bold())
                Text(finding.type)
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
        switch finding.severity.lowercased() {
        case "critical": return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
        case "high": return Color(red: 0.8, green: 0.3, blue: 0.5) // Purple-red blend
        default: return .themePurpleLight // Lighter purple
        }
    }
    
    private var severityIcon: String {
        switch finding.severity.lowercased() {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
}

struct FileStatusRow: View {
    let name: String
    let path: String
    let status: FileStatus
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            VStack(alignment: .leading) {
                Text(name)
                    .font(.subheadline.bold())
                Text(path)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            Text(statusText)
                .font(.caption.bold())
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch status {
        case .ok: return "checkmark.circle.fill"
        case .modified: return "exclamationmark.triangle.fill"
        case .missing: return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .ok: return .themePurple.opacity(0.7) // Subtle purple for OK
        case .modified: return .themePurpleLight // Lighter purple for modified
        case .missing: return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple for missing
        }
    }
    
    private var statusText: String {
        switch status {
        case .ok: return "OK"
        case .modified: return "Modified"
        case .missing: return "Missing"
        }
    }
}

