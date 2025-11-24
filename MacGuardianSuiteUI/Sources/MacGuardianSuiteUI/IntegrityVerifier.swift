import Foundation
import CryptoKit

/// Verifies integrity of scripts and critical files
class IntegrityVerifier {
    static let shared = IntegrityVerifier()
    
    private let checksumsFile = "MacGuardianSuite/.checksums.json"
    private var knownChecksums: [String: String] = [:]
    
    private init() {
        loadChecksums()
    }
    
    /// Calculate SHA-256 checksum of a file
    func calculateChecksum(filePath: String) -> String? {
        guard let fileData = FileManager.default.contents(atPath: filePath) else {
            return nil
        }
        
        let hash = SHA256.hash(data: fileData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify file integrity against known checksums
    func verifyFile(_ filePath: String) -> (isValid: Bool, message: String) {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return (false, "File does not exist")
        }
        
        guard let calculatedChecksum = calculateChecksum(filePath: filePath) else {
            return (false, "Failed to calculate checksum")
        }
        
        let relativePath = getRelativePath(filePath)
        
        // If we have a stored checksum, verify against it
        if let storedChecksum = knownChecksums[relativePath] {
            if calculatedChecksum == storedChecksum {
                return (true, "File integrity verified")
            } else {
                auditLog(action: "integrity_failure", file: relativePath, details: "Checksum mismatch")
                return (false, "⚠️ File integrity check failed - file may have been modified!")
            }
        } else {
            // First time seeing this file - store its checksum
            knownChecksums[relativePath] = calculatedChecksum
            saveChecksums()
            return (true, "File checksum recorded (first verification)")
        }
    }
    
    /// Verify all critical scripts
    func verifyCriticalFiles(repositoryPath: String) -> [String: (isValid: Bool, message: String)] {
        let criticalFiles = [
            "MacGuardianSuite/mac_guardian.sh",
            "MacGuardianSuite/mac_watchdog.sh",
            "MacGuardianSuite/mac_blueteam.sh",
            "MacGuardianSuite/mac_remediation.sh",
            "MacGuardianSuite/utils.sh",
            "MacGuardianSuite/config.sh"
        ]
        
        var results: [String: (isValid: Bool, message: String)] = [:]
        
        for file in criticalFiles {
            let fullPath = URL(fileURLWithPath: repositoryPath).appendingPathComponent(file).path
            results[file] = verifyFile(fullPath)
        }
        
        return results
    }
    
    /// Check file permissions (should be 755 for scripts)
    func verifyPermissions(_ filePath: String) -> (isValid: Bool, message: String) {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
              let permissions = attributes[.posixPermissions] as? Int else {
            return (false, "Could not read file permissions")
        }
        
        let expectedPermissions = 0o755
        if permissions == expectedPermissions || (permissions & 0o111) != 0 {
            return (true, "File permissions OK")
        } else {
            return (false, "File is not executable (permissions: \(String(permissions, radix: 8)))")
        }
    }
    
    /// Load stored checksums
    private func loadChecksums() {
        let expandedPath = (checksumsFile as NSString).expandingTildeInPath
        if let data = FileManager.default.contents(atPath: expandedPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            knownChecksums = json
        }
    }
    
    /// Save checksums to file
    private func saveChecksums() {
        let expandedPath = (checksumsFile as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        if let data = try? JSONSerialization.data(withJSONObject: knownChecksums, options: .prettyPrinted) {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url)
        }
    }
    
    /// Get relative path from absolute path
    private func getRelativePath(_ absolutePath: String) -> String {
        // Try to extract relative path from repository
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        if absolutePath.hasPrefix(homeDir) {
            return String(absolutePath.dropFirst(homeDir.count + 1))
        }
        return absolutePath
    }
    
    /// Audit logging
    private func auditLog(action: String, file: String, details: String) {
        let logEntry = """
        [\(Date().ISO8601Format())] INTEGRITY: \(action) - File: \(file) - \(details)
        """
        
        if let logDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("MacGuardianSuite/audit") {
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
            let logFile = logDir.appendingPathComponent("integrity_audit.log")
            
            if let data = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFile.path) {
                    if let fileHandle = FileHandle(forWritingAtPath: logFile.path) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: logFile)
                }
            }
        }
    }
}

