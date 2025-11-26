import SwiftUI

struct NetworkGraphView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    @State private var networkGraph: NetworkGraphData?
    @State private var isLoading = false
    @State private var selectedNode: GraphNode?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "network")
                        .font(.title)
                        .foregroundColor(.themePurple)
                    VStack(alignment: .leading) {
                        Text("Network Flow")
                            .font(.title.bold())
                        Text("Process → Port → IP connections")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Button {
                        buildGraph()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.themePurple)
                    .disabled(isLoading)
                }
                .padding()
                
                Divider()
                
                if isLoading {
                    ProgressView("Building network graph...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let graph = networkGraph {
                    // Statistics
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Nodes",
                            value: "\(graph.nodes.count)",
                            icon: "circle.grid.2x2",
                            color: .themePurple
                        )
                        StatCard(
                            title: "Connections",
                            value: "\(graph.edges.count)",
                            icon: "arrow.triangle.branch",
                            color: .themePurpleLight
                        )
                        StatCard(
                            title: "Processes",
                            value: "\(graph.processCount)",
                            icon: "cpu",
                            color: .themePurple
                        )
                    }
                    .padding()
                    
                    // Graph Visualization (simplified - would use actual graph library)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Network Connections")
                            .font(.headline.bold())
                        
                        // Process nodes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Processes")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeTextSecondary)
                            
                            ForEach(graph.nodes.filter { $0.type == "process" }.prefix(10), id: \.id) { node in
                                ProcessNodeRow(node: node) {
                                    selectedNode = node
                                }
                            }
                        }
                        .padding()
                        .background(Color.themeDarkGray)
                        .cornerRadius(12)
                        
                        // IP nodes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("IP Addresses")
                                .font(.subheadline.bold())
                                .foregroundColor(.themeTextSecondary)
                            
                            ForEach(graph.nodes.filter { $0.type == "ip" }.prefix(10), id: \.id) { node in
                                IPNodeRow(node: node) {
                                    selectedNode = node
                                }
                            }
                        }
                        .padding()
                        .background(Color.themeDarkGray)
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    EmptyStateView(
                        icon: "network",
                        title: "No network graph",
                        message: "Build graph to visualize network connections"
                    )
                }
            }
        }
        .background(Color.themeBlack)
        .sheet(item: $selectedNode) { node in
            NodeDetailView(node: node)
        }
        .onAppear {
            loadGraph()
        }
    }
    
    private func buildGraph() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let scriptPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite/graphs/network_flow_builder.py"
            let outputPath = "/tmp/network_graph.json"
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [scriptPath, outputPath]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if let data = try? Data(contentsOf: URL(fileURLWithPath: outputPath)),
                   let graph = try? JSONDecoder().decode(NetworkGraphData.self, from: data) {
                    DispatchQueue.main.async {
                        self.networkGraph = graph
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadGraph() {
        let graphPath = "/tmp/network_graph.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: graphPath)),
              let graph = try? JSONDecoder().decode(NetworkGraphData.self, from: data) else {
            return
        }
        
        networkGraph = graph
    }
}

struct NetworkGraphData: Codable {
    let timestamp: String
    let nodes: [GraphNode]
    let edges: [GraphEdge]
    let connectionCount: Int
    let processCount: Int
    
    enum CodingKeys: String, CodingKey {
        case timestamp, nodes, edges
        case connectionCount = "connection_count"
        case processCount = "process_count"
    }
}

struct GraphNode: Codable, Identifiable {
    let id: Int
    let label: String
    let type: String
    let pid: Int?
    let ip: String?
    let name: String?
}

struct GraphEdge: Codable, Identifiable {
    let id = UUID()
    let from: Int
    let to: Int
    let label: String?
    let port: Int?
    let localPort: Int?
    let remotePort: Int?
    
    enum CodingKeys: String, CodingKey {
        case from, to, label, port
        case localPort = "local_port"
        case remotePort = "remote_port"
    }
}

struct ProcessNodeRow: View {
    let node: GraphNode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.themePurple)
                VStack(alignment: .leading) {
                    Text(node.label)
                        .font(.subheadline.bold())
                    if let pid = node.pid {
                        Text("PID: \(pid)")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.themeTextSecondary)
            }
            .padding()
            .background(Color.themeBlack.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct IPNodeRow: View {
    let node: GraphNode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(.themePurpleLight)
                VStack(alignment: .leading) {
                    Text(node.label)
                        .font(.subheadline.bold())
                    if let ip = node.ip {
                        Text(ip)
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.themeTextSecondary)
            }
            .padding()
            .background(Color.themeBlack.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct NodeDetailView: View {
    let node: GraphNode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: node.type == "process" ? "cpu" : "globe")
                            .font(.title)
                            .foregroundColor(.themePurple)
                        VStack(alignment: .leading) {
                            Text(node.label)
                                .font(.title.bold())
                            Text(node.type.uppercased())
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let pid = node.pid {
                            DetailRow(label: "Process ID", value: "\(pid)")
                        }
                        if let ip = node.ip {
                            DetailRow(label: "IP Address", value: ip)
                        }
                        if let name = node.name {
                            DetailRow(label: "Name", value: name)
                        }
                    }
                    .padding()
                    .background(Color.themeDarkGray)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.themeBlack)
            .navigationTitle("Node Details")
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

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.subheadline.bold())
                .foregroundColor(.themeTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

