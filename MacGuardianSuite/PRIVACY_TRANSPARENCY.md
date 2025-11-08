# 🔒 Privacy & Transparency Report

## What MacGuardian Suite Monitors (And What It Doesn't)

### ✅ What We Monitor (Connection Metadata Only)

**Network Monitoring:**
- ✅ Which processes have network connections
- ✅ What IP addresses your Mac connects to
- ✅ What ports are being used
- ✅ Connection status (ESTABLISHED, LISTENING, etc.)

**This is like macOS Activity Monitor** - we see connection metadata, NOT content.

### ❌ What We DON'T Monitor (No Wiretapping!)

- ❌ **NO packet capture** - We don't use tcpdump, wireshark, or packet sniffers
- ❌ **NO content inspection** - We don't read what you're sending/receiving
- ❌ **NO deep packet inspection** - We don't analyze packet payloads
- ❌ **NO wiretapping** - We don't intercept or record network traffic
- ❌ **NO data collection** - All processing happens locally on your Mac
- ❌ **NO external servers** - Nothing is sent to external services

## How Network Monitoring Works

### What We Use:
- `lsof -i` - Shows open network connections (like netstat)
- `netstat` - Shows network statistics
- Process information - Which apps are connected

### What This Shows:
```
Process: Chrome
IP: 142.250.185.14
Port: 443
Status: ESTABLISHED
```

### What This DOESN'T Show:
- ❌ What you're browsing
- ❌ What data you're sending
- ❌ Email content
- ❌ Messages or chats
- ❌ File contents being transferred

## Privacy Guarantees

1. **100% Local Processing**
   - Everything runs on your Mac
   - No cloud services
   - No external data transmission

2. **Metadata Only**
   - We only see connection information
   - No content inspection
   - No packet capture

3. **You're in Control**
   - Privacy Mode lets you disable network monitoring
   - You can choose what to monitor
   - All settings are local

4. **Open Source**
   - You can review all code
   - No hidden functionality
   - Complete transparency

## Privacy Modes

### Minimal Mode
- ✅ Essential security checks only
- ❌ No network monitoring
- ❌ No performance tracking
- ❌ Minimal logging

### Light Mode
- ✅ Basic security checks
- ✅ Limited network checks (connection count only)
- ❌ No performance tracking
- ❌ Basic logging

### Standard Mode (Default)
- ✅ Full security suite
- ✅ Network connection monitoring (metadata only)
- ✅ Performance tracking
- ✅ Standard logging

### Full Mode
- ✅ Everything enabled
- ✅ Detailed network analysis
- ✅ Complete performance tracking
- ✅ Detailed logging

## Comparison to Other Tools

| Feature | MacGuardian | Commercial Tools | Wiretapping? |
|---------|-------------|------------------|--------------|
| Connection metadata | ✅ | ✅ | ❌ No |
| Packet capture | ❌ | ✅ (some) | ⚠️ Yes |
| Content inspection | ❌ | ✅ (some) | ⚠️ Yes |
| Deep packet inspection | ❌ | ✅ (some) | ⚠️ Yes |
| Local processing | ✅ | ❌ (often cloud) | N/A |
| Privacy controls | ✅ | ❌ (rare) | N/A |

## Is This Wiretapping?

**NO!** Wiretapping means:
- Intercepting and recording actual communication content
- Capturing packet payloads
- Reading data being transmitted

**What we do:**
- Check which apps are connected (like Activity Monitor)
- See IP addresses and ports (like netstat)
- Monitor connection status (like system tools)

**This is the same level of monitoring as:**
- macOS Activity Monitor
- `netstat` command
- `lsof` command
- System network preferences

## How to Reduce Monitoring

1. **Use Privacy Mode:**
   ```bash
   ./MacGuardianSuite/privacy_mode.sh minimal
   ```

2. **Disable Network Monitoring:**
   ```bash
   ./MacGuardianSuite/privacy_mode.sh set minimal
   ```

3. **Check Current Settings:**
   ```bash
   ./MacGuardianSuite/privacy_mode.sh status
   ```

## Bottom Line

**Your app is NOT wiretapping.** It's doing the same level of network monitoring as built-in macOS tools. You can reduce or disable monitoring anytime using Privacy Mode.

**All processing is local** - nothing leaves your Mac.

