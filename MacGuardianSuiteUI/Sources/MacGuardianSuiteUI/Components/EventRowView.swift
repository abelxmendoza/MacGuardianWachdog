import SwiftUI

/// Reusable component for displaying individual events
struct EventRowView: View {
    let event: MacGuardianEvent
    let showSource: Bool
    let showTimestamp: Bool
    
    init(event: MacGuardianEvent, showSource: Bool = true, showTimestamp: Bool = true) {
        self.event = event
        self.showSource = showSource
        self.showTimestamp = showTimestamp
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity indicator
            Circle()
                .fill(event.severityColor)
                .frame(width: 12, height: 12)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.event_type.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline.bold())
                        .foregroundColor(.themeText)
                    Spacer()
                    if showTimestamp, let date = event.date {
                        Text(formatTime(date))
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                
                Text(event.message)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                
                if showSource {
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text(event.source)
                            .font(.caption)
                    }
                    .foregroundColor(.themePurple.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.themePurple.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.themeDarkGray)
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

