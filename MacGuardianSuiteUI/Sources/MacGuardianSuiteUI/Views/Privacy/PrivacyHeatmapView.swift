import SwiftUI

struct PrivacyHeatmapView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var privacyData: TCCPrivacyData?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.title)
                        .foregroundColor(.themePurple)
                    VStack(alignment: .leading) {
                        Text("Privacy Permissions")
                            .font(.title.bold())
                        Text("TCC (Transparency, Consent, and Control) monitoring")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Button {
                        runAudit()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.themePurple)
                    .disabled(isLoading)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    ProgressView("Loading privacy data...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let data = privacyData {
                    // Permission Heatmap
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Permission Overview")
                            .font(.headline.bold())
                        
                        PermissionCard(
                            title: "Full Disk Access",
                            count: data.fullDiskAccess,
                            icon: "externaldrive.fill",
                            color: heatmapColor(count: data.fullDiskAccess, isHighRisk: true)
                        )
                        
                        PermissionCard(
                            title: "Screen Recording",
                            count: data.screenRecording,
                            icon: "rectangle.on.rectangle",
                            color: heatmapColor(count: data.screenRecording, isHighRisk: true)
                        )
                        
                        PermissionCard(
                            title: "Microphone",
                            count: data.microphone,
                            icon: "mic.fill",
                            color: heatmapColor(count: data.microphone, isHighRisk: true)
                        )
                        
                        PermissionCard(
                            title: "Camera",
                            count: data.camera,
                            icon: "camera.fill",
                            color: heatmapColor(count: data.camera, isHighRisk: true)
                        )
                        
                        PermissionCard(
                            title: "Input Monitoring",
                            count: data.inputMonitoring,
                            icon: "keyboard",
                            color: heatmapColor(count: data.inputMonitoring, isHighRisk: true)
                        )
                        
                        PermissionCard(
                            title: "Accessibility",
                            count: data.accessibility,
                            icon: "figure.walk",
                            color: heatmapColor(count: data.accessibility, isHighRisk: false)
                        )
                    }
                    .padding()
                    .background(Color.themeDarkGray)
                    .cornerRadius(12)
                    
                    // Alerts
                    if data.issuesFound > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Privacy Alerts")
                                .font(.headline.bold())
                            
                            if data.newPermissions > 0 {
                                AlertBubble(
                                    message: "\(data.newPermissions) new permission(s) granted",
                                    severity: .warning
                                )
                            }
                        }
                        .padding()
                        .background(Color.themeDarkGray)
                        .cornerRadius(12)
                    }
                } else {
                    EmptyStateView(
                        icon: "hand.raised",
                        title: "No privacy data",
                        message: "Run an audit to check privacy permissions"
                    )
                }
            }
        }
        .background(Color.themeBlack)
        .onAppear {
            loadPrivacyData()
        }
    }
    
    private func runAudit() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let scriptPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/privacy/tcc_auditor.sh"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath, "audit"]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let auditDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".macguardian/audits")
                
                if let files = try? FileManager.default.contentsOfDirectory(at: auditDir, includingPropertiesForKeys: [.creationDateKey]),
                   let latestFile = files.filter({ $0.lastPathComponent.contains("tcc_audit") })
                       .sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
                       .first,
                   let data = try? Data(contentsOf: latestFile),
                   let privacy = try? JSONDecoder().decode(TCCPrivacyData.self, from: data) {
                    DispatchQueue.main.async {
                        self.privacyData = privacy
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
    
    private func loadPrivacyData() {
        let auditDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".macguardian/audits")
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: auditDir, includingPropertiesForKeys: [.creationDateKey]),
              let latestFile = files.filter({ $0.lastPathComponent.contains("tcc_audit") })
                  .sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
                  .first,
              let data = try? Data(contentsOf: latestFile),
              let privacy = try? JSONDecoder().decode(TCCPrivacyData.self, from: data) else {
            return
        }
        
        privacyData = privacy
    }
    
    // Heatmap color function - purple-based gradient that fits Omega aesthetic
    private func heatmapColor(count: Int, isHighRisk: Bool) -> Color {
        if count == 0 {
            return .themePurple.opacity(0.3) // Very subtle purple for safe
        } else if count == 1 {
            return .themePurple // Base purple
        } else if count <= 3 {
            return .themePurpleLight // Lighter purple for moderate
        } else {
            // High count - use red but muted to fit dark theme
            return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple
        }
    }
}

struct TCCPrivacyData: Codable {
    let timestamp: String
    let auditType: String
    let issuesFound: Int
    let fullDiskAccess: Int
    let screenRecording: Int
    let microphone: Int
    let camera: Int
    let inputMonitoring: Int
    let accessibility: Int
    let newPermissions: Int
    
    enum CodingKeys: String, CodingKey {
        case timestamp, auditType = "audit_type", issuesFound = "issues_found"
        case fullDiskAccess = "full_disk_access", screenRecording = "screen_recording"
        case microphone, camera, inputMonitoring = "input_monitoring"
        case accessibility, newPermissions = "new_permissions"
    }
}

struct PermissionCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text("\(count) app(s)")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
            
            if count > 0 {
                // Heatmap intensity indicator (purple dots)
                HStack(spacing: 4) {
                    ForEach(0..<min(count, 5), id: \.self) { _ in
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    }
                    if count > 5 {
                        Text("+")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.themePurple.opacity(0.5))
            }
        }
        .padding()
        .background(
            // Subtle glow effect for high counts
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.themeBlack.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(count > 0 ? 0.3 : 0.1), lineWidth: 1)
                )
        )
    }
}

struct AlertBubble: View {
    let message: String
    let severity: AlertSeverity
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(severityColor.opacity(0.2))
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

enum AlertSeverity {
    case critical, warning, info
}

