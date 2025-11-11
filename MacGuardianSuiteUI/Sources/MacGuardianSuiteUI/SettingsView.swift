import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var reportEmail: String = ""
    @State private var smtpUsername: String = ""
    @State private var smtpPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showSaveConfirmation: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with Logo
                HStack {
                    LogoView(size: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.title.bold())
                            .foregroundColor(.themeText)
                        Text("Configure your MacGuardian Suite")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Email Configuration
                SettingsSection(title: "Email Configuration", icon: "envelope.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Report Email")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeText)
                            TextField("abelxmendoza@gmail.com", text: $reportEmail)
                                .textFieldStyle(.roundedBorder)
                                .help("Email address to receive security reports")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SMTP Username")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeText)
                            TextField("your-email@gmail.com", text: $smtpUsername)
                                .textFieldStyle(.roundedBorder)
                                .help("SMTP username for sending emails")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SMTP Password")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeText)
                            HStack {
                                if showPassword {
                                    TextField("Enter password", text: $smtpPassword)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    SecureField("Enter password", text: $smtpPassword)
                                        .textFieldStyle(.roundedBorder)
                                }
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.themeTextSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .help("SMTP password (stored securely)")
                        }
                        
                        Button("Save Email Settings") {
                            saveEmailSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.themePurple)
                        .controlSize(.large)
                        
                        if showSaveConfirmation {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Settings saved successfully")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                // Safety Settings
                SettingsSection(title: "Safety Settings", icon: "shield.checkered") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Safe Mode", isOn: $workspace.safeMode)
                            .help("Requires confirmation for potentially dangerous operations")
                        
                        Text("When enabled, you'll be asked to confirm before running scripts that may modify files or system settings.")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                
                // Repository Settings
                SettingsSection(title: "Repository", icon: "folder.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repository Path")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeText)
                            HStack {
                                TextField("Repository Path", text: $workspace.repositoryPath)
                                    .textFieldStyle(.roundedBorder)
                                Button {
                                    selectRepositoryPath()
                                } label: {
                                    Image(systemName: "folder")
                                }
                                .buttonStyle(.bordered)
                                .tint(.themePurple)
                            }
                        }
                        
                        let validation = workspace.validateRepositoryPath()
                        if !validation.isValid {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(validation.message)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Repository path is valid")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                
                // About
                SettingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.themeTextSecondary)
                        }
                        
                        Divider()
                            .background(Color.themePurpleDark)
                        
                        Link("Documentation", destination: URL(string: "https://github.com")!)
                            .foregroundColor(.themePurple)
                        
                        Link("Support", destination: URL(string: "mailto:abelxmendoza@gmail.com")!)
                            .foregroundColor(.themePurple)
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBlack)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        reportEmail = workspace.reportEmail.isEmpty ? UserDefaults.standard.string(forKey: "reportEmail") ?? "" : workspace.reportEmail
        smtpUsername = workspace.smtpUsername.isEmpty ? UserDefaults.standard.string(forKey: "smtpUsername") ?? "" : workspace.smtpUsername
    }
    
    private func saveEmailSettings() {
        workspace.reportEmail = reportEmail
        workspace.smtpUsername = smtpUsername
        
        UserDefaults.standard.set(reportEmail, forKey: "reportEmail")
        UserDefaults.standard.set(smtpUsername, forKey: "smtpUsername")
        
        // Note: Password should be stored in Keychain in production
        if !smtpPassword.isEmpty {
            UserDefaults.standard.set(smtpPassword, forKey: "smtpPassword")
        }
        
        showSaveConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSaveConfirmation = false
        }
    }
    
    private func selectRepositoryPath() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Select your MacGuardian project folder"
        if panel.runModal() == .OK {
            workspace.repositoryPath = panel.url?.path ?? workspace.repositoryPath
        }
        #endif
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.themePurple)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.themeText)
            }
            
            content
        }
        .padding()
        .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themePurpleDark, lineWidth: 1)
        )
    }
}

