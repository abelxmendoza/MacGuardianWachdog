# MacGuardian Watchdog - Phase 5 Implementation

## Overview
Phase 5 focuses on SwiftUI integration, Event Bus implementation, and creating a production-ready frontend for MacGuardian Watchdog.

## ✅ Completed Components

### 1. Event Bus (`outputs/event_bus.py`)
- **Purpose**: Central hub for all real-time events
- **Features**:
  - Unix Domain Socket (UDS) server at `/tmp/macguardian.sock` for shell script integration
  - WebSocket server on `ws://localhost:9765` for SwiftUI real-time updates
  - Event normalization from various sources
  - Event storage to `~/.macguardian/events/`
  - Broadcast to all connected WebSocket clients
  - Automatic reconnection handling
  - Event caching (last 1000 events)

### 2. Live Update Service (`Services/LiveUpdateService.swift`)
- **Purpose**: SwiftUI service for real-time event streaming
- **Features**:
  - WebSocket client with auto-reconnect
  - Combine publishers for reactive updates
  - Event filtering by type and severity
  - Caching of last 100 events
  - Standardized event model (`MacGuardianEvent`)

### 3. SwiftUI Views Created

#### SSH Security Dashboard (`Views/SSH/SSHSecurityView.swift`)
- Displays SSH audit results
- Key fingerprint monitoring
- Config file integrity checks
- Baseline management
- File status indicators

#### User Account Security (`Views/UserAccounts/UserAccountSecurityView.swift`)
- User enumeration
- Admin account tracking
- UID 0 (root) detection
- Account change alerts
- Statistics dashboard

#### Privacy Heatmap (`Views/Privacy/PrivacyHeatmapView.swift`)
- TCC permission monitoring
- Full Disk Access tracking
- Screen Recording alerts
- Microphone/Camera access
- Permission heatmap visualization

#### Network Flow Graph (`Views/Network/NetworkGraphView.swift`)
- Process → Port → IP visualization
- Connection statistics
- Node detail views
- Interactive graph exploration

#### Incident Timeline (`Views/Timeline/IncidentTimelineView.swift`)
- Chronological event feed
- Date-grouped events
- Severity filtering
- Event type filtering
- Statistics overview

#### Config Editor (`Views/Settings/ConfigEditorView.swift`)
- YAML configuration editing
- Monitoring toggles
- Privacy settings
- SSH monitoring config
- IDS settings
- Alert configuration

### 4. JSON Schema Documentation (`outputs/json_schema.md`)
- Standardized event format specification
- Module-specific context schemas
- Validation rules
- Examples and best practices

## 📋 Integration Steps

### Starting the Event Bus

```bash
# Install websockets if needed
pip3 install websockets

# Start event bus
python3 MacGuardianSuite/outputs/event_bus.py
```

The event bus will:
- Listen on UDS socket: `/tmp/macguardian.sock`
- Listen on WebSocket: `ws://localhost:9765`
- Store events in: `~/.macguardian/events/`

### Connecting Shell Scripts to Event Bus

Shell scripts can send events via UDS:

```bash
# Example: Send event from watcher
echo '{
  "timestamp": "2024-01-15T10:30:45Z",
  "type": "process",
  "severity": "high",
  "source": "process_watcher",
  "message": "High CPU process detected",
  "context": {"pid": 12345, "cpu_percent": 85.5}
}' | nc -U /tmp/macguardian.sock
```

Or use Python helper:

```python
import socket
import json

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect('/tmp/macguardian.sock')
sock.send(json.dumps({
    'timestamp': '2024-01-15T10:30:45Z',
    'type': 'process',
    'severity': 'high',
    'source': 'process_watcher',
    'message': 'High CPU process detected',
    'context': {'pid': 12345, 'cpu_percent': 85.5}
}).encode())
sock.close()
```

### SwiftUI Integration

In your SwiftUI app:

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var liveService = LiveUpdateService.shared
    
    var body: some View {
        VStack {
            // Connect on appear
            .onAppear {
                liveService.start()
            }
            
            // Display events
            List(liveService.events) { event in
                EventRow(event: event)
            }
        }
    }
}
```

## 🔄 Next Steps

### 1. Update Shell Scripts to Use Event Bus

Modify watchers to send events via UDS:

```bash
# In process_watcher.sh
send_event() {
    local event_json=$(cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "process",
  "severity": "$1",
  "source": "process_watcher",
  "message": "$2",
  "context": $3
}
EOF
)
    echo "$event_json" | nc -U /tmp/macguardian.sock 2>/dev/null || true
}
```

### 2. Add View Navigation

Update `AppState.swift` to include new views:

```swift
enum AppView: String, CaseIterable {
    // ... existing views
    case sshSecurity = "SSH Security"
    case userAccounts = "User Accounts"
    case privacy = "Privacy"
    case networkGraph = "Network Graph"
    case timeline = "Timeline"
    case config = "Configuration"
}
```

### 3. Implement YAML Parsing

For production, add YAML parsing library:

```swift
// Add to Package.swift
.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")

// Use in ConfigEditorView
import Yams
```

### 4. Add Graph Visualization Library

For network graph visualization, consider:
- SwiftUI Charts (native)
- Custom graph rendering
- Third-party library integration

### 5. Testing

Create test suites:
- Event Bus unit tests
- WebSocket connection tests
- View rendering tests
- JSON schema validation tests

## 📁 File Structure

```
MacGuardianSuiteUI/
├── Sources/
│   └── MacGuardianSuiteUI/
│       ├── Services/
│       │   └── LiveUpdateService.swift ✅
│       └── Views/
│           ├── SSH/
│           │   └── SSHSecurityView.swift ✅
│           ├── UserAccounts/
│           │   └── UserAccountSecurityView.swift ✅
│           ├── Privacy/
│           │   └── PrivacyHeatmapView.swift ✅
│           ├── Network/
│           │   └── NetworkGraphView.swift ✅
│           ├── Timeline/
│           │   └── IncidentTimelineView.swift ✅
│           └── Settings/
│               └── ConfigEditorView.swift ✅

MacGuardianSuite/
└── outputs/
    ├── event_bus.py ✅
    └── json_schema.md ✅
```

## 🎨 UI Features

### Dark Theme
- Cyberpunk purple/red color scheme
- Dark backgrounds with accent colors
- High contrast for readability

### Real-Time Updates
- Live event streaming via WebSocket
- Automatic reconnection
- Event filtering and search

### Interactive Dashboards
- Clickable nodes in network graph
- Expandable event details
- Filterable timelines
- Configurable settings

## 🔧 Configuration

All views read from:
- Audit results: `~/.macguardian/audits/`
- Timeline data: `~/.macguardian/timeline.json`
- Network graph: `/tmp/network_graph.json`
- Configuration: `MacGuardianSuite/config/config.yaml`

## 🚀 Production Readiness

### Completed ✅
- Event Bus implementation
- WebSocket server/client
- SwiftUI service layer
- All dashboard views
- JSON schema documentation

### Remaining Tasks
- [ ] Update shell scripts to use Event Bus
- [ ] Add YAML parsing library
- [ ] Implement graph visualization
- [ ] Add comprehensive tests
- [ ] Create user documentation
- [ ] Add error handling and recovery
- [ ] Performance optimization
- [ ] UI polish and animations

## 📝 Notes

- Event Bus requires Python 3.6+ and `websockets` library
- WebSocket runs on port 9765 (configurable)
- UDS socket requires write permissions
- All views use dark theme consistent with MacGuardian branding
- Views are designed to be modular and reusable

