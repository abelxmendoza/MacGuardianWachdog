# 🚀 Quick Start Guide - Mac Guardian Suite

## Easiest Way: Interactive Menu

Simply run:
```bash
./mac_suite.sh
```

This will show you an interactive menu where you can:
1. Run Mac Guardian (Cleanup & Security)
2. Run Mac Watchdog (File Integrity Monitor)
3. Run Mac Blue Team (Advanced Threat Detection)
4. Run Mac AI (Intelligent Security Analysis)
5. Run Mac Security Audit (Comprehensive Security Assessment)
6. Run all tools in sequence
7. Exit

---

## Direct Script Execution

### Mac Guardian (Cleanup & Security)
```bash
cd MacGuardianSuite
./mac_guardian.sh
```

**Options:**
- `./mac_guardian.sh -y` - Non-interactive mode (auto-answers)
- `./mac_guardian.sh -q` - Quiet mode (minimal output)
- `./mac_guardian.sh -v` - Verbose mode (detailed output)
- `./mac_guardian.sh --skip-scan` - Skip antivirus scans
- `./mac_guardian.sh --report` - Generate HTML report

### Mac Watchdog (File Integrity Monitor)
```bash
cd MacGuardianSuite
./mac_watchdog.sh
```

**First Run:** Creates baseline checksums
**Subsequent Runs:** Compares against baseline and alerts on changes

### Mac Blue Team (Advanced Threat Detection)
```bash
cd MacGuardianSuite
./mac_blueteam.sh
```

**Options:**
- `./mac_blueteam.sh --threat-hunt` - Run advanced threat hunting
- `./mac_blueteam.sh --forensic` - Forensic analysis mode
- `./mac_blueteam.sh --osquery` - Use osquery for system queries
- `./mac_blueteam.sh --nmap` - Run network port scanning
- `./mac_blueteam.sh --yara` - Use yara for pattern matching
- `./mac_blueteam.sh --osquery --nmap --yara` - Use all advanced tools

### Mac AI (Intelligent Security Analysis)
```bash
cd MacGuardianSuite
./mac_ai.sh
```

**Options:**
- `./mac_ai.sh --train` - Train ML models
- `./mac_ai.sh --advanced` - Run advanced ML analysis
- `./mac_ai.sh --classify` - Run file classification

### Mac Security Audit (Comprehensive Security Assessment)
```bash
cd MacGuardianSuite
./mac_security_audit.sh
```

**Options:**
- `./mac_security_audit.sh --lynis` - Run full lynis security audit
- `./mac_security_audit.sh -v` - Verbose output
- `./mac_security_audit.sh -q` - Quiet mode

---

## Recommended Usage

### Daily
```bash
./MacGuardianSuite/mac_watchdog.sh -q
```

### Weekly
```bash
./MacGuardianSuite/mac_guardian.sh -y
./MacGuardianSuite/mac_security_audit.sh
```

### Monthly (Full Security Check)
```bash
./MacGuardianSuite/mac_blueteam.sh --osquery --nmap --yara
./MacGuardianSuite/mac_ai.sh --advanced
```

### Complete Security Suite (All Tools)
```bash
./mac_suite.sh
# Then select option 6: "Run all"
```

---

## First Time Setup

1. **Make scripts executable** (if needed):
   ```bash
   chmod +x mac_suite.sh MacGuardianSuite/*.sh
   ```

2. **Run the main menu**:
   ```bash
   ./mac_suite.sh
   ```

3. **The suite will automatically:**
   - Install required tools (ClamAV, rkhunter, etc.) via Homebrew
   - Create configuration files
   - Set up logging directories
   - Initialize baselines

---

## Troubleshooting

### "Permission denied" error
```bash
chmod +x mac_suite.sh MacGuardianSuite/*.sh
```

### "Command not found" errors
The suite will auto-install missing tools via Homebrew. Make sure Homebrew is installed:
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Scripts won't run
Make sure you're in the correct directory:
```bash
cd /Users/abel_elreaper/Desktop/MacGuardianProject
./mac_suite.sh
```

---

## Quick Reference

| Tool | Purpose | Frequency |
|------|---------|-----------|
| Mac Guardian | Cleanup & Security | Weekly |
| Mac Watchdog | File Integrity | Daily |
| Mac Blue Team | Threat Detection | Weekly/Monthly |
| Mac AI | ML Analysis | Weekly |
| Security Audit | Security Assessment | Monthly |

---

## Need Help?

- Check logs: `~/.macguardian/logs/`
- View reports: `~/.macguardian/reports/`
- Configuration: `~/.macguardian/config.conf`

