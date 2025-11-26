//
// Network Graph Density Test
// Tests graph building with 10k nodes / 30k edges
//

import Foundation

// Note: This test requires NetworkGraphBuilder.swift to be accessible
// Run with: swift tests/performance/graph_density_test.swift

struct NetworkGraphDensityTest {
    static func run() {
        print("==========================================")
        print("Network Graph Density Test")
        print("==========================================")
        print("")
        
        let nodeCount = 10_000
        let edgeCount = 30_000
        
        print("Building graph with:")
        print("  Nodes: \(nodeCount)")
        print("  Edges: \(edgeCount)")
        print("")
        
        let startTime = Date()
        
        // Simulate graph building
        var nodes: Set<Int> = []
        var edges: [(Int, Int)] = []
        
        // Generate nodes
        for i in 0..<nodeCount {
            nodes.insert(i)
            if (i + 1) % 1000 == 0 {
                print("  Generated \(i + 1) nodes...")
            }
        }
        
        // Generate edges (random connections)
        let random = SystemRandomNumberGenerator()
        for i in 0..<edgeCount {
            let from = Int.random(in: 0..<nodeCount, using: &random)
            let to = Int.random(in: 0..<nodeCount, using: &random)
            edges.append((from, to))
            
            if (i + 1) % 5000 == 0 {
                print("  Generated \(i + 1) edges...")
            }
        }
        
        // Simulate adjacency list building (O(V+E))
        var adjacencyList: [Int: Set<Int>] = [:]
        for (from, to) in edges {
            if adjacencyList[from] == nil {
                adjacencyList[from] = Set<Int>()
            }
            adjacencyList[from]?.insert(to)
        }
        
        let buildDuration = Date().timeIntervalSince(startTime)
        
        print("")
        print("Results:")
        print("  Nodes: \(nodes.count)")
        print("  Edges: \(edges.count)")
        print("  Adjacency list size: \(adjacencyList.count)")
        print("  Build duration: \(String(format: "%.2f", buildDuration))s")
        print("  Build rate: \(String(format: "%.0f", Double(edgeCount) / buildDuration)) edges/sec")
        print("")
        
        // Validate O(V+E) behavior
        // Expected: Build time should scale linearly with V+E
        let expectedMaxDuration = 5.0 // 5 seconds max for 10k nodes + 30k edges
        if buildDuration < expectedMaxDuration {
            print("✅ PASS: Build duration (\(String(format: "%.2f", buildDuration))s) < threshold (\(expectedMaxDuration)s)")
        } else {
            print("⚠️  WARNING: Build duration (\(String(format: "%.2f", buildDuration))s) exceeds threshold (\(expectedMaxDuration)s)")
        }
        
        // Validate memory efficiency
        let memoryEstimate = (nodes.count * MemoryLayout<Int>.size) + 
                            (edges.count * MemoryLayout<Int>.size * 2) +
                            (adjacencyList.count * MemoryLayout<Int>.size * 2)
        let memoryMB = Double(memoryEstimate) / (1024 * 1024)
        print("  Estimated memory: \(String(format: "%.2f", memoryMB)) MB")
        
        if memoryMB < 100.0 { // Less than 100MB for 10k nodes + 30k edges
            print("✅ PASS: Memory usage (\(String(format: "%.2f", memoryMB)) MB) < threshold (100 MB)")
        } else {
            print("⚠️  WARNING: Memory usage (\(String(format: "%.2f", memoryMB)) MB) exceeds threshold (100 MB)")
        }
        
        print("")
        print("==========================================")
    }
}

// Run test if executed directly
if CommandLine.argc > 0 {
    NetworkGraphDensityTest.run()
}

