# MacGuardian Watchdog - Phase 3 & 4 Implementation

## Overview
This document outlines the implementation of Phase 3 (Real-Time Monitoring) and Phase 4 (Privacy, SSH, Timeline) modules for the MacGuardian Watchdog Suite.

## Directory Structure

```
MacGuardianSuite/
├── core/                    # Core utilities and configuration
│   ├── utils.sh
│   ├── config.sh
│   └── algorithms.sh
├── daemons/                 # Real-time monitoring daemons
│   ├── mg_monitor.sh        # Main monitoring daemon
│   ├── fsevents_watcher.sh  # File system watcher
│   ├── process_watcher.sh   # Process anomaly watcher
│   ├── network_watcher.sh   # Network connections watcher
│   ├── timeline_sync.sh     # Timeline synchronizer
│   └── event_writer.sh      # JSON event writer
├── auditors/                # Security auditors
│   ├── ssh_auditor.sh       # SSH security auditor
│   ├── user_account_auditor.sh  # User account auditor
│   ├── cron_auditor.sh      # Cron job auditor
│   ├── network_deep_audit.sh    # Network deep audit
│   └── log_aggregator.sh    # Log aggregator
├── detectors/               # Detection engines
│   ├── ids_engine.sh        # Intrusion Detection System
│   ├── signature_engine.sh  # Malware signature detection
│   └── ransomware_detector.sh  # Ransomware detection
├── privacy/                 # Privacy monitoring
│   └── tcc_auditor.sh       # TCC privacy auditor
├── graphs/                  # Graph builders
│   ├── network_flow_builder.py   # Network flow graph
│   └── process_tree_builder.py   # Process tree graph
├── collectors/              # Data collectors
│   ├── unified_logging.py   # Unified log collector
│   ├── fsevents_collector.py    # FSEvents collector
│   └── dns_collector.py     # DNS collector
├── remediation/             # Remediation playbooks
│   └── remediation_playbooks.sh  # Automated response
├── outputs/                 # Output formatters
│   ├── webhook_notifier.sh  # Webhook notifications
│   ├── timeline_formatter.py    # Timeline formatter
│   └── event_bus.py         # Event bus (future)
└── config/                  # Configuration files
    ├── config.yaml          # Main configuration
    ├── rules.yaml           # IDS correlation rules
    └── signatures/          # Signature database
```

## Phase 3: Real-Time Monitoring

### 1. Enhanced Monitoring Daemon (`mg_monitor.sh`)
- **Purpose**: Main event loop daemon for 24/7 monitoring
- **Features**:
  - Continuous monitoring with configurable intervals
  - Integrates all watchers (FSEvents, Process, Network)
  - IDS correlation engine integration
  - Graceful shutdown handling
  - PID file management
  - Comprehensive logging

### 2. FSEvents Watcher (`fsevents_watcher.sh`)
- **Purpose**: Real-time file system change detection
- **Features**:
  - Monitors critical directories (/Users, /Applications, LaunchDaemons, LaunchAgents)
  - Detects file edits, deletes, new files, permission changes
  - Suspicious pattern detection (executable files)
  - JSON event output

### 3. Process Watcher (`process_watcher.sh`)
- **Purpose**: Real-time process anomaly detection
- **Features**:
  - High CPU spike detection (>80%)
  - Suspicious process pattern matching
  - Baseline comparison
  - Process tree analysis

### 4. Network Watcher (`network_watcher.sh`)
- **Purpose**: Real-time network connection monitoring
- **Features**:
  - Active connection tracking (lsof)
  - DNS request logging
  - ARP table monitoring
  - Routing table changes
  - Threat intelligence integration

### 5. IDS Engine (`ids_engine.sh`)
- **Purpose**: Intrusion Detection System with correlation logic
- **Features**:
  - Event correlation across multiple sources
  - Rule-based detection
  - Incident creation
  - Configurable correlation windows

## Phase 4: Privacy, SSH, Timeline

### 1. SSH Security Auditor (`ssh_auditor.sh`)
- **Purpose**: Comprehensive SSH configuration auditing
- **Features**:
  - Authorized keys fingerprinting
  - SSH config file integrity checking
  - Known hosts monitoring
  - SSHD config changes
  - Failed login attempt detection
  - Baseline creation and comparison

### 2. User Account Auditor (`user_account_auditor.sh`)
- **Purpose**: User account and privilege auditing
- **Features**:
  - User enumeration (dscl)
  - Admin account detection
  - UID 0 (root) account detection
  - Sudoers file integrity
  - Group membership changes
  - Last login anomaly detection

### 3. TCC Privacy Auditor (`tcc_auditor.sh`)
- **Purpose**: macOS Privacy (TCC) permission auditing
- **Features**:
  - TCC database querying
  - Permission change detection
  - Full Disk Access monitoring
  - Screen Recording monitoring
  - Microphone/Camera access tracking
  - Baseline creation

### 4. Cron Auditor (`cron_auditor.sh`)
- **Purpose**: Cron job monitoring
- **Features**:
  - User crontab monitoring
  - System crontab monitoring
  - Suspicious pattern detection
  - Baseline comparison

### 5. Network Deep Audit (`network_deep_audit.sh`)
- **Purpose**: Advanced network security monitoring
- **Features**:
  - DNS server change detection
  - Routing table monitoring
  - ARP table monitoring
  - Listening port enumeration
  - Threat intelligence integration

### 6. Log Aggregator (`log_aggregator.sh`)
- **Purpose**: Unified log collection
- **Features**:
  - Multiple log source aggregation
  - Time-based filtering
  - JSON output format
  - Python-based unified logging support

### 7. Signature Engine (`signature_engine.sh`)
- **Purpose**: Custom malware signature detection
- **Features**:
  - File hash matching
  - File pattern matching
  - String pattern detection
  - Configurable signatures

### 8. Ransomware Detector (`ransomware_detector.sh`)
- **Purpose**: Ransomware activity detection
- **Features**:
  - Mass file change detection
  - Encryption pattern detection
  - Time-window analysis
  - Critical incident creation

### 9. Network Flow Graph Builder (`network_flow_builder.py`)
- **Purpose**: Network visualization data generation
- **Features**:
  - Process → Port → IP mapping
  - Graph node/edge generation
  - JSON output for SwiftUI
  - Connection tracking

### 10. Process Tree Builder (`process_tree_builder.py`)
- **Purpose**: Process tree visualization
- **Features**:
  - Parent-child process relationships
  - Process hierarchy mapping
  - JSON output format

### 11. Timeline Formatter (`timeline_formatter.py`)
- **Purpose**: Unified timeline generation
- **Features**:
  - Event aggregation from all sources
  - Chronological sorting
  - Event type grouping
  - Severity statistics
  - JSON output

### 12. Webhook Notifier (`webhook_notifier.sh`)
- **Purpose**: Alert delivery via webhooks
- **Features**:
  - Slack integration
  - Discord integration
  - Teams integration
  - Generic JSON webhooks
  - Severity-based formatting

### 13. Remediation Playbooks (`remediation_playbooks.sh`)
- **Purpose**: Automated incident response
- **Features**:
  - Ransomware response playbook
  - Suspicious process termination
  - Network threat blocking
  - Incident-based routing

## Configuration

### Main Config (`config/config.yaml`)
- Monitoring intervals
- Privacy alert settings
- SSH monitoring configuration
- IDS correlation rules
- Logging configuration
- Alert delivery settings

### IDS Rules (`config/rules.yaml`)
- Correlation rule definitions
- Severity levels
- Time windows
- Action definitions

## Usage Examples

### Start Monitoring Daemon
```bash
./MacGuardianSuite/daemons/mg_monitor.sh
```

### Run SSH Audit
```bash
./MacGuardianSuite/auditors/ssh_auditor.sh baseline  # Create baseline
./MacGuardianSuite/auditors/ssh_auditor.sh audit    # Run audit
```

### Run User Account Audit
```bash
./MacGuardianSuite/auditors/user_account_auditor.sh baseline
./MacGuardianSuite/auditors/user_account_auditor.sh audit
```

### Run TCC Privacy Audit
```bash
./MacGuardianSuite/privacy/tcc_auditor.sh baseline
./MacGuardianSuite/privacy/tcc_auditor.sh audit
```

### Build Network Flow Graph
```bash
python3 ./MacGuardianSuite/graphs/network_flow_builder.py /tmp/network_graph.json
```

### Format Timeline
```bash
python3 ./MacGuardianSuite/outputs/timeline_formatter.py ~/.macguardian/events ~/.macguardian/timeline.json
```

### Execute Remediation Playbook
```bash
./MacGuardianSuite/remediation/remediation_playbooks.sh ~/.macguardian/incidents/incident_xyz.json
```

## Integration Points

### SwiftUI Integration
- Real-Time Monitor dashboard reads from `~/.macguardian/events/`
- Timeline view uses `~/.macguardian/timeline.json`
- Network graph visualization uses network flow builder output
- Process tree visualization uses process tree builder output

### LaunchDaemon Integration
- `mg_monitor.sh` can be installed as LaunchAgent
- Use `install_monitor_daemon.sh` for installation
- Plist template: `launchd/com.macguardian.monitor.plist`

## Next Steps

1. **SwiftUI Views**: Create UI components for:
   - SSH audit results
   - User account audit results
   - TCC privacy dashboard
   - Network flow graph visualization
   - Process tree visualization
   - Timeline view

2. **Event Bus**: Implement `outputs/event_bus.py` for event routing

3. **FSEvents Collector**: Implement `collectors/fsevents_collector.py` for native FSEvents

4. **Unified Logging**: Complete `collectors/unified_logging.py` implementation

5. **Testing**: Add test suites for each module

6. **Documentation**: Expand inline documentation and examples

## Notes

- All scripts use bash/zsh for macOS compatibility
- Python scripts require Python 3.6+
- Some features require sudo privileges (noted in scripts)
- Baseline files are stored in `~/.macguardian/baselines/`
- Events are stored in `~/.macguardian/events/`
- Incidents are stored in `~/.macguardian/incidents/`
- Logs are stored in `~/.macguardian/logs/`

