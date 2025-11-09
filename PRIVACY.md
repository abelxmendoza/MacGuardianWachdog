# Privacy Policy

**Last Updated**: November 2024

## Overview

MacGuardian Suite is designed with privacy as a core principle. This document explains what data is collected, how it's used, and your rights regarding your data.

## Data Collection

### What We Collect

**Security Scan Data:**
- File integrity checksums (SHA-256)
- Process lists (names, PIDs, resource usage)
- Network connection metadata (IPs, ports, protocols - NOT content)
- System configuration settings
- Threat intelligence indicators (IOCs)

**Performance Metrics:**
- Script execution times
- Resource usage (CPU, memory)
- Operation success/failure rates

**Error Logs:**
- Script errors and warnings
- System errors encountered during scans
- Remediation actions taken

**What We DON'T Collect:**
- ❌ Personal files or content
- ❌ Passwords or credentials
- ❌ Browsing history
- ❌ Application data
- ❌ Email content (only metadata for security analysis)
- ❌ Network packet content (only metadata)
- ❌ User keystrokes or screen content

### How Data is Stored

All data is stored **locally** on your Mac:
- Location: `~/Library/Application Support/MacGuardian/`
- Format: JSON files, text logs, SQLite databases
- Encryption: Not encrypted by default (you can encrypt the directory if desired)

### Data Transmission

**What is transmitted:**
- Email reports (if configured) - sent via SMTP to your specified email
- Threat intelligence feed downloads - from public sources (Abuse.ch, URLhaus, etc.)

**What is NOT transmitted:**
- ❌ Scan results to external servers
- ❌ Personal data to third parties
- ❌ Telemetry or analytics
- ❌ Usage statistics

## Data Retention

**Default Retention Periods:**
- Scan results: 90 days
- Logs: 30 days
- Performance data: 30 days
- Quarantined files: Until manually restored or deleted
- Threat intelligence cache: 7 days

**You can:**
- Adjust retention periods in `config.sh`
- Manually delete data from `~/Library/Application Support/MacGuardian/`
- Use `--no-logging` flag (where supported) to disable logging

## Privacy Modes

MacGuardian Suite offers four privacy levels:

### 1. Minimal
- Only essential security checks
- No network monitoring
- No process monitoring
- Minimal logging

### 2. Light
- Basic security checks
- Limited network monitoring (metadata only)
- No detailed process analysis

### 3. Standard (Default)
- Full security checks
- Network connection monitoring (metadata only)
- Process monitoring
- Standard logging

### 4. Full
- All security features enabled
- Comprehensive monitoring
- Detailed logging

**To change privacy mode:**
```bash
./MacGuardianSuite/privacy_mode.sh set minimal
```

## Network Monitoring

**What we monitor:**
- Active network connections (IP addresses, ports, protocols)
- Established connections (ESTABLISHED state)
- Listening ports
- DNS queries (if enabled)

**What we DON'T monitor:**
- ❌ Packet content or payload
- ❌ Encrypted traffic content
- ❌ Application data
- ❌ Browsing history

**Note**: We do NOT perform "wiretapping" or deep packet inspection. We only collect connection metadata for security analysis.

## File Integrity Monitoring (FIM)

**What we monitor:**
- File changes (additions, modifications, deletions)
- Checksum verification
- Honeypot file access

**What we DON'T monitor:**
- ❌ File content (only checksums)
- ❌ File access patterns
- ❌ User activity within files

## Email Reports

If you configure email reporting:
- Reports are sent to **your specified email address only**
- SMTP credentials are stored locally in `~/.zshrc` (you control this)
- No email content is stored or transmitted to third parties
- You can disable email reporting at any time

## Third-Party Services

**Threat Intelligence Feeds:**
- Abuse.ch (Feodo Tracker, URLhaus)
- Malware Domain List
- These are public, open-source feeds

**No third-party analytics or tracking services are used.**

## Your Rights

You have the right to:
1. **Access**: View all collected data in `~/Library/Application Support/MacGuardian/`
2. **Delete**: Remove any or all collected data
3. **Opt-Out**: Disable data collection via privacy mode
4. **Export**: Export your data (JSON format)
5. **Modify**: Adjust retention periods and collection settings

## Data Security

- All data is stored locally on your Mac
- No cloud storage or external servers
- You control access via macOS permissions
- Quarantined files are stored in `~/MacGuardian/quarantine/`

## Children's Privacy

MacGuardian Suite is not intended for users under 13. We do not knowingly collect data from children.

## Changes to This Policy

We may update this privacy policy. Changes will be:
- Documented in this file
- Noted in release notes
- Effective immediately upon update

## Contact

For privacy concerns or questions:
- Open a GitHub issue
- Email: [Your Contact Email]

## Compliance

This privacy policy is designed to comply with:
- GDPR (General Data Protection Regulation)
- CCPA (California Consumer Privacy Act)
- macOS privacy best practices

---

**Remember**: MacGuardian Suite runs entirely on your local machine. You have full control over your data.

