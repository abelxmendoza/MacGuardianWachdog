# MacGuardian Watchdog - CI/CD Documentation

## Overview

MacGuardian Watchdog uses CI/CD pipelines to ensure code quality, run tests, and automate releases.

## CI/CD Platforms

### GitHub Actions

**Location**: `.github/workflows/`

#### Workflows

1. **`ci.yml`** - Continuous Integration
   - Runs on: push, pull_request, manual trigger
   - Jobs:
     - Syntax validation (Bash + Python)
     - Unit tests (BATS)
     - Integration tests (BATS)
     - Functional tests
     - E2E tests
     - Security scan
     - Build check
     - Code linting
     - Test summary

2. **`release.yml`** - Release Pipeline
   - Runs on: release creation, manual trigger
   - Jobs:
     - Build release package
     - Code sign application
     - Notarize application
     - Create release archive
     - Upload to GitHub Releases

3. **`daily-tests.yml`** - Daily Test Suite
   - Runs on: Daily schedule (2 AM UTC), manual trigger
   - Jobs:
     - Full test suite
     - E2E tests
     - Security tests
     - Test report generation

### GitLab CI

**Location**: `.gitlab-ci.yml`

#### Stages

1. **Validate** - Syntax checking
2. **Test** - Unit, integration, functional, E2E tests
3. **Security** - Security scanning
4. **Build** - Application building
5. **Deploy** - Deployment (staging/production)

## Running CI/CD Locally

### GitHub Actions (using act)

```bash
# Install act
brew install act

# Run CI workflow
act -W .github/workflows/ci.yml

# Run specific job
act -j syntax-check -W .github/workflows/ci.yml
```

### GitLab CI (using gitlab-runner)

```bash
# Install gitlab-runner
brew install gitlab-runner

# Run pipeline locally
gitlab-runner exec shell syntax-check
```

## CI/CD Secrets

### GitHub Actions Secrets

Required for release pipeline:

- `APPLE_CERTIFICATE` - Apple Developer certificate (base64 encoded)
- `APPLE_CERTIFICATE_PASSWORD` - Certificate password
- `APPLE_ID` - Apple ID for notarization
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `APPLE_TEAM_ID` - Apple Developer Team ID

### Setting Secrets

**GitHub**:
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret

**GitLab**:
1. Go to Settings → CI/CD → Variables
2. Add each variable

## Test Execution in CI

### Syntax Validation

```yaml
- Validates all .sh files with `bash -n`
- Validates all .py files with `python3 -m py_compile`
```

### Unit Tests

```yaml
- Requires BATS framework
- Runs: test_validators.sh, test_system_state.sh, test_hashing.sh
```

### Integration Tests

```yaml
- Requires BATS framework
- Runs: test_event_pipeline.sh, test_watcher_output.sh
```

### Functional Tests

```yaml
- Runs: run_all_tests.sh
- Includes: syntax validation, validator tests, event writer tests, Python tests
```

### E2E Tests

```yaml
- Runs: test_full_installation.sh
- Tests: installation flow, event generation, event bus
```

### Security Tests

```yaml
- Runs: test_input_injection.sh
- Tests: command injection, path traversal, SQL injection, XSS prevention
```

## Build Process

### Application Build

```bash
cd MacGuardianSuiteUI
xcodebuild -scheme MacGuardianSuiteUI -configuration Release archive
```

### Installer Package

```bash
cd MacGuardianSuite
bash installers/macos_installer.sh
```

### Code Signing

```bash
codesign --force --deep --sign "Developer ID Application: Omega Technologies" \
    --entitlements hardening/codesign_config/plist_entitlements.xml \
    --options runtime \
    MacGuardianSuiteUI.app
```

### Notarization

```bash
xcrun notarytool submit MacGuardianSuiteUI.zip \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait

xcrun stapler staple MacGuardianSuiteUI.app
```

## Deployment

### Staging Deployment

- Triggered manually on `develop` branch
- Deploys to staging environment
- Runs smoke tests

### Production Deployment

- Triggered manually on tags
- Requires approval
- Deploys to production environment
- Creates release notes

## CI/CD Best Practices

1. **Always run tests before merging**
   - All PRs must pass CI checks
   - No merging with failing tests

2. **Keep secrets secure**
   - Never commit secrets to repository
   - Use CI/CD secret management
   - Rotate secrets regularly

3. **Monitor CI/CD health**
   - Check daily test reports
   - Review failed builds
   - Fix flaky tests

4. **Version management**
   - Use semantic versioning
   - Tag releases properly
   - Update CHANGELOG.md

5. **Documentation**
   - Keep CI/CD docs updated
   - Document new workflows
   - Explain deployment process

## Troubleshooting

### CI Fails: Syntax Errors

```bash
# Run locally to debug
bash -n MacGuardianSuite/core/validators.sh
```

### CI Fails: Tests

```bash
# Run tests locally
cd MacGuardianSuite/tests
bash run_all_tests.sh
```

### CI Fails: Build

```bash
# Build locally
cd MacGuardianSuiteUI
xcodebuild -scheme MacGuardianSuiteUI -configuration Debug clean build
```

### CI Fails: Code Signing

- Verify certificate is valid
- Check certificate password
- Ensure Team ID is correct

## Status Badges

Add to README.md:

```markdown
![CI](https://github.com/yourusername/MacGuardianProject/workflows/MacGuardian%20CI/badge.svg)
![Tests](https://github.com/yourusername/MacGuardianProject/workflows/MacGuardian%20CI/badge.svg?branch=main)
```

## Future Enhancements

- [ ] Automated dependency updates (Dependabot)
- [ ] Code coverage reporting
- [ ] Performance benchmarking
- [ ] Automated security scanning (Snyk, CodeQL)
- [ ] Automated documentation generation
- [ ] Multi-platform testing (different macOS versions)

