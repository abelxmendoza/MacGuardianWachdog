import Foundation
import Combine
import Network

/// Standardized event structure matching JSON schema
struct MacGuardianEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: String
    let type: String
    let severity: String
    let source: String
    let message: String
    let context: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case timestamp, type, severity, source, message, context
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
        self.type = try container.decode(String.self, forKey: .type)
        self.severity = try container.decode(String.self, forKey: .severity)
        self.source = try container.decode(String.self, forKey: .source)
        self.message = try container.decode(String.self, forKey: .message)
        self.context = try container.decode([String: AnyCodable].self, forKey: .context)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(severity, forKey: .severity)
        try container.encode(source, forKey: .source)
        try container.encode(message, forKey: .message)
        try container.encode(context, forKey: .context)
    }
    
    var severityColor: Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "warning": return .yellow
        case "medium": return .yellow
        default: return .blue
        }
    }
    
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp)
    }
}

/// Helper for decoding Any JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

/// WebSocket client for real-time event updates
class WebSocketClient: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private var reconnectTimer: Timer?
    private let maxReconnectAttempts = 10
    private var reconnectAttempts = 0
    
    @Published var isConnected = false
    @Published var connectionError: String?
    
    init(url: URL) {
        self.url = url
    }
    
    func connect() {
        guard webSocketTask == nil || webSocketTask?.state != .running else {
            return
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
        isConnected = true
        connectionError = nil
        reconnectAttempts = 0
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage() // Continue receiving
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        // Message handling will be done by LiveUpdateService
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionError = error.localizedDescription
            self.attemptReconnect()
        }
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 30.0) // Exponential backoff, max 30s
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    func send(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
}

/// Live update service for real-time event streaming
@MainActor
class LiveUpdateService: ObservableObject {
    static let shared = LiveUpdateService()
    
    @Published var events: [MacGuardianEvent] = []
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var lastUpdate: Date?
    
    private let webSocketClient: WebSocketClient
    private let maxCachedEvents = 100
    private let eventBusURL = URL(string: "ws://localhost:9765")!
    
    private init() {
        self.webSocketClient = WebSocketClient(url: eventBusURL)
        setupWebSocketObservers()
    }
    
    func start() {
        webSocketClient.connect()
    }
    
    func stop() {
        webSocketClient.disconnect()
    }
    
    private func setupWebSocketObservers() {
        // Observe connection status
        webSocketClient.$isConnected
            .assign(to: &$isConnected)
        
        webSocketClient.$connectionError
            .assign(to: &$connectionError)
    }
    
    func handleWebSocketMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(MacGuardianEvent.self, from: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            if self.events.count > self.maxCachedEvents {
                self.events.removeLast()
            }
            self.lastUpdate = Date()
        }
    }
    
    // Filtered event accessors
    var criticalEvents: [MacGuardianEvent] {
        events.filter { $0.severity.lowercased() == "critical" }
    }
    
    var highSeverityEvents: [MacGuardianEvent] {
        events.filter { $0.severity.lowercased() == "high" }
    }
    
    var processEvents: [MacGuardianEvent] {
        events.filter { $0.type == "process" }
    }
    
    var networkEvents: [MacGuardianEvent] {
        events.filter { $0.type == "network" }
    }
    
    var filesystemEvents: [MacGuardianEvent] {
        events.filter { $0.type == "fs" || $0.type == "filesystem" }
    }
    
    var idsEvents: [MacGuardianEvent] {
        events.filter { $0.type == "ids" || $0.type == "correlation" }
    }
    
    var recentEvents: [MacGuardianEvent] {
        Array(events.prefix(50))
    }
    
    func events(forType type: String) -> [MacGuardianEvent] {
        events.filter { $0.type == type }
    }
    
    func events(forSeverity severity: String) -> [MacGuardianEvent] {
        events.filter { $0.severity.lowercased() == severity.lowercased() }
    }
}

