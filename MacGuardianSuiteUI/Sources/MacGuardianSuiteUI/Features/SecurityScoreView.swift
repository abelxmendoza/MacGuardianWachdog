import SwiftUI

struct SecurityScoreView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var securityScore: Double = 0.85
    @State private var showExplanation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Score display
                VStack(spacing: 20) {
                    ProgressRingWithLabel(
                        progress: securityScore,
                        label: "Security Score",
                        size: 200
                    )
                    .padding(.top, 40)
                    
                    Text("What this score means")
                        .font(.macGuardianBody)
                        .foregroundColor(.themeTextSecondary)
                        .underline()
                        .onTapGesture {
                            showExplanation = true
                        }
                }
                
                // Score breakdown
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Score Breakdown")
                    
                    ScoreFactorRow(
                        name: "File Integrity",
                        score: 0.95,
                        weight: 0.3
                    )
                    
                    ScoreFactorRow(
                        name: "Network Security",
                        score: 0.80,
                        weight: 0.25
                    )
                    
                    ScoreFactorRow(
                        name: "Process Monitoring",
                        score: 0.90,
                        weight: 0.20
                    )
                    
                    ScoreFactorRow(
                        name: "Privacy Permissions",
                        score: 0.75,
                        weight: 0.15
                    )
                    
                    ScoreFactorRow(
                        name: "System Configuration",
                        score: 0.85,
                        weight: 0.10
                    )
                }
                .padding(LayoutGuides.paddingLarge)
                
                // Recommendations
                if securityScore < 0.8 {
                    CardContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommendations")
                                .font(.macGuardianTitle3)
                            
                            Text("• Review and fix file integrity issues")
                            Text("• Check network connections")
                            Text("• Update privacy permissions")
                        }
                    }
                    .padding(.horizontal, LayoutGuides.paddingLarge)
                }
            }
        }
        .background(Color.themeBlack)
        .sheet(isPresented: $showExplanation) {
            SecurityScoreExplanationView()
        }
        .onAppear {
            calculateScore()
        }
    }
    
    private func calculateScore() {
        // Calculate score based on recent events and audit results
        // Simplified for now
        let criticalCount = liveService.criticalEvents.count
        let highCount = liveService.highSeverityEvents.count
        
        var score = 1.0
        score -= Double(criticalCount) * 0.1
        score -= Double(highCount) * 0.05
        score = max(0.0, min(1.0, score))
        
        withAnimation {
            securityScore = score
        }
    }
}

struct ScoreFactorRow: View {
    let name: String
    let score: Double
    let weight: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.macGuardianBodyBold)
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(.macGuardianBodyBold)
                    .foregroundColor(scoreColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.themeDarkGray)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * score, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
    
    private var scoreColor: Color {
        if score >= 0.8 {
            return .themePurple // Base purple for good scores
        } else if score >= 0.6 {
            return .themePurpleLight // Lighter purple for moderate
        } else {
            return Color(red: 0.9, green: 0.1, blue: 0.3) // Muted red-purple for low scores
        }
    }
}

struct SecurityScoreExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Understanding Your Security Score")
                        .font(.macGuardianTitle2)
                        .foregroundColor(.themeText)
                    
                    Text("Your security score is calculated based on multiple factors:")
                        .font(.macGuardianBody)
                        .foregroundColor(.themeText)
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ScoreExplanationRow(
                            range: "90-100",
                            label: "Excellent",
                            description: "Your system is well-protected with minimal security issues."
                        )
                        
                        ScoreExplanationRow(
                            range: "70-89",
                            label: "Good",
                            description: "Minor issues detected. Review recommendations."
                        )
                        
                        ScoreExplanationRow(
                            range: "50-69",
                            label: "Fair",
                            description: "Several security concerns. Action recommended."
                        )
                        
                        ScoreExplanationRow(
                            range: "0-49",
                            label: "Poor",
                            description: "Critical security issues detected. Immediate action required."
                        )
                    }
                }
                .padding(LayoutGuides.paddingLarge)
            }
            .background(Color.themeBlack)
            .navigationTitle("Security Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScoreExplanationRow: View {
    let range: String
    let label: String
    let description: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(range)
                        .font(.macGuardianBodyBold)
                        .foregroundColor(.themePurple)
                    Text(label)
                        .font(.macGuardianBodyBold)
                }
                Text(description)
                    .font(.macGuardianBody)
                    .foregroundColor(.themeTextSecondary)
            }
        }
    }
}

