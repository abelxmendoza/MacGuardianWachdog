# Security Policy

## Supported Versions

We currently support the following macOS versions:
- macOS 12 (Monterey) and later
- macOS 13 (Ventura)
- macOS 14 (Sonoma)
- macOS 15 (Sequoia)

## Reporting a Vulnerability

If you discover a security vulnerability in MacGuardian Suite, please report it responsibly:

1. **Do NOT** open a public GitHub issue
2. Email security details to: [Your Security Email]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide an update on the status within 7 days.

## Security Best Practices

### Auto-Fix Safety

- **Default Behavior**: All remediation runs in **dry-run mode** by default
- **Quarantine System**: Files are moved to quarantine (`~/MacGuardian/quarantine/`) instead of being deleted
- **Rollback Capability**: All changes are tracked in JSON manifests with SHA-256 checksums
- **Confirmation Required**: Dangerous operations (file removal, process termination) require explicit confirmation

### Permissions Required

MacGuardian Suite requires the following macOS permissions:

1. **Full Disk Access** (for file integrity monitoring)
   - Required for: File scanning, baseline creation, change detection
   - How to grant: System Settings > Privacy & Security > Full Disk Access

2. **Network Access** (for threat intelligence and reporting)
   - Required for: Downloading threat feeds, sending email reports
   - How to grant: System Settings > Privacy & Security > Network Access

3. **Accessibility** (optional, for some advanced features)
   - Required for: Process monitoring (if enabled)
   - How to grant: System Settings > Privacy & Security > Accessibility

### Data Collection

**What we collect:**
- Security scan results (stored locally)
- Performance metrics (execution times, resource usage)
- Error logs (for troubleshooting)
- Threat intelligence IOCs (IPs, domains, hashes)

**What we DON'T collect:**
- Personal files or content
- Passwords or credentials
- Browsing history
- Application data

**Data Storage:**
- All data is stored locally in `~/Library/Application Support/MacGuardian/`
- No data is transmitted to external servers (except email reports if configured)
- Threat intelligence feeds are downloaded from public sources (Abuse.ch, etc.)

**Data Retention:**
- Scan results: 90 days (configurable)
- Logs: 30 days (configurable)
- Quarantined files: Until manually restored or deleted
- Performance data: 30 days

### Opt-Out Options

You can disable data collection by:
1. Setting `PRIVACY_MODE=minimal` in `config.sh`
2. Disabling specific features in Privacy Mode settings
3. Running with `--no-logging` flag (where supported)

## Security Features

### File Integrity Monitoring (FIM)
- SHA-256 checksums for baseline files
- Change detection with timestamps
- Honeypot file monitoring
- Extended attributes for metadata

### Threat Detection
- Process monitoring (heuristic-based)
- Network connection analysis
- File system anomaly detection
- Command & control (C2) detection

### Remediation Safety
- Dry-run by default
- Quarantine before deletion
- Rollback manifests
- Checksum verification

## Known Limitations

1. **Root Access**: Some features require `sudo` privileges. The suite will prompt when needed.
2. **False Positives**: Heuristic-based detection may flag benign files. Review quarantined files before permanent deletion.
3. **macOS Updates**: Some checks may need updates after major macOS releases.
4. **Third-Party Tools**: Relies on ClamAV, rkhunter, and other tools that must be kept updated.

## Security Updates

We recommend:
- Running `./MacGuardianSuite/mac_guardian.sh` weekly for updates
- Keeping ClamAV definitions updated (`freshclam`)
- Reviewing quarantined files regularly
- Checking for suite updates on GitHub

## Disclosure Policy

Security vulnerabilities will be disclosed:
- After a fix is available (coordinated disclosure)
- With credit to the reporter (if desired)
- In the CHANGELOG and release notes

## Contact

For security concerns: [Your Security Email]
For general support: Open a GitHub issue

