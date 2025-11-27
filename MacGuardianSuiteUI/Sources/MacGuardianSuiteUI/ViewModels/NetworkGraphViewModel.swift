import Foundation
import SwiftUI
import Combine

/// Optimized view model for Network Graph Dashboard
/// Maintains graph state and only updates when needed
@MainActor
class NetworkGraphViewModel: ObservableObject {
    @Published var nodes: [GraphNode] = []
    @Published var edges: [GraphEdge] = []
    @Published var statistics: GraphStatistics?
    @Published var networkEvents: [MacGuardianEvent] = []
    
    private let liveService = LiveUpdateService.shared
    private let graphBuilder = NetworkGraphBuilder()
    private var cancellables = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?
    
    init() {
        setupObservers()
        startPeriodicUpdate()
    }
    
    private func setupObservers() {
        // Observe graph builder updates
        graphBuilder.$didUpdate
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateGraph()
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdate() {
        // Observe networkEvents updates directly
        liveService.$networkEvents
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.processNetworkEvents()
            }
            .store(in: &cancellables)
        
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.processNetworkEvents()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    private func processNetworkEvents() {
        // Use synchronous @Published property
        let networkEvents = liveService.networkEvents
        self.networkEvents = networkEvents
        
        for event in networkEvents {
            if let process = event.context["process"]?.value as? String ??
               event.context["process_name"]?.value as? String,
               let pid = event.context["pid"]?.value as? Int,
               let ip = event.context["ip"]?.value as? String ?? 
                       event.context["remote_ip"]?.value as? String,
               let port = event.context["port"]?.value as? Int ?? 
                         event.context["remote_port"]?.value as? Int {
                
                graphBuilder.addConnection(
                    processID: pid,
                    processName: process,
                    ip: ip,
                    port: port,
                    isOutbound: true
                )
            }
        }
        
        updateGraph()
    }
    
    private func updateGraph() {
        // Only rebuild if needed (reuse existing graph structure)
        nodes = graphBuilder.buildGraphNodes()
        edges = graphBuilder.buildGraphEdges()
        statistics = graphBuilder.statistics
    }
    
    deinit {
        updateTask?.cancel()
    }
}

