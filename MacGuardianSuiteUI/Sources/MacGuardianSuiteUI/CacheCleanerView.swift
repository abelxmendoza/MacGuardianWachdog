import SwiftUI
#if os(macOS)
import AppKit
#endif

struct CacheCleanerView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var selectedBrowsers: Set<String> = ["Safari", "Chrome", "Firefox", "Edge"]
    @State private var cleanCache = true
    @State private var cleanCookies = false
    @State private var cleanHistory = false
    @State private var cleanDownloads = false
    @State private var cleanAutofill = false
    @State private var cleanSystemCache = true
    @State private var cleanHomebrewCache = true
    @State private var isLoading = false
    @State private var showConfirmation = false
    @State private var cleaningResult: CleaningResult?
    @State private var cacheSizes: [String: String] = [:]
    @State private var totalSize: String = "Calculating..."
    
    let availableBrowsers = ["Safari", "Chrome", "Firefox", "Edge"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "trash.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cache Cleaner")
                        .font(.title.bold())
                        .foregroundColor(.themeText)
                    Text("Safely clear browser and system caches to free up disk space")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                
                Button {
                    calculateCacheSizes()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Sizes")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.themePurple)
                .disabled(isLoading)
            }
            .padding()
            .background(Color.themeDarkGray)
            
            Divider()
                .background(Color.themePurpleDark)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Total size estimate
                    if !totalSize.isEmpty && totalSize != "Calculating..." {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.themePurple)
                            Text("Estimated space to free: \(totalSize)")
                                .font(.headline)
                                .foregroundColor(.themeText)
                            Spacer()
                        }
                        .padding()
                        .background(Color.themePurple.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Browser Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Browsers")
                            .font(.headline)
                            .foregroundColor(.themeText)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(availableBrowsers, id: \.self) { browser in
                                BrowserToggle(
                                    browser: browser,
                                    isSelected: selectedBrowsers.contains(browser),
                                    cacheSize: cacheSizes[browser] ?? "Unknown",
                                    onToggle: {
                                        if selectedBrowsers.contains(browser) {
                                            selectedBrowsers.remove(browser)
                                        } else {
                                            selectedBrowsers.insert(browser)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.themeDarkGray.opacity(0.5))
                    .cornerRadius(12)
                    
                    // Browser Data Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What to Clean")
                            .font(.headline)
                            .foregroundColor(.themeText)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            CleanOptionToggle(
                                title: "Cache",
                                description: "Temporary files and cached data",
                                icon: "externaldrive.fill",
                                isOn: $cleanCache
                            )
                            
                            CleanOptionToggle(
                                title: "Cookies",
                                description: "Website cookies and login sessions",
                                icon: "lock.fill",
                                isOn: $cleanCookies
                            )
                            
                            CleanOptionToggle(
                                title: "History",
                                description: "Browsing history",
                                icon: "clock.fill",
                                isOn: $cleanHistory
                            )
                            
                            CleanOptionToggle(
                                title: "Download History",
                                description: "List of downloaded files",
                                icon: "arrow.down.circle.fill",
                                isOn: $cleanDownloads
                            )
                            
                            CleanOptionToggle(
                                title: "Autofill Data",
                                description: "Saved form data and passwords",
                                icon: "key.fill",
                                isOn: $cleanAutofill
                            )
                        }
                    }
                    .padding()
                    .background(Color.themeDarkGray.opacity(0.5))
                    .cornerRadius(12)
                    
                    // System Cache Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("System Cache")
                            .font(.headline)
                            .foregroundColor(.themeText)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            CleanOptionToggle(
                                title: "System Cache",
                                description: "macOS system cache files (~/Library/Caches)",
                                icon: "gear.circle.fill",
                                isOn: $cleanSystemCache
                            )
                            
                            CleanOptionToggle(
                                title: "Homebrew Cache",
                                description: "Homebrew package cache (if installed)",
                                icon: "cup.and.saucer.fill",
                                isOn: $cleanHomebrewCache
                            )
                        }
                    }
                    .padding()
                    .background(Color.themeDarkGray.opacity(0.5))
                    .cornerRadius(12)
                    
                    // Safety Warning
                    if cleanCookies || cleanHistory || cleanAutofill {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚠️ Data Loss Warning")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)
                                Text("Clearing cookies, history, or autofill data will log you out of websites and remove saved information. Make sure you have backups if needed.")
                                    .font(.caption)
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            Divider()
                .background(Color.themePurpleDark)
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    // Preview what will be cleaned
                    showConfirmation = true
                } label: {
                    Label("Preview Clean", systemImage: "eye.fill")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .tint(.themePurple)
                .disabled(selectedBrowsers.isEmpty && !cleanSystemCache && !cleanHomebrewCache)
                
                Spacer()
                
                Button {
                    performClean()
                } label: {
                    Label("Clean Now", systemImage: "trash.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isLoading || (selectedBrowsers.isEmpty && !cleanSystemCache && !cleanHomebrewCache))
            }
            .padding()
            .background(Color.themeDarkGray)
        }
        .background(Color.themeBlack)
        .onAppear {
            calculateCacheSizes()
        }
        .alert("Clean Cache", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Preview", role: .none) {
                previewClean()
            }
        } message: {
            Text("This will clean selected caches. You can preview what will be cleaned first, or proceed directly.")
        }
        .alert("Cleaning Result", isPresented: .constant(cleaningResult != nil), presenting: cleaningResult) { result in
            Button("OK") {
                cleaningResult = nil
                calculateCacheSizes()
            }
        } message: { result in
            Text(result.message)
        }
    }
    
    private func calculateCacheSizes() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var sizes: [String: String] = [:]
            var totalBytes: Int64 = 0
            
            // Calculate browser cache sizes for all browsers (to show sizes even if not selected)
            for browser in availableBrowsers {
                let size = getBrowserCacheSize(browser: browser)
                sizes[browser] = size.formatted
                // Only add to total if selected
                if selectedBrowsers.contains(browser) {
                    totalBytes += size.bytes
                }
            }
            
            // Calculate system cache size
            if cleanSystemCache {
                let systemSize = getSystemCacheSize()
                sizes["System"] = systemSize.formatted
                totalBytes += systemSize.bytes
            }
            
            // Calculate Homebrew cache size
            if cleanHomebrewCache {
                let brewSize = getHomebrewCacheSize()
                sizes["Homebrew"] = brewSize.formatted
                totalBytes += brewSize.bytes
            }
            
            DispatchQueue.main.async {
                cacheSizes = sizes
                totalSize = formatBytes(totalBytes)
                isLoading = false
            }
        }
    }
    
    private func previewClean() {
        // Run browser_cleanup.sh with --dry-run
        let browsers = selectedBrowsers.joined(separator: ",").lowercased()
        var args: [String] = ["--dry-run"]
        
        if cleanCache && !cleanCookies && !cleanHistory && !cleanDownloads && !cleanAutofill {
            args.append("--cache-only")
        } else {
            if cleanCookies { args.append("--cookies") }
            if cleanHistory { args.append("--history") }
            if cleanDownloads { args.append("--downloads") }
            if cleanAutofill { args.append("--autofill") }
            if cleanCache && cleanCookies && cleanHistory && cleanDownloads && cleanAutofill {
                args.append("--all")
            }
        }
        
        if !browsers.isEmpty {
            args.append("--browsers")
            args.append(browsers)
        }
        
        let _ = runBrowserCleanup(args: args, isPreview: true)
    }
    
    private func performClean() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [String] = []
            var errors: [String] = []
            
            // Clean browsers
            if !selectedBrowsers.isEmpty {
                let browsers = selectedBrowsers.joined(separator: ",").lowercased()
                var args: [String] = []
                
                if cleanCache && !cleanCookies && !cleanHistory && !cleanDownloads && !cleanAutofill {
                    args.append("--cache-only")
                } else {
                    if cleanCache { args.append("--cache-only") }
                    if cleanCookies { args.append("--cookies") }
                    if cleanHistory { args.append("--history") }
                    if cleanDownloads { args.append("--downloads") }
                    if cleanAutofill { args.append("--autofill") }
                    if cleanCache && cleanCookies && cleanHistory && cleanDownloads && cleanAutofill {
                        args = ["--all"]
                    }
                }
                
                if !browsers.isEmpty {
                    args.append("--browsers")
                    args.append(browsers)
                }
                
                let browserResult = runBrowserCleanup(args: args, isPreview: false)
                if browserResult.success {
                    results.append("Browser caches cleaned")
                } else {
                    errors.append(browserResult.message)
                }
            }
            
            // Clean system cache
            if cleanSystemCache {
                let systemResult = cleanSystemCaches()
                if systemResult.success {
                    results.append("System cache cleaned")
                } else {
                    errors.append(systemResult.message)
                }
            }
            
            // Clean Homebrew cache
            if cleanHomebrewCache {
                let brewResult = performHomebrewCleanup()
                if brewResult.success {
                    results.append("Homebrew cache cleaned")
                } else {
                    errors.append(brewResult.message)
                }
            }
            
            DispatchQueue.main.async {
                isLoading = false
                let message: String
                if errors.isEmpty {
                    message = "✅ Successfully cleaned:\n\n" + results.joined(separator: "\n")
                } else {
                    message = "⚠️ Partial success:\n\n" + results.joined(separator: "\n") + "\n\nErrors:\n" + errors.joined(separator: "\n")
                }
                cleaningResult = CleaningResult(success: errors.isEmpty, message: message)
            }
        }
    }
}

struct BrowserToggle: View {
    let browser: String
    let isSelected: Bool
    let cacheSize: String
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                Image(systemName: browserIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .themeTextSecondary)
                Text(browser)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .themeText)
                Text(cacheSize)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .themeTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.themePurple : Color.themeDarkGray.opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.themePurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var browserIcon: String {
        switch browser {
        case "Safari": return "safari.fill"
        case "Chrome": return "globe"
        case "Firefox": return "flame.fill"
        case "Edge": return "e.circle.fill"
        default: return "globe"
        }
    }
}

struct CleanOptionToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.themePurple)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.themeText)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}

struct CleaningResult: Identifiable {
    let id = UUID()
    let success: Bool
    let message: String
}

// MARK: - Cache Size Calculation

struct CacheSize {
    let bytes: Int64
    let formatted: String
}

func getBrowserCacheSize(browser: String) -> CacheSize {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    var totalBytes: Int64 = 0
    
    switch browser {
    case "Safari":
        let cacheDirs = [
            "\(homeDir)/Library/Caches/com.apple.Safari",
            "\(homeDir)/Library/Caches/com.apple.WebKit.Networking",
            "\(homeDir)/Library/Caches/com.apple.WebKit.WebContent"
        ]
        for dir in cacheDirs {
            totalBytes += getDirectorySize(dir)
        }
    case "Chrome":
        totalBytes += getDirectorySize("\(homeDir)/Library/Caches/Google/Chrome")
    case "Firefox":
        totalBytes += getDirectorySize("\(homeDir)/Library/Caches/Firefox")
    case "Edge":
        totalBytes += getDirectorySize("\(homeDir)/Library/Caches/Microsoft Edge")
    default:
        break
    }
    
    return CacheSize(bytes: totalBytes, formatted: formatBytes(totalBytes))
}

func getSystemCacheSize() -> CacheSize {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    let cacheDir = "\(homeDir)/Library/Caches"
    let bytes = getDirectorySize(cacheDir)
    return CacheSize(bytes: bytes, formatted: formatBytes(bytes))
}

func getHomebrewCacheSize() -> CacheSize {
    let cacheDir = "/opt/homebrew/var/cache" // Intel: /usr/local/var/cache
    var bytes = getDirectorySize(cacheDir)
    if bytes == 0 {
        bytes = getDirectorySize("/usr/local/var/cache")
    }
    return CacheSize(bytes: bytes, formatted: formatBytes(bytes))
}

func getDirectorySize(_ path: String) -> Int64 {
    guard let enumerator = FileManager.default.enumerator(atPath: path) else {
        return 0
    }
    
    var totalSize: Int64 = 0
    for file in enumerator {
        if let filePath = file as? String {
            let fullPath = (path as NSString).appendingPathComponent(filePath)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
    }
    return totalSize
}

func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    return formatter.string(fromByteCount: bytes)
}

// MARK: - Cache Cleaning Functions

#if os(macOS)
func runBrowserCleanup(args: [String], isPreview: Bool) -> (success: Bool, message: String) {
    let scriptPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop")
        .appendingPathComponent("MacGuardianProject")
        .appendingPathComponent("MacGuardianSuite")
        .appendingPathComponent("browser_cleanup.sh")
        .path
    
    guard FileManager.default.fileExists(atPath: scriptPath) else {
        return (false, "Browser cleanup script not found")
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", "cd '\(FileManager.default.homeDirectoryForCurrentUser.path)/Desktop/MacGuardianProject/MacGuardianSuite' && bash '\(scriptPath)' \(args.joined(separator: " "))"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if process.terminationStatus == 0 {
            return (true, isPreview ? "Preview: \(output)" : "Cleaned successfully")
        } else {
            return (false, "Error: \(output)")
        }
    } catch {
        return (false, "Failed to run: \(error.localizedDescription)")
    }
}

func cleanSystemCaches() -> (success: Bool, message: String) {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    let cacheDir = "\(homeDir)/Library/Caches"
    
    // Clean old cache files (older than 30 days)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/find")
    process.arguments = [cacheDir, "-type", "f", "-mtime", "+30", "-delete"]
    
    do {
        try process.run()
        process.waitUntilExit()
        return (true, "System cache cleaned")
    } catch {
        return (false, "Failed to clean system cache: \(error.localizedDescription)")
    }
}

func performHomebrewCleanup() -> (success: Bool, message: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = ["brew"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            // Homebrew is installed, clean it
            let brewProcess = Process()
            brewProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
            if !FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
                brewProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/brew")
            }
            brewProcess.arguments = ["cleanup"]
            
            try brewProcess.run()
            brewProcess.waitUntilExit()
            return (true, "Homebrew cache cleaned")
        } else {
            return (false, "Homebrew not installed")
        }
    } catch {
        return (false, "Failed to clean Homebrew cache: \(error.localizedDescription)")
    }
}
#endif

