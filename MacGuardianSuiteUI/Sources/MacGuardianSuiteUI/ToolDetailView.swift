import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ToolDetailView: View {
    @EnvironmentObject private var workspace: WorkspaceState
    let tool: SuiteTool
    let runAction: (SuiteTool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            Divider()
            executionSection
            Spacer()
        }
        .padding(32)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name)
                        .font(.largeTitle.weight(.semibold))
                    Text(tool.description)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Script Path")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: workspace.resolve(path: tool.relativePath))
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .frame(maxWidth: 320, alignment: .trailing)
                }
            }

            HStack(spacing: 12) {
                Button {
                    runAction(tool)
                } label: {
                    Label("Run Module", systemImage: "play.fill")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    revealInFinder()
                } label: {
                    Label("Reveal Script", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    workspace.execution = nil
                } label: {
                    Label("Clear Output", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(workspace.execution == nil)
            }
        }
    }

    private var executionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let execution = workspace.execution, execution.tool.id == tool.id {
                statusHeader(for: execution)
                ScrollView {
                    Text(execution.log.isEmpty ? "Output will appear here…" : execution.log)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                        .padding(16)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        )
                }
                .frame(minHeight: 360)
            } else {
                ContentUnavailableView("No execution yet", systemImage: "waveform", description: Text("Run the module to capture live logs from the underlying shell script."))
            }
        }
    }

    private func statusHeader(for execution: CommandExecution) -> some View {
        let statusText: String
        let statusColor: Color
        switch execution.state {
        case .idle:
            statusText = "Idle"
            statusColor = .secondary
        case .running:
            statusText = "Running…"
            statusColor = .blue
        case .finished:
            statusText = "Completed Successfully"
            statusColor = .green
        case .failed(let message):
            statusText = "Failed – \(message)"
            statusColor = .red
        }

        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label(statusText, systemImage: iconName(for: execution.state))
                .foregroundColor(statusColor)
                .font(.headline)
            Spacer()
            if let duration = executionDuration(for: execution) {
                Label(duration, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func executionDuration(for execution: CommandExecution) -> String? {
        let end = execution.finishedAt ?? Date()
        let interval = end.timeIntervalSince(execution.startedAt)
        guard interval > 0 else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval)
    }

    private func iconName(for state: CommandExecution.State) -> String {
        switch state {
        case .idle:
            return "pause.fill"
        case .running:
            return "circle.dashed"
        case .finished:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.octagon.fill"
        }
    }

    private func revealInFinder() {
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([
            URL(fileURLWithPath: workspace.resolve(path: tool.relativePath))
        ])
        #endif
    }
}
