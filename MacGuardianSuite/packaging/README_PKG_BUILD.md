# MacGuardian Watchdog - Package Build Guide

## Overview

This guide explains how to build a distributable `.pkg` installer for MacGuardian Watchdog.

## Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools
- Packages.app (optional, for GUI) OR `pkgbuild`/`productbuild` (command-line)

## Method 1: Using Packages.app (GUI)

1. Open `packaging/macguardian.pkgproj` in Packages.app
2. Configure signing identity
3. Build → Build Package
4. Output: `MacGuardianWatchdog.pkg`

## Method 2: Using Command Line

### Step 1: Prepare Package Structure

```bash
cd MacGuardianSuite
mkdir -p pkg_root/usr/local/macguardian
cp -r core daemons auditors detectors privacy outputs pkg_root/usr/local/macguardian/
cp -r installers pkg_root/usr/local/macguardian/
```

### Step 2: Create Component Package

```bash
pkgbuild \
    --root pkg_root \
    --identifier com.macguardian.watchdog \
    --version 1.0.0 \
    --install-location / \
    --scripts installers \
    MacGuardianWatchdog.pkg
```

### Step 3: Sign Package

```bash
productsign \
    --sign "Developer ID Installer: Omega Technologies" \
    MacGuardianWatchdog.pkg \
    MacGuardianWatchdog-signed.pkg
```

### Step 4: Notarize Package

```bash
# Submit for notarization
xcrun notarytool submit MacGuardianWatchdog-signed.pkg \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password" \
    --wait

# Staple ticket
xcrun stapler staple MacGuardianWatchdog-signed.pkg
```

## Distribution

### Direct Distribution

- Upload signed and notarized `.pkg` to download server
- Users download and install
- Gatekeeper will verify notarization

### MDM Distribution

- Upload `.pkg` to MDM system
- Deploy via MDM to managed devices
- Configuration profile handles permissions

## Verification

```bash
# Verify package signature
pkgutil --check-signature MacGuardianWatchdog-signed.pkg

# Verify notarization
spctl --assess --type install --verbose MacGuardianWatchdog-signed.pkg
```

## Troubleshooting

### Issue: Package won't install
- Check code signature: `pkgutil --check-signature`
- Verify notarization: `spctl --assess`
- Check installer logs: Console.app

### Issue: Notarization fails
- Ensure Hardened Runtime is enabled
- Check entitlements are correct
- Verify signing identity is valid

