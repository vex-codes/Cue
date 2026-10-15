import Foundation
import AppKit

class AppRegistry {
    static let shared = AppRegistry()

    private(set) var installedApps: [AppResult] = []
    private let fileManager = FileManager.default
    private let workspace = NSWorkspace.shared

    // Directories that contain user-visible apps
    private let userVisibleDirectories: Set<String> = [
        "/Applications",
        "/System/Applications",
        "/Applications/Utilities",
        "/System/Applications/Utilities"
    ]

    // Path prefixes that indicate hidden/internal system apps
    private let hiddenPathPrefixes: [String] = [
        "/System/Library/CoreServices/",
        "/System/Library/PrivateFrameworks/",
        "/System/Library/Frameworks/",
        "/System/Library/PreferencePanes/",
        "/System/Library/Services/",
        "/System/Library/Input Methods/",
        "/System/Library/ExtensionKit/",
        "/System/Library/Assistant/",
        "/usr/",
        "/Library/Apple/",
        "/Library/Application Support/",
        "/System/Library/Automator/",
        "/System/Volumes/"
    ]

    // Well-known user-visible apps that live in CoreServices (whitelist)
    private let coreServicesWhitelist: Set<String> = [
        "Finder", "Spotlight", "Screen Sharing"
    ]

    // Fallback directories if Spotlight is unavailable
    private var searchDirectories: [URL] {
        var dirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications/Utilities")
        ]
        if let userApps = fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first {
            dirs.append(userApps)
        }
        return dirs
    }

    private init() {
        refreshApps()
    }

    func refreshApps() {
        // Try Spotlight first — it knows about every .app on the system
        var appURLs = discoverViaSpotlight()

        // Fallback to directory enumeration if Spotlight returned nothing
        if appURLs.isEmpty {
            appURLs = discoverViaDirectories()
        }

        // Filter out nested apps, hidden system agents, and background-only apps
        appURLs = filterNestedApps(appURLs)
        appURLs = filterHiddenSystemApps(appURLs)

        var newApps: [AppResult] = []
        var seenURLs = Set<URL>()

        for fileURL in appURLs {
            let standardized = fileURL.standardizedFileURL
            guard !seenURLs.contains(standardized) else { continue }
            seenURLs.insert(standardized)

            guard fileManager.fileExists(atPath: standardized.path) else { continue }

            let name = standardized.deletingPathExtension().lastPathComponent
            let lowercasedName = name.lowercased()
            let acronym = name.split(separator: " ").compactMap { $0.first?.lowercased() }.joined()
            let icon = workspace.icon(forFile: standardized.path)
            icon.size = NSSize(width: 128, height: 128)

            let averageColor = icon.getAverageColor()
            let appResult = AppResult(id: standardized, name: name, lowercasedName: lowercasedName, acronym: acronym, icon: icon, url: standardized, averageColor: averageColor)
            newApps.append(appResult)
        }

        self.installedApps = newApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // MARK: - Spotlight Discovery
    
    /// Uses `mdfind` to query Spotlight for every application bundle on the system.
    /// This is the same mechanism Launchpad and Spotlight use to find apps.
    private func discoverViaSpotlight() -> [URL] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemContentType == 'com.apple.application-bundle'"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        
        return output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { URL(fileURLWithPath: $0) }
    }
    
    // MARK: - Directory Enumeration Fallback
    
    private func discoverViaDirectories() -> [URL] {
        var urls: [URL] = []
        
        for directoryURL in searchDirectories {
            guard let enumerator = fileManager.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "app" {
                    urls.append(fileURL)
                }
            }
        }
        
        return urls
    }
    
    // MARK: - Nested App Filtering

    private func filterNestedApps(_ urls: [URL]) -> [URL] {
        return urls.filter { url in
            let pathComponents = url.pathComponents
            var appCount = 0
            for component in pathComponents {
                if component.hasSuffix(".app") {
                    appCount += 1
                    if appCount > 1 { return false }
                }
            }
            return true
        }
    }

    // MARK: - Hidden System App Filtering

    /// Filters out internal system helpers, background agents, and UI-less apps
    /// that should never appear in a user-facing launcher.
    private func filterHiddenSystemApps(_ urls: [URL]) -> [URL] {
        return urls.filter { url in
            let path = url.path
            let name = url.deletingPathExtension().lastPathComponent

            // Always allow whitelisted CoreServices apps (e.g. Finder)
            if coreServicesWhitelist.contains(name) { return true }

            // Allow apps in standard user-visible directories
            let isInVisibleDir = userVisibleDirectories.contains(where: { dir in
                // Must be a direct child of one of these directories
                let parent = url.deletingLastPathComponent().path
                return parent == dir
            })

            // Allow ~/Applications
            if let userApps = fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first {
                if url.deletingLastPathComponent().path == userApps.path {
                    return !isBackgroundOnlyApp(at: url)
                }
            }

            if isInVisibleDir {
                // Even in visible dirs, skip background-only agents
                return !isBackgroundOnlyApp(at: url)
            }

            // Block apps from known hidden system paths
            for prefix in hiddenPathPrefixes {
                if path.hasPrefix(prefix) { return false }
            }

            // For any other location, check if it's a background agent
            return !isBackgroundOnlyApp(at: url)
        }
    }

    /// Checks an app's Info.plist to determine if it's a background-only agent
    /// (LSBackgroundOnly or LSUIElement) that shouldn't appear in a launcher.
    private func isBackgroundOnlyApp(at url: URL) -> Bool {
        let plistURL = url.appendingPathComponent("Contents/Info.plist")

        guard let plistData = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            // No readable Info.plist — likely an internal system stub
            return true
        }

        // LSBackgroundOnly apps are invisible background daemons
        if let bgOnly = plist["LSBackgroundOnly"] as? Bool, bgOnly {
            return true
        }

        // LSUIElement apps run as agents (no dock icon, no menu bar)
        // These are typically helper apps not meant to be launched directly
        if let uiElement = plist["LSUIElement"] as? Bool, uiElement {
            return true
        }
        // Also check string variant ("1")
        if let uiElement = plist["LSUIElement"] as? String, uiElement == "1" || uiElement == "YES" {
            return true
        }

        return false
    }
}
