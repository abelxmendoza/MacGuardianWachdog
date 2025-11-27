import Foundation
import Combine
import SwiftUI

/// Network graph builder using adjacency list representation
/// O(1) edge insertion, O(V + E) graph building
final class NetworkGraphBuilder: ObservableObject {
    // Adjacency lists: ProcessID -> Set of connections
    private var processConnections: [Int: Set<ConnectionNode>] = [:]
    
    // Reverse index: IPAddress -> Set of ProcessIDs
    private var ipToProcesses: [String: Set<Int>] = [:]
    
    // Process metadata: ProcessID -> NetworkProcessInfo
    private var processInfo: [Int: NetworkProcessInfo] = [:]
    
    private let queue = DispatchQueue(label: "com.macguardian.networkgraph", attributes: .concurrent)
    
    @Published var didUpdate = false
    
    /// Add a network connection (O(1))
    func addConnection(processID: Int, processName: String, ip: String, port: Int, isOutbound: Bool = true) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Store process info
            if self.processInfo[processID] == nil {
                self.processInfo[processID] = NetworkProcessInfo(id: processID, name: processName)
            }
            
            // Add connection node
            if self.processConnections[processID] == nil {
                self.processConnections[processID] = []
            }
            
            let connection = ConnectionNode(ip: ip, port: port, isOutbound: isOutbound)
            self.processConnections[processID]?.insert(connection)
            
            // Update reverse index
            if self.ipToProcesses[ip] == nil {
                self.ipToProcesses[ip] = []
            }
            self.ipToProcesses[ip]?.insert(processID)
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Remove a connection (O(1))
    func removeConnection(processID: Int, ip: String, port: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if let connection = self.processConnections[processID]?.first(where: { $0.ip == ip && $0.port == port }) {
                self.processConnections[processID]?.remove(connection)
                
                // Update reverse index
                self.ipToProcesses[ip]?.remove(processID)
                if self.ipToProcesses[ip]?.isEmpty == true {
                    self.ipToProcesses.removeValue(forKey: ip)
                }
            }
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
    
    /// Get all connections for a process (O(1))
    func connections(for processID: Int) -> Set<ConnectionNode> {
        return queue.sync {
            return processConnections[processID] ?? []
        }
    }
    
    /// Get all processes connecting to an IP (O(1))
    func processes(for ip: String) -> Set<Int> {
        return queue.sync {
            return ipToProcesses[ip] ?? []
        }
    }
    
    /// Get process info (O(1))
    func processInfo(for processID: Int) -> NetworkProcessInfo? {
        return queue.sync {
            return processInfo[processID]
        }
    }
    
    /// Build graph nodes for visualization (O(V + E))
    func buildGraphNodes() -> [GraphNode] {
        return queue.sync(execute: {
            var nodes: [GraphNode] = []
            var nodeId = 0
            
            // Add process nodes
            for (pid, info) in processInfo {
                nodes.append(GraphNode(
                    id: nodeId,
                    label: info.name,
                    type: "process",
                    pid: pid,
                    ip: nil,
                    name: info.name
                ))
                nodeId += 1
            }
            
            // Add IP nodes (unique IPs)
            let uniqueIPs = Set(ipToProcesses.keys)
            for ip in uniqueIPs {
                nodes.append(GraphNode(
                    id: nodeId,
                    label: ip,
                    type: "ip",
                    pid: nil,
                    ip: ip,
                    name: nil
                ))
                nodeId += 1
            }
            
            return nodes
        })
    }
    
    /// Build graph edges for visualization (O(E))
    func buildGraphEdges() -> [GraphEdge] {
        return queue.sync(execute: {
            var edges: [GraphEdge] = []
            var edgeId = 0
            
            // Build node ID mapping
            var processNodeMap: [Int: Int] = [:]
            var ipNodeMap: [String: Int] = [:]
            var nodeId = 0
            
            for (pid, _) in processInfo.sorted(by: { $0.key < $1.key }) {
                processNodeMap[pid] = nodeId
                nodeId += 1
            }
            
            for ip in ipToProcesses.keys.sorted() {
                ipNodeMap[ip] = nodeId
                nodeId += 1
            }
            
            // Build edges
            for (pid, connections) in processConnections {
                guard let processNodeId = processNodeMap[pid] else { continue }
                
                for connection in connections {
                    guard let ipNodeId = ipNodeMap[connection.ip] else { continue }
                    
                    edges.append(GraphEdge(
                        from: processNodeId,
                        to: ipNodeId,
                        label: "\(processInfo[pid]?.name ?? "Unknown") → \(connection.ip):\(connection.port)",
                        port: connection.port,
                        localPort: nil,
                        remotePort: connection.port
                    ))
                    edgeId += 1
                }
            }
            
            return edges
        })
    }
    
    /// Get statistics
    var statistics: GraphStatistics {
        return queue.sync {
            let processCount = processInfo.count
            let ipCount = ipToProcesses.count
            let connectionCount = processConnections.values.reduce(0) { $0 + $1.count }
            
            return GraphStatistics(
                processCount: processCount,
                ipCount: ipCount,
                connectionCount: connectionCount
            )
        }
    }
    
    /// Clear all data
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.processConnections.removeAll()
            self.ipToProcesses.removeAll()
            self.processInfo.removeAll()
            
            DispatchQueue.main.async {
                self.didUpdate.toggle()
            }
        }
    }
}

// MARK: - Supporting Types

struct ConnectionNode: Hashable {
    let ip: String
    let port: Int
    let isOutbound: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ip)
        hasher.combine(port)
    }
    
    static func == (lhs: ConnectionNode, rhs: ConnectionNode) -> Bool {
        return lhs.ip == rhs.ip && lhs.port == rhs.port
    }
}

struct NetworkProcessInfo {
    let id: Int
    let name: String
}

struct GraphStatistics {
    let processCount: Int
    let ipCount: Int
    let connectionCount: Int
}

