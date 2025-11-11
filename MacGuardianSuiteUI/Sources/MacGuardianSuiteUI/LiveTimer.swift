import SwiftUI

struct LiveTimer: View {
    let execution: CommandExecution
    let currentTime: Date
    @State private var displayTime: String = "00:00"
    
    var body: some View {
        Label(displayTime, systemImage: "clock.fill")
            .font(.subheadline.monospacedDigit())
            .foregroundColor(.themePurple)
            .onChange(of: currentTime) { _, _ in
                updateTimer()
            }
            .onAppear {
                updateTimer()
            }
    }
    
    private func updateTimer() {
        let end = execution.finishedAt ?? currentTime
        let interval = end.timeIntervalSince(execution.startedAt)
        
        if interval > 0 {
            displayTime = formatDuration(interval)
        } else {
            displayTime = "00:00"
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

