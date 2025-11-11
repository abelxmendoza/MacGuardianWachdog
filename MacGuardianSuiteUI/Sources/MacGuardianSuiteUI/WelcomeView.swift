import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var showPathPicker = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon/Logo
            LogoView(size: 150)
                .shadow(color: .themePurple.opacity(0.3), radius: 20)
            
            VStack(spacing: 12) {
                Text("Welcome to MacGuardian Suite")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.themeText)
                
                Text("Your comprehensive security toolkit for macOS")
                    .font(.title2)
                    .foregroundColor(.themeTextSecondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "1.circle.fill",
                    title: "Set Repository Path",
                    description: "Select your MacGuardian project folder to get started"
                )
                
                FeatureRow(
                    icon: "2.circle.fill",
                    title: "Choose a Module",
                    description: "Browse security tools from the sidebar"
                )
                
                FeatureRow(
                    icon: "3.circle.fill",
                    title: "Run & Monitor",
                    description: "Execute scripts and watch live output in real-time"
                )
            }
            .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                // Repository Path Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repository Path")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        TextField("Path to MacGuardian project", text: $workspace.repositoryPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            showPathPicker = true
                        } label: {
                            Label("Browse", systemImage: "folder")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    let validation = workspace.validateRepositoryPath()
                    if !validation.isValid {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(validation.message)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(validation.message)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.themeDarkGray, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.themePurpleDark, lineWidth: 2)
                )
                .frame(maxWidth: 600)
                
                Button {
                    workspace.hasSeenWelcome = true
                } label: {
                    Label("Get Started", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: 300)
                }
                .buttonStyle(.borderedProminent)
                .tint(.themePurple)
                .controlSize(.large)
                .disabled(!workspace.validateRepositoryPath().isValid)
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBlack)
        .fileImporter(
            isPresented: $showPathPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                workspace.repositoryPath = url.path
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.themePurple)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.themeText)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
        }
    }
}

