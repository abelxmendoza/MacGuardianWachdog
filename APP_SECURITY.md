# 🔒 MacGuardian Suite App Security

## Overview

MacGuardian Suite now includes comprehensive security features to protect the app itself. A security app should be secure, and we've implemented multiple layers of protection.

## Security Features

### 1. **Secure Password Storage (Keychain)**

**Problem**: Passwords were previously stored in UserDefaults (plaintext)

**Solution**: All passwords now stored in macOS Keychain
- Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum security
- Encrypted at rest by macOS
- Only accessible by the app
- Automatic audit logging of access

**Implementation**:
- `SecureStorage.swift` - Keychain wrapper
- Passwords automatically migrated from UserDefaults
- SMTP passwords stored securely

### 2. **File Integrity Verification**

**Problem**: Scripts could be tampered with, compromising security

**Solution**: SHA-256 checksums verify file integrity
- Calculates checksums for critical files
- Compares against stored baseline
- Detects any modifications
- Warns user if tampering detected

**Implementation**:
- `IntegrityVerifier.swift` - Checksum verification
- `app_security.sh` - Command-line integrity checker
- Automatic verification on app startup
- Verification before script execution

**Critical Files Monitored**:
- `mac_guardian.sh`
- `mac_watchdog.sh`
- `mac_blueteam.sh`
- `mac_remediation.sh`
- `utils.sh`
- `config.sh`

### 3. **Input Validation & Sanitization**

**Problem**: Injection attacks through user inputs

**Solution**: Comprehensive input validation
- Email format validation
- Path sanitization (prevents directory traversal)
- Script path validation (must be within repository)
- Argument sanitization (removes dangerous characters)
- SMTP settings validation

**Implementation**:
- `InputValidator.swift` - All validation logic
- Validates before script execution
- Blocks dangerous paths
- Sanitizes command arguments

**Blocked Characters**:
- `;`, `&`, `|`, `` ` ``, `$`, `(`, `)`, `<`, `>`
- Null bytes
- Path traversal (`../`, `..\\`)

### 4. **Audit Logging**

**Problem**: No visibility into security events

**Solution**: Comprehensive audit trail
- All security events logged
- Timestamped entries
- Separate logs for different event types
- Stored in secure location

**Log Files**:
- `security_audit.log` - Password/keychain operations
- `integrity_audit.log` - File integrity checks
- `validation_audit.log` - Input validation failures

**Location**: `~/Library/Application Support/MacGuardianSuite/audit/`

### 5. **File Permission Verification**

**Problem**: Scripts might not have correct permissions

**Solution**: Automatic permission checking
- Verifies scripts are executable (755)
- Warns if permissions incorrect
- Checks before execution

**Implementation**:
- `IntegrityVerifier.verifyPermissions()`
- `app_security.sh --check-permissions`

### 6. **Security Dashboard**

**Problem**: No visibility into app security status

**Solution**: New Security Dashboard view
- Real-time integrity status
- Security feature status
- File verification results
- One-click integrity check

**Access**: Navigate to "Security" tab in app

## Usage

### Generate Checksums

First time setup - generate baseline checksums:

```bash
cd MacGuardianSuite
./app_security.sh --generate-checksums
```

### Verify Integrity

Check if files have been modified:

```bash
./app_security.sh --verify
```

### Check Permissions

Verify file permissions:

```bash
./app_security.sh --check-permissions
```

### Run All Checks

```bash
./app_security.sh --all
```

## Security Best Practices

1. **Generate Checksums After Installation**
   - Run `app_security.sh --generate-checksums` after installing
   - Store `.checksums.json` securely (consider backing up)

2. **Regular Integrity Checks**
   - App automatically checks on startup
   - Use Security Dashboard for manual checks
   - Run `app_security.sh --verify` periodically

3. **Monitor Audit Logs**
   - Review audit logs regularly
   - Look for suspicious activity
   - Check for failed integrity checks

4. **Keep App Updated**
   - Update checksums after app updates
   - Verify integrity after updates
   - Report any integrity failures

## Security Architecture

```
┌─────────────────────────────────────┐
│      MacGuardian Suite UI           │
├─────────────────────────────────────┤
│  Input Validation → Sanitization    │
│  Path Validation → Execution        │
│  Integrity Check → Verification     │
│  Permission Check → Execution        │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│      Secure Storage Layer           │
├─────────────────────────────────────┤
│  Keychain (Passwords)               │
│  Checksums (Integrity)              │
│  Audit Logs (Events)                │
└─────────────────────────────────────┘
```

## Threat Model

### Protected Against:

✅ **Password Theft**
- Passwords encrypted in Keychain
- Not accessible to other apps
- Audit trail of access

✅ **File Tampering**
- Checksum verification detects changes
- Warns before execution
- Can block execution if configured

✅ **Injection Attacks**
- Input sanitization
- Path validation
- Argument sanitization

✅ **Unauthorized Access**
- Permission verification
- Path restrictions
- Audit logging

### Not Protected Against:

⚠️ **Physical Access**
- If attacker has physical access and admin rights, they can modify files
- Mitigation: Use FileVault encryption

⚠️ **Root Compromise**
- If system is compromised at root level, all protections can be bypassed
- Mitigation: Regular security audits, keep system updated

## Compliance

- **OWASP Top 10**: Addresses injection, broken authentication
- **CIS Controls**: Implements secure configuration, access control
- **NIST Framework**: Implements Protect, Detect functions

## Future Enhancements

- [ ] Code signing verification
- [ ] Network traffic encryption
- [ ] Two-factor authentication for sensitive operations
- [ ] Automated security scanning
- [ ] Security incident response automation

## Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. Email security concerns to: [Your Security Email]
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and coordinate disclosure.

