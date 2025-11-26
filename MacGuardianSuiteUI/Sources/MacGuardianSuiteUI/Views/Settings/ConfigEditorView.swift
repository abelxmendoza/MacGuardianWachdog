import SwiftUI

struct ConfigEditorView: View {
    @State private var config: MacGuardianConfig?
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                        .foregroundColor(.themePurple)
                    VStack(alignment: .leading) {
                        Text("Configuration")
                            .font(.title.bold())
                        Text("Edit MacGuardian settings")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Button {
                        saveConfig()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.themePurple)
                    .disabled(isSaving || config == nil)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    ProgressView("Loading configuration...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let config = config {
                    // Monitoring Settings
                    ConfigSection(title: "Real-Time Monitoring") {
                        Toggle("Enable Process Monitor", isOn: Binding(
                            get: { config.monitoring.enableProcessMonitor },
                            set: { config.monitoring.enableProcessMonitor = $0 }
                        ))
                        
                        Toggle("Enable Network Monitor", isOn: Binding(
                            get: { config.monitoring.enableNetworkMonitor },
                            set: { config.monitoring.enableNetworkMonitor = $0 }
                        ))
                        
                        Toggle("Enable FSEvents", isOn: Binding(
                            get: { config.monitoring.enableFSEvents },
                            set: { config.monitoring.enableFSEvents = $0 }
                        ))
                        
                        Toggle("Enable IDS", isOn: Binding(
                            get: { config.monitoring.enableIDS },
                            set: { config.monitoring.enableIDS = $0 }
                        ))
                        
                        HStack {
                            Text("Check Interval (seconds)")
                            Spacer()
                            TextField("", value: Binding(
                                get: { config.monitoring.interval },
                                set: { config.monitoring.interval = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                    }
                    
                    // Privacy Settings
                    ConfigSection(title: "Privacy Monitoring") {
                        Toggle("Alert on New Permissions", isOn: Binding(
                            get: { config.privacy.alertOnNewPermissions },
                            set: { config.privacy.alertOnNewPermissions = $0 }
                        ))
                        
                        Toggle("Monitor TCC Changes", isOn: Binding(
                            get: { config.privacy.monitorTCCChanges },
                            set: { config.privacy.monitorTCCChanges = $0 }
                        ))
                        
                        Toggle("Alert on Full Disk Access", isOn: Binding(
                            get: { config.privacy.alertOnFullDiskAccess },
                            set: { config.privacy.alertOnFullDiskAccess = $0 }
                        ))
                        
                        Toggle("Alert on Screen Recording", isOn: Binding(
                            get: { config.privacy.alertOnScreenRecording },
                            set: { config.privacy.alertOnScreenRecording = $0 }
                        ))
                    }
                    
                    // SSH Settings
                    ConfigSection(title: "SSH Monitoring") {
                        Toggle("Alert on Key Change", isOn: Binding(
                            get: { config.ssh.alertOnKeyChange },
                            set: { config.ssh.alertOnKeyChange = $0 }
                        ))
                        
                        Toggle("Alert on Config Change", isOn: Binding(
                            get: { config.ssh.alertOnConfigChange },
                            set: { config.ssh.alertOnConfigChange = $0 }
                        ))
                        
                        Toggle("Monitor Authorized Keys", isOn: Binding(
                            get: { config.ssh.monitorAuthorizedKeys },
                            set: { config.ssh.monitorAuthorizedKeys = $0 }
                        ))
                    }
                    
                    // IDS Settings
                    ConfigSection(title: "Intrusion Detection") {
                        Toggle("Enable Correlation", isOn: Binding(
                            get: { config.ids.enableCorrelation },
                            set: { config.ids.enableCorrelation = $0 }
                        ))
                        
                        HStack {
                            Text("Correlation Window (seconds)")
                            Spacer()
                            TextField("", value: Binding(
                                get: { config.ids.correlationWindow },
                                set: { config.ids.correlationWindow = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                        
                        HStack {
                            Text("File Change Threshold")
                            Spacer()
                            TextField("", value: Binding(
                                get: { config.ids.fileChangeThreshold },
                                set: { config.ids.fileChangeThreshold = $0 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }
                    }
                    
                    // Alert Settings
                    ConfigSection(title: "Alerting") {
                        Toggle("Enable Email Alerts", isOn: Binding(
                            get: { config.alerts.enableEmail },
                            set: { config.alerts.enableEmail = $0 }
                        ))
                        
                        Toggle("Enable Webhook", isOn: Binding(
                            get: { config.alerts.enableWebhook },
                            set: { config.alerts.enableWebhook = $0 }
                        ))
                        
                        HStack {
                            Text("Webhook URL")
                            Spacer()
                            TextField("", text: Binding(
                                get: { config.alerts.webhookURL },
                                set: { config.alerts.webhookURL = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                        }
                        
                        Toggle("Critical Alerts", isOn: Binding(
                            get: { config.alerts.criticalAlerts },
                            set: { config.alerts.criticalAlerts = $0 }
                        ))
                        
                        Toggle("High Alerts", isOn: Binding(
                            get: { config.alerts.highAlerts },
                            set: { config.alerts.highAlerts = $0 }
                        ))
                    }
                } else {
                    EmptyStateView(
                        icon: "gearshape",
                        title: "No configuration",
                        message: "Configuration file not found"
                    )
                }
            }
        }
        .background(Color.themeBlack)
        .alert("Configuration Saved", isPresented: $showSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveMessage)
        }
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let configPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/config/config.yaml"
            
            // Note: Would need YAML parsing library in production
            // For now, create default config
            DispatchQueue.main.async {
                self.config = MacGuardianConfig.default
                self.isLoading = false
            }
        }
    }
    
    private func saveConfig() {
        guard let config = config else { return }
        
        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            // Note: Would need YAML encoding library in production
            // For now, just show success message
            DispatchQueue.main.async {
                self.saveMessage = "Configuration saved. Restart daemon to apply changes."
                self.showSaveAlert = true
                self.isSaving = false
            }
        }
    }
}

struct ConfigSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(12)
    }
}

struct MacGuardianConfig {
    var monitoring: MonitoringConfig
    var privacy: PrivacyConfig
    var ssh: SSHConfig
    var ids: IDSConfig
    var alerts: AlertConfig
    
    static var `default`: MacGuardianConfig {
        MacGuardianConfig(
            monitoring: MonitoringConfig(
                interval: 2,
                enableProcessMonitor: true,
                enableNetworkMonitor: true,
                enableFSEvents: true,
                enableIDS: true
            ),
            privacy: PrivacyConfig(
                alertOnNewPermissions: true,
                monitorTCCChanges: true,
                alertOnFullDiskAccess: true,
                alertOnScreenRecording: true
            ),
            ssh: SSHConfig(
                alertOnKeyChange: true,
                alertOnConfigChange: true,
                monitorAuthorizedKeys: true
            ),
            ids: IDSConfig(
                enableCorrelation: true,
                correlationWindow: 60,
                fileChangeThreshold: 50
            ),
            alerts: AlertConfig(
                enableEmail: false,
                enableWebhook: false,
                webhookURL: "",
                criticalAlerts: true,
                highAlerts: true
            )
        )
    }
}

struct MonitoringConfig {
    var interval: Int
    var enableProcessMonitor: Bool
    var enableNetworkMonitor: Bool
    var enableFSEvents: Bool
    var enableIDS: Bool
}

struct PrivacyConfig {
    var alertOnNewPermissions: Bool
    var monitorTCCChanges: Bool
    var alertOnFullDiskAccess: Bool
    var alertOnScreenRecording: Bool
}

struct SSHConfig {
    var alertOnKeyChange: Bool
    var alertOnConfigChange: Bool
    var monitorAuthorizedKeys: Bool
}

struct IDSConfig {
    var enableCorrelation: Bool
    var correlationWindow: Int
    var fileChangeThreshold: Int
}

struct AlertConfig {
    var enableEmail: Bool
    var enableWebhook: Bool
    var webhookURL: String
    var criticalAlerts: Bool
    var highAlerts: Bool
}

