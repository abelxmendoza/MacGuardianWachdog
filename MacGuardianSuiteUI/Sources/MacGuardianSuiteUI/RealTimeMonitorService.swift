import Foundation
import Combine

/// Real-time monitoring service that reads security events from the daemon
class RealTimeMonitorService: ObservableObject {
    @Published var events: [ThreatEvent] = []
    @Published var isMonitoring: Bool = false
    @Published var lastUpdate: Date?
    
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var timer: Timer?
    private let eventDirectory: URL
    private let maxEvents: Int = 1000  // Limit events to prevent memory issues
    
    init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        eventDirectory = homeDir.appendingPathComponent(".macguardian/events")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: eventDirectory, withIntermediateDirectories: true)
        
        // Load initial events
        loadEvents()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Set up file system watcher
        let fileDescriptor = open(eventDirectory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("⚠️ Failed to open event directory for monitoring")
            isMonitoring = false
            return
        }
        
        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )
        
        fileWatcher?.setEventHandler { [weak self] in
            self?.loadEvents()
        }
        
        fileWatcher?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileWatcher?.resume()
        
        // Also poll periodically as a backup (every 5 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.loadEvents()
        }
        
        print("✅ Real-time monitoring started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        fileWatcher?.cancel()
        fileWatcher = nil
        timer?.invalidate()
        timer = nil
        print("⏹️ Real-time monitoring stopped")
    }
    
    func loadEvents() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: eventDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        // Sort by modification date (newest first)
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 > date2
        }
        
        // Load events from JSON files
        var loadedEvents: [ThreatEvent] = []
        
        for file in sortedFiles.prefix(maxEvents) {
            guard file.pathExtension == "json",
                  let data = try? Data(contentsOf: file),
                  let event = try? JSONDecoder().decode(ThreatEvent.self, from: data) else {
                continue
            }
            
            loadedEvents.append(event)
        }
        
        // Sort by timestamp (newest first)
        events = loadedEvents.sorted { event1, event2 in
            event1.timestamp > event2.timestamp
        }
        
        lastUpdate = Date()
    }
    
    func clearEvents() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: eventDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
        
        events.removeAll()
        lastUpdate = Date()
    }
    
    var criticalEvents: [ThreatEvent] {
        events.filter { $0.severity == "critical" }
    }
    
    var highSeverityEvents: [ThreatEvent] {
        events.filter { $0.severity == "high" }
    }
    
    var recentEvents: [ThreatEvent] {
        Array(events.prefix(50))
    }
    
    deinit {
        stopMonitoring()
    }
}

/// Threat event model matching the JSON structure from the daemon
struct ThreatEvent: Codable, Identifiable {
    let id: String
    let timestamp: String
    let type: String
    let severity: String
    let message: String
    let details: ThreatEventDetails
    
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) ?? ISO8601DateFormatter().date(from: timestamp)
    }
    
    var severityColor: String {
        switch severity.lowercased() {
        case "critical": return "red"
        case "high": return "orange"
        case "medium": return "yellow"
        case "low": return "blue"
        default: return "gray"
        }
    }
}

/// Threat event details (flexible JSON structure)
struct ThreatEventDetails: Codable {
    // Common fields
    let pid: Int?
    let process: String?
    let cpu_percent: Double?
    let directory: String?
    let file_count: Int?
    let files: [String]?
    let port: Int?
    let remote: String?
    let ip: String?
    let threat_source: String?
    
    // Allow additional fields
    private enum CodingKeys: String, CodingKey {
        case pid, process, cpu_percent, directory, file_count, files, port, remote, ip, threat_source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pid = try? container.decode(Int.self, forKey: .pid)
        process = try? container.decode(String.self, forKey: .process)
        cpu_percent = try? container.decode(Double.self, forKey: .cpu_percent)
        directory = try? container.decode(String.self, forKey: .directory)
        file_count = try? container.decode(Int.self, forKey: .file_count)
        files = try? container.decode([String].self, forKey: .files)
        port = try? container.decode(Int.self, forKey: .port)
        remote = try? container.decode(String.self, forKey: .remote)
        ip = try? container.decode(String.self, forKey: .ip)
        threat_source = try? container.decode(String.self, forKey: .threat_source)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(pid, forKey: .pid)
        try? container.encode(process, forKey: .process)
        try? container.encode(cpu_percent, forKey: .cpu_percent)
        try? container.encode(directory, forKey: .directory)
        try? container.encode(file_count, forKey: .file_count)
        try? container.encode(files, forKey: .files)
        try? container.encode(port, forKey: .port)
        try? container.encode(remote, forKey: .remote)
        try? container.encode(ip, forKey: .ip)
        try? container.encode(threat_source, forKey: .threat_source)
    }
}

