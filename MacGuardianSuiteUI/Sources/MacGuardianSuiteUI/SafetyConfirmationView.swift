import SwiftUI

struct SafetyConfirmationView: View {
    @ObservedObject var workspace: WorkspaceState
    let tool: SuiteTool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: tool.safetyLevel.icon)
                    .font(.title)
                    .foregroundColor(tool.safetyLevel == .destructive ? .red : .orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Confirmation Required")
                        .font(.headline)
                        .foregroundColor(.themeText)
                    Text(tool.safetyLevel.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.themeDarkGray)
            
            Divider()
                .background(Color.themePurpleDark)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Safety level description
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.themePurple)
                        Text(tool.safetyLevel.description)
                            .font(.body)
                            .foregroundColor(.themeText)
                    }
                    .padding(.vertical, 8)
                    
                    // Destructive operations list
                    if !tool.destructiveOperations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This script may:")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeText)
                            
                            ForEach(tool.destructiveOperations, id: \.self) { operation in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.themePurple)
                                    Text(operation)
                                        .font(.subheadline)
                                        .foregroundColor(.themeTextSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.themeDarkGray.opacity(0.5))
                        .cornerRadius(8)
                    }
                    
                    // Safe mode info
                    if workspace.safeMode {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.themePurple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Safe Mode is ON")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.themeText)
                                Text("You're being asked to confirm because Safe Mode requires confirmation for \(tool.safetyLevel == .destructive ? "destructive" : "caution") operations.")
                                    .font(.caption)
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                        .padding()
                        .background(Color.themePurpleDark.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    // Warning
                    if tool.safetyLevel == .destructive {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚠️ Important Warning")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.red)
                                Text("This operation can permanently delete files or make irreversible changes to your system. Make sure you understand what this script does before proceeding.")
                                    .font(.caption)
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            Divider()
                .background(Color.themePurpleDark)
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    workspace.showSafetyConfirmation = false
                    workspace.pendingExecution = nil
                }
                .buttonStyle(.bordered)
                .foregroundColor(.themeText)
                
                Spacer()
                
                Button("Run Anyway") {
                    workspace.showSafetyConfirmation = false
                    if let execute = workspace.pendingExecution {
                        execute()
                        workspace.pendingExecution = nil
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(tool.safetyLevel == .destructive ? .red : .orange)
            }
            .padding()
            .background(Color.themeDarkGray)
        }
        .frame(width: 500, height: 500)
        .background(Color.themeBlack)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

