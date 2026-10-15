import Foundation
import AppKit
import SwiftUI
import IOKit.pwr_mgt

class SystemCommandProvider {
    static let shared = SystemCommandProvider()

    let commands: [SystemCommand]

    private init() {
        commands = [
            SystemCommand(
                identifier: "sleep",
                name: "Sleep",
                icon: Self.sfSymbol("moon.zzz.fill"),
                averageColor: Color(hue: 0.7, saturation: 0.6, brightness: 0.8),
                action: {
                    // IOKit is the most reliable — no admin prompt, works without privileges
                    SystemCommandProvider.sleepWithIOKit()
                }
            ),
            SystemCommand(
                identifier: "emptytrash",
                name: "Empty Trash",
                icon: Self.sfSymbol("trash.fill"),
                averageColor: Color(hue: 0.0, saturation: 0.7, brightness: 0.8),
                action: {
                    // macOS will auto-prompt for Automation permission on first use
                    SystemCommandProvider.runAppleScript("""
                        tell application "Finder" to empty trash
                    """)
                }
            ),
            SystemCommand(
                identifier: "toggledarkmode",
                name: "Toggle Dark Mode",
                icon: Self.sfSymbol("circle.lefthalf.filled"),
                averageColor: Color(hue: 0.6, saturation: 0.5, brightness: 0.7),
                action: {
                    SystemCommandProvider.runAppleScript("""
                        tell application "System Events"
                            tell appearance preferences
                                set dark mode to not dark mode
                            end tell
                        end tell
                    """)
                }
            ),
            SystemCommand(
                identifier: "lockscreen",
                name: "Lock Screen",
                icon: Self.sfSymbol("lock.fill"),
                averageColor: Color(hue: 0.55, saturation: 0.6, brightness: 0.7),
                action: {
                    SystemCommandProvider.runAppleScript("""
                        tell application "System Events" to keystroke "q" using {command down, control down}
                    """)
                }
            ),
            SystemCommand(
                identifier: "restart",
                name: "Restart",
                icon: Self.sfSymbol("arrow.triangle.2.circlepath"),
                averageColor: Color(hue: 0.08, saturation: 0.7, brightness: 0.9),
                action: {
                    SystemCommandProvider.runAppleScript("""
                        tell application "System Events" to restart
                    """)
                }
            ),
            SystemCommand(
                identifier: "shutdown",
                name: "Shut Down",
                icon: Self.sfSymbol("power"),
                averageColor: Color(hue: 0.0, saturation: 0.6, brightness: 0.7),
                action: {
                    SystemCommandProvider.runAppleScript("""
                        tell application "System Events" to shut down
                    """)
                }
            ),
            SystemCommand(
                identifier: "logout",
                name: "Log Out",
                icon: Self.sfSymbol("rectangle.portrait.and.arrow.right"),
                averageColor: Color(hue: 0.45, saturation: 0.5, brightness: 0.7),
                action: {
                    SystemCommandProvider.runAppleScript("""
                        tell application "System Events" to log out
                    """)
                }
            )
        ]
    }

    func search(query: String) -> [SystemCommand] {
        let q = query.lowercased()
        return commands.filter { cmd in
            let name = cmd.name.lowercased()
            let ident = cmd.identifier.lowercased()
            return name.hasPrefix(q) || name.contains(q) || ident.hasPrefix(q)
        }.sorted { cmd1, cmd2 in
            let p1 = cmd1.name.lowercased().hasPrefix(q)
            let p2 = cmd2.name.lowercased().hasPrefix(q)
            if p1 && !p2 { return true }
            if !p1 && p2 { return false }
            return cmd1.name < cmd2.name
        }
    }

    // MARK: - AppleScript Runner

    /// Runs an AppleScript string. macOS will auto-prompt for Automation permissions
    /// (e.g. "Cue wants to control Finder") the first time each target app is used.
    private static func runAppleScript(_ source: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            print("[SystemCommand] AppleScript failed: \(error.localizedDescription)")
        }
    }

    // MARK: - IOKit Sleep

    private static func sleepWithIOKit() {
        let port = IOPMFindPowerManagement(0)
        if port != 0 {
            IOPMSleepSystem(port)
            IOServiceClose(port)
        }
    }

    // MARK: - Helper

    private static func sfSymbol(_ name: String) -> NSImage {
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .medium)
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.size = NSSize(width: 128, height: 128)
            return configured
        }
        let fallback = NSImage()
        fallback.size = NSSize(width: 128, height: 128)
        return fallback
    }
}
