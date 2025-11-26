import SwiftUI

struct WelcomeView: View {
    @Binding var hasSeenWelcome: Bool
    @State private var showSetup = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo and title
            VStack(spacing: 20) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.themePurple)
                    .scaleOnAppear()
                
                TitleText(text: "MacGuardian Suite")
                
                SubtitleText(text: "Advanced macOS Security Monitoring")
            }
            .fadeIn()
            
            // Features preview
            VStack(spacing: 16) {
                FeaturePreviewRow(icon: "lock.shield.fill", text: "File Integrity Monitoring")
                FeaturePreviewRow(icon: "network", text: "Real-Time Network Analysis")
                FeaturePreviewRow(icon: "eye.fill", text: "Threat Detection & Hunting")
                FeaturePreviewRow(icon: "hand.raised.fill", text: "Privacy Auditing")
            }
            .padding(.horizontal, LayoutGuides.paddingXLarge)
            .fadeIn()
            .animation(.easeInOut.delay(0.2), value: showSetup)
            
            Spacer()
            
            // Begin button
            Button {
                withAnimation {
                    showSetup = true
                    hasSeenWelcome = true
                }
            } label: {
                Text("Begin Setup")
                    .font(.macGuardianSubtitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.themePurple, .themePurpleLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .hoverPulse()
            .scaleOnAppear()
            .padding(.bottom, LayoutGuides.paddingXLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBlack)
    }
}

struct FeaturePreviewRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.themePurple)
                .frame(width: 24)
            Text(text)
                .font(.macGuardianBody)
                .foregroundColor(.themeTextSecondary)
            Spacer()
        }
    }
}

