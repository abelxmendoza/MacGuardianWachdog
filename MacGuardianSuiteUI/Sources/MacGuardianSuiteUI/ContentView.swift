import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var categories: [SuiteCategory] = SuiteCategory.defaultCategories()
    @State private var commandRunner = ShellCommandRunner()
    @FocusState private var repositoryPathFieldFocused: Bool

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 1100, minHeight: 720)
    }

    private var sidebar: some View {
        List(selection: $workspace.selectedTool) {
            Section("Repository") {
                HStack(spacing: 12) {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.accentColor)
                    TextField("Repository Path", text: $workspace.repositoryPath)
                        .textFieldStyle(.roundedBorder)
                        .focused($repositoryPathFieldFocused)
                    Button {
                        openPanel()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.borderless)
                    .help("Choose the MacGuardian repository folder")
                }
            }

            ForEach(categories) { category in
                Section {
                    ForEach(category.tools) { tool in
                        Label(tool.name, systemImage: icon(for: tool))
                            .tag(tool as SuiteTool?)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.headline)
                        Text(category.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MacGuardian Suite")
        .onChange(of: workspace.selectedTool) { _, newValue in
            guard let tool = newValue else { return }
            if !categories.contains(where: { $0.tools.contains(tool) }) {
                workspace.selectedTool = categories.first?.tools.first
            }
        }
        .onAppear {
            if workspace.selectedTool == nil {
                workspace.selectedTool = categories.first?.tools.first
            }
        }
    }

    private var detailView: some View {
        Group {
            if let tool = workspace.selectedTool {
                ToolDetailView(tool: tool) { selectedTool in
                    let execution = commandRunner.run(tool: selectedTool, workspace: workspace)
                    workspace.execution = execution
                }
                .environmentObject(workspace)
            } else {
                ContentUnavailableView("Select a module", systemImage: "square.grid.2x2", description: Text("Choose a module from the sidebar to view details and run it."))
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func icon(for tool: SuiteTool) -> String {
        switch tool.kind {
        case .shell:
            return "terminal"
        case .python:
            return "chevron.left.forwardslash.chevron.right"
        }
    }

    private func openPanel() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK {
            workspace.repositoryPath = panel.url?.path ?? workspace.repositoryPath
        }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WorkspaceState(defaultPath: "/Users/example/Desktop/MacGuardianProject"))
    }
}
