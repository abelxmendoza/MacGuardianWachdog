import Foundation
import Combine

/// Represents a runnable script or module in the MacGuardian suite.
struct SuiteTool: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Codable {
        case shell
        case python
    }

    let id = UUID()
    let name: String
    let description: String
    let relativePath: String
    let kind: Kind
    let arguments: [String]
    let requiresSudo: Bool

    init(
        name: String,
        description: String,
        relativePath: String,
        kind: Kind = .shell,
        arguments: [String] = [],
        requiresSudo: Bool = false
    ) {
        self.name = name
        self.description = description
        self.relativePath = relativePath
        self.kind = kind
        self.arguments = arguments
        self.requiresSudo = requiresSudo
    }

    func commandLine(using workspace: WorkspaceState) -> [String] {
        var resolvedPath = workspace.resolve(path: relativePath)
        if requiresSudo {
            resolvedPath = "sudo " + resolvedPath
        }
        let command = [workspace.interpreter(for: self), resolvedPath] + arguments
        if requiresSudo {
            return ["/bin/zsh", "-lc", (["sudo", resolvedPath] + arguments).joined(separator: " ")]
        }
        return command
    }
}

/// Logical grouping for tools, used for the navigation sidebar.
struct SuiteCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let tools: [SuiteTool]
}

/// Global app state that stores the workspace path and currently selected items.
final class WorkspaceState: ObservableObject {
    @Published var repositoryPath: String
    @Published var selectedCategory: SuiteCategory?
    @Published var selectedTool: SuiteTool?
    @Published var execution: CommandExecution?

    init(defaultPath: String = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("MacGuardianWachdog").path) {
        self.repositoryPath = defaultPath
    }

    func resolve(path: String) -> String {
        if path.hasPrefix("/") {
            return path
        }
        let expanded = (repositoryPath as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded).appendingPathComponent(path).path
    }

    func interpreter(for tool: SuiteTool) -> String {
        switch tool.kind {
        case .shell:
            return "/bin/zsh"
        case .python:
            return "/usr/bin/python3"
        }
    }
}

/// Represents an execution request and its mutable progress state.
final class CommandExecution: ObservableObject, Identifiable {
    enum State {
        case idle
        case running
        case finished(Int32)
        case failed(String)
    }

    let id = UUID()
    let tool: SuiteTool
    @Published var log: String
    @Published var state: State
    @Published var startedAt: Date
    @Published var finishedAt: Date?

    init(tool: SuiteTool) {
        self.tool = tool
        self.log = ""
        self.state = .idle
        self.startedAt = Date()
        self.finishedAt = nil
    }
}

/// Bridges Process output into published updates for SwiftUI.
final class ShellCommandRunner {
    func run(tool: SuiteTool, workspace: WorkspaceState) -> CommandExecution {
        let execution = CommandExecution(tool: tool)
        execution.state = .running
        execution.startedAt = Date()

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            switch tool.kind {
            case .shell:
                process.launchPath = "/bin/zsh"
                let command = self.shellCommand(for: tool, workspace: workspace)
                process.arguments = ["-lc", command]
            case .python:
                process.launchPath = "/usr/bin/python3"
                process.arguments = [workspace.resolve(path: tool.relativePath)] + tool.arguments
            }

            let handle = pipe.fileHandleForReading
            let buffer = NSMutableData()

            NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: handle, queue: nil) { _ in
                let data = handle.availableData
                if data.count > 0 {
                    buffer.append(data)
                    if let chunk = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            execution.log.append(contentsOf: chunk)
                        }
                    }
                    handle.waitForDataInBackgroundAndNotify()
                }
            }

            handle.waitForDataInBackgroundAndNotify()

            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    execution.state = .failed(error.localizedDescription)
                    execution.finishedAt = Date()
                    execution.log.append("\nFailed to start: \(error.localizedDescription)\n")
                }
                return
            }

            process.waitUntilExit()
            let status = process.terminationStatus
            DispatchQueue.main.async {
                execution.finishedAt = Date()
                if status == 0 {
                    execution.state = .finished(status)
                } else {
                    execution.state = .failed("Exit code \(status)")
                }
            }
        }

        return execution
    }

    private func shellCommand(for tool: SuiteTool, workspace: WorkspaceState) -> String {
        let resolved = workspace.resolve(path: tool.relativePath)
        let components = [resolved] + tool.arguments
        let quoted = components.map { component -> String in
            if component.isEmpty { return "''" }
            let escaped = component.replacingOccurrences(of: "'", with: "'\\''")
            return "'\(escaped)'"
        }
        let commandBody = quoted.joined(separator: " ")
        if tool.requiresSudo {
            return "sudo \(commandBody)"
        }
        return commandBody
    }
}

extension SuiteCategory {
    static func defaultCategories() -> [SuiteCategory] {
        return [
            SuiteCategory(
                name: "Mac Suite",
                description: "Main entry point combining all modules.",
                tools: [
                    SuiteTool(
                        name: "Run mac_suite.sh",
                        description: "Launch the interactive command-line interface for the entire suite.",
                        relativePath: "mac_suite.sh",
                        arguments: []
                    ),
                    SuiteTool(
                        name: "Run mac_guardian.sh",
                        description: "Execute the cleanup and security hardening workflow.",
                        relativePath: "MacGuardianSuite/mac_guardian.sh"
                    ),
                    SuiteTool(
                        name: "Run mac_watchdog.sh",
                        description: "Start file integrity monitoring and Tripwire-style checks.",
                        relativePath: "MacGuardianSuite/mac_watchdog.sh"
                    ),
                    SuiteTool(
                        name: "Run mac_blueteam.sh",
                        description: "Advanced detection of suspicious processes, network connections, and anomalies.",
                        relativePath: "MacGuardianSuite/mac_blueteam.sh"
                    ),
                    SuiteTool(
                        name: "Run mac_ai.sh",
                        description: "Machine learning-driven security analytics and behavioral insights.",
                        relativePath: "MacGuardianSuite/mac_ai.sh"
                    ),
                    SuiteTool(
                        name: "Run mac_security_audit.sh",
                        description: "Comprehensive security posture assessment for macOS.",
                        relativePath: "MacGuardianSuite/mac_security_audit.sh"
                    ),
                    SuiteTool(
                        name: "Run mac_remediation.sh",
                        description: "Automated remediation workflows with dry-run safety checks.",
                        relativePath: "MacGuardianSuite/mac_remediation.sh"
                    )
                ]
            ),
            SuiteCategory(
                name: "Threat Intelligence",
                description: "Collectors, schedulers, and alerting utilities.",
                tools: [
                    SuiteTool(
                        name: "Threat Intel Feeds",
                        description: "Fetch and correlate the latest threat intelligence feeds.",
                        relativePath: "MacGuardianSuite/threat_intel_feeds.sh"
                    ),
                    SuiteTool(
                        name: "Scheduled Reports",
                        description: "Generate scheduled HTML and text reports.",
                        relativePath: "MacGuardianSuite/scheduled_reports.sh"
                    ),
                    SuiteTool(
                        name: "Advanced Alerting",
                        description: "Manage custom alert rules and severity-based notifications.",
                        relativePath: "MacGuardianSuite/advanced_alerting.sh"
                    ),
                    SuiteTool(
                        name: "STIX Exporter",
                        description: "Export collected indicators of compromise to STIX format.",
                        relativePath: "MacGuardianSuite/stix_exporter.py",
                        kind: .python
                    )
                ]
            ),
            SuiteCategory(
                name: "Utilities",
                description: "Helpful maintenance and troubleshooting utilities.",
                tools: [
                    SuiteTool(
                        name: "Performance Monitor",
                        description: "Track execution times and identify suite bottlenecks.",
                        relativePath: "MacGuardianSuite/performance_monitor.sh"
                    ),
                    SuiteTool(
                        name: "Error Tracker",
                        description: "Review and triage recorded errors from recent runs.",
                        relativePath: "MacGuardianSuite/error_tracker.sh"
                    ),
                    SuiteTool(
                        name: "View Errors",
                        description: "Quickly open the generated error logs.",
                        relativePath: "MacGuardianSuite/view_errors.sh"
                    ),
                    SuiteTool(
                        name: "Module Manager",
                        description: "Enable, disable, and configure suite modules.",
                        relativePath: "MacGuardianSuite/module_manager.py",
                        kind: .python
                    )
                ]
            )
        ]
    }
}
