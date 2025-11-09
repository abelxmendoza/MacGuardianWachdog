# Release Guide

This document explains how to create releases for MacGuardian Suite.

## Automated Releases (Recommended)

### Using GitHub Actions

Releases are automatically created when you push a version tag:

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Actions workflow will:
1. Build tarball and zip archives
2. Optionally create a .pkg installer
3. Sign artifacts (if certificates are configured)
4. Create a GitHub release with all artifacts
5. Generate release notes with checksums

### Manual Release

You can also trigger a release manually from the GitHub Actions tab:
1. Go to Actions > Release
2. Click "Run workflow"
3. Enter the version tag (e.g., `v1.0.0`)
4. Click "Run workflow"

## Signing Certificates (Optional)

To sign macOS packages, you need:

1. **Apple Developer Certificate** (Developer ID Installer)
   - Obtain from: https://developer.apple.com/account/resources/certificates/list
   - Export as .p12 file

2. **GitHub Secrets** (Settings > Secrets and variables > Actions):
   - `MACOS_CERTIFICATE_P12`: Base64-encoded .p12 certificate
   - `KEYCHAIN_PASSWORD`: Password for temporary keychain
   - `CERTIFICATE_PASSWORD`: Password for .p12 certificate
   - `APPLE_DEVELOPER_NAME`: Your Apple Developer name (e.g., "John Doe (ABC123XYZ)")

### Exporting Certificate

```bash
# Export certificate as .p12
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities -f pkcs12 -o certificate.p12 \
  -P "your-password"

# Base64 encode for GitHub Secret
base64 -i certificate.p12 | pbcopy
```

## Release Artifacts

Each release includes:

- **MacGuardianSuite-{VERSION}-macos.tar.gz**: Tarball archive
- **MacGuardianSuite-{VERSION}-macos.zip**: Zip archive
- **MacGuardianSuite-{VERSION}.pkg**: macOS installer package (if productbuild available)
- **SHA-256 checksums**: For all artifacts

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Examples:
- `v1.0.0` - Initial release
- `v1.1.0` - New features
- `v1.1.1` - Bug fixes
- `v2.0.0` - Breaking changes

## Pre-release Testing

Before creating a release:

1. **Test locally:**
   ```bash
   # Make scripts executable
   chmod +x mac_suite.sh MacGuardianSuite/*.sh
   
   # Run verification
   ./MacGuardianSuite/verify_suite.sh
   
   # Test dry-run mode
   ./MacGuardianSuite/mac_remediation.sh
   ```

2. **Update CHANGELOG.md** (if you have one)

3. **Update version in scripts** (if needed)

4. **Test installation:**
   ```bash
   # Create test release
   mkdir -p test-release
   cp -R MacGuardianSuite test-release/
   cp mac_suite.sh test-release/
   cd test-release
   ./install.sh
   ```

## Release Checklist

- [ ] All tests pass
- [ ] Documentation updated (README, SECURITY.md, PRIVACY.md)
- [ ] Version tag follows semantic versioning
- [ ] CHANGELOG.md updated (if maintained)
- [ ] Release notes prepared
- [ ] Signing certificates configured (optional)
- [ ] GitHub Actions workflow tested

## Troubleshooting

### Workflow fails on signing

- Check that all GitHub Secrets are set correctly
- Verify certificate is valid and not expired
- Ensure certificate password is correct

### Package not created

- `productbuild` may not be available on GitHub Actions runner
- This is normal - tarball and zip are always created

### Release not created

- Check GitHub token permissions
- Verify tag format (must start with `v`)
- Check workflow logs for errors

## Manual Build (Local)

If you want to build releases locally:

```bash
# Create release directory
mkdir -p release/MacGuardianSuite-v1.0.0
cp -R MacGuardianSuite release/MacGuardianSuite-v1.0.0/
cp mac_suite.sh README.md LICENSE SECURITY.md PRIVACY.md release/MacGuardianSuite-v1.0.0/

# Create tarball
cd release
tar -czf MacGuardianSuite-v1.0.0-macos.tar.gz MacGuardianSuite-v1.0.0/
shasum -a 256 MacGuardianSuite-v1.0.0-macos.tar.gz > MacGuardianSuite-v1.0.0-macos.tar.gz.sha256

# Create zip
zip -r MacGuardianSuite-v1.0.0-macos.zip MacGuardianSuite-v1.0.0/
shasum -a 256 MacGuardianSuite-v1.0.0-macos.zip > MacGuardianSuite-v1.0.0-macos.zip.sha256
```

