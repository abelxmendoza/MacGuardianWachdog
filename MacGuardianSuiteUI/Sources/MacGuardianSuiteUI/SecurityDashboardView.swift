import SwiftUI

struct SecurityDashboardView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var integrityResults: [String: (isValid: Bool, message: String)] = [:]
    @State private var isChecking = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    LogoView(size: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Dashboard")
                            .font(.title.bold())
                            .foregroundColor(.themeText)
                        Text("Monitor app security and integrity")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Security Status Card
                SecurityStatusCard()
                
                // Integrity Verification
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.themePurple)
                        Text("File Integrity Verification")
                            .font(.headline)
                            .foregroundColor(.themeText)
                        Spacer()
                        Button {
                            checkIntegrity()
                        } label: {
                            if isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isChecking)
                    }
                    
                    if integrityResults.isEmpty {
                        Text("Click refresh to verify file integrity")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    } else {
                        ForEach(Array(integrityResults.keys.sorted()), id: \.self) { file in
                            if let result = integrityResults[file] {
                                HStack {
                                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(result.isValid ? .green : .yellow)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(file)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.themeText)
                                        Text(result.message)
                                            .font(.caption)
                                            .foregroundColor(.themeTextSecondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.themeDarkGray)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Rootkit Scan Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.themePurple)
                        Text("Rootkit Detection")
                            .font(.headline)
                            .foregroundColor(.themeText)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rootkit Hunter (rkhunter) scans your system for hidden rootkits and malware. This scan requires Terminal access and administrator privileges.")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("⚠️ The scan will open in Terminal.app where you'll need to enter your password.")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .font(.caption2)
                                Text("Command will be copied to clipboard automatically")
                                    .font(.caption2)
                            }
                            .foregroundColor(.themeTextSecondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            Button {
                                #if os(macOS)
                                // Open Terminal and copy command to clipboard
                                TerminalLauncher.shared.openRkhunterScan(updateFirst: true)
                                #endif
                            } label: {
                                HStack {
                                    Image(systemName: "terminal.fill")
                                    Text("Open Terminal & Copy Command")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.themePurple)
                            
                            Button {
                                #if os(macOS)
                                // Open Terminal and copy scan-only command
                                TerminalLauncher.shared.openRkhunterScan(updateFirst: false)
                                #endif
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Scan Only (No Update)")
                                        .font(.subheadline)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.themePurple)
                        }
                        
                        Button {
                            #if os(macOS)
                            // Get the simple command (without echo statements) for clipboard
                            let command = TerminalLauncher.shared.getRkhunterScanCommandForClipboard(updateFirst: true)
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(command, forType: .string)
                            
                            // Also open Terminal to show the command
                            TerminalLauncher.shared.openRkhunterScan(updateFirst: true)
                            #endif
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard.fill")
                                Text("Copy & Open Terminal")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.themePurple)
                    }
                    .padding()
                    .background(Color.themeDarkGray)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Security Features Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Security Features")
                        .font(.headline)
                        .foregroundColor(.themeText)
                    
                    SecurityFeatureRow(
                        icon: "key.fill",
                        title: "Keychain Storage",
                        description: "Passwords stored securely in macOS Keychain"
                    )
                    
                    SecurityFeatureRow(
                        icon: "checkmark.seal.fill",
                        title: "Integrity Verification",
                        description: "SHA-256 checksums verify files haven't been tampered"
                    )
                    
                    SecurityFeatureRow(
                        icon: "lock.shield.fill",
                        title: "Input Validation",
                        description: "All inputs sanitized to prevent injection attacks"
                    )
                    
                    SecurityFeatureRow(
                        icon: "doc.text.fill",
                        title: "Audit Logging",
                        description: "All security events logged for review"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.themeBlack)
        .onAppear {
            checkIntegrity()
        }
    }
    
    private func checkIntegrity() {
        isChecking = true
        DispatchQueue.global(qos: .userInitiated).async {
            let results = IntegrityVerifier.shared.verifyCriticalFiles(repositoryPath: workspace.repositoryPath)
            DispatchQueue.main.async {
                integrityResults = results
                isChecking = false
            }
        }
    }
}

struct SecurityStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Security Status: Active")
                    .font(.headline)
                    .foregroundColor(.themeText)
                Spacer()
            }
            
            Text("All security features are enabled and protecting the app.")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
            
            HStack(spacing: 16) {
                StatusBadge(icon: "key.fill", text: "Keychain", isActive: true)
                StatusBadge(icon: "checkmark.seal.fill", text: "Integrity", isActive: true)
                StatusBadge(icon: "lock.shield.fill", text: "Validation", isActive: true)
            }
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(isActive ? .green : .gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
        .cornerRadius(6)
    }
}

struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.themePurple)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.themeText)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(8)
    }
}

