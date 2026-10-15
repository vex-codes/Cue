import Foundation
import AppKit
import SwiftUI

/// Provides searchable access to macOS System Settings panes.
/// Results are returned as `SystemCommand` entries so they integrate
/// seamlessly with the existing search pipeline — no new result types needed.
class SystemSettingsProvider {
    static let shared = SystemSettingsProvider()

    let panes: [SystemCommand]

    private init() {
        panes = Self.buildPanes()
    }

    /// Search settings panes by name and keywords.
    func search(query: String) -> [SystemCommand] {
        let q = query.lowercased()
        guard q.count >= 2 else { return [] } // Avoid noise on single-letter queries

        return panes.filter { pane in
            let name = pane.name.lowercased()
            let ident = pane.identifier.lowercased()
            return name.hasPrefix(q) || name.contains(q) || ident.contains(q)
        }.sorted { p1, p2 in
            let n1 = p1.name.lowercased()
            let n2 = p2.name.lowercased()
            let prefix1 = n1.hasPrefix(q)
            let prefix2 = n2.hasPrefix(q)
            if prefix1 && !prefix2 { return true }
            if !prefix1 && prefix2 { return false }
            return n1 < n2
        }
    }

    // MARK: - Open Settings Pane

    /// Opens a System Settings pane via URL scheme (macOS 13+) or falls back to
    /// opening System Preferences by bundle ID for the pane.
    private static func openSettingsPane(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - SF Symbol Helper

    private static func sfSymbol(_ name: String) -> NSImage {
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .medium)
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.size = NSSize(width: 128, height: 128)
            return configured
        }
        let fallback = NSImage(systemSymbolName: "gear", accessibilityDescription: nil) ?? NSImage()
        fallback.size = NSSize(width: 128, height: 128)
        return fallback
    }

    // MARK: - Pane Definitions

    /// All macOS System Settings panes with search keywords embedded in the identifier
    /// for broad matching (e.g. searching "wifi" finds "Wi-Fi", "dark" finds "Appearance").
    private static func buildPanes() -> [SystemCommand] {
        let grayColor = Color(hue: 0.0, saturation: 0.0, brightness: 0.5)
        let blueColor = Color(hue: 0.6, saturation: 0.6, brightness: 0.8)
        let greenColor = Color(hue: 0.35, saturation: 0.5, brightness: 0.7)
        let orangeColor = Color(hue: 0.08, saturation: 0.6, brightness: 0.8)
        let purpleColor = Color(hue: 0.75, saturation: 0.5, brightness: 0.7)
        let redColor = Color(hue: 0.0, saturation: 0.5, brightness: 0.7)

        return [
            // ── Network ──────────────────────────────────────────
            SystemCommand(
                identifier: "settings.wifi.wireless.internet",
                name: "Wi-Fi",
                icon: sfSymbol("wifi"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.wifi-settings-extension") }
            ),
            SystemCommand(
                identifier: "settings.bluetooth.devices.wireless",
                name: "Bluetooth",
                icon: sfSymbol("dot.radiowaves.left.and.right"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.BluetoothSettings") }
            ),
            SystemCommand(
                identifier: "settings.network.ethernet.vpn.dns.proxy",
                name: "Network",
                icon: sfSymbol("globe"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Network-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.energy.battery.power.charger",
                name: "Energy",
                icon: sfSymbol("bolt.fill"),
                averageColor: greenColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Battery-Settings.extension") }
            ),

            // ── System ───────────────────────────────────────────
            SystemCommand(
                identifier: "settings.general.about.software.update.storage.login.items",
                name: "General",
                icon: sfSymbol("gearshape"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.General-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.accessibility.voiceover.zoom.display.motor",
                name: "Accessibility",
                icon: sfSymbol("accessibility"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Accessibility-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.appearance.dark.mode.light.accent.color.theme",
                name: "Appearance",
                icon: sfSymbol("paintbrush"),
                averageColor: purpleColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Appearance-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.siri.apple.intelligence.ai.assistant.voice",
                name: "Apple Intelligence & Siri",
                icon: sfSymbol("sparkles"),
                averageColor: purpleColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Siri-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.desktop.dock.stage.manager.hot.corners.mission.control",
                name: "Desktop & Dock",
                icon: sfSymbol("dock.rectangle"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Desktop-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.displays.monitor.resolution.brightness.night.shift.screen",
                name: "Displays",
                icon: sfSymbol("display"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Displays-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.menu.bar.control.center.clock.battery",
                name: "Menu Bar",
                icon: sfSymbol("menubar.rectangle"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.spotlight.search.indexing",
                name: "Spotlight",
                icon: sfSymbol("magnifyingglass"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Spotlight-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.wallpaper.background.desktop.picture",
                name: "Wallpaper",
                icon: sfSymbol("photo"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Wallpaper-Settings.extension") }
            ),

            // ── Notifications & Focus ────────────────────────────
            SystemCommand(
                identifier: "settings.notifications.alerts.banners.badges",
                name: "Notifications",
                icon: sfSymbol("bell.badge.fill"),
                averageColor: redColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Notifications-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.sound.volume.audio.output.input.speaker.microphone",
                name: "Sound",
                icon: sfSymbol("speaker.wave.3.fill"),
                averageColor: redColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Sound-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.focus.do.not.disturb.dnd.concentration",
                name: "Focus",
                icon: sfSymbol("moon.fill"),
                averageColor: purpleColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Focus-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.screen.time.usage.limits.downtime.app",
                name: "Screen Time",
                icon: sfSymbol("hourglass"),
                averageColor: purpleColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Screen-Time-Settings.extension") }
            ),

            // ── Security & Users ─────────────────────────────────
            SystemCommand(
                identifier: "settings.lock.screen.screensaver.password.require",
                name: "Lock Screen",
                icon: sfSymbol("lock.display"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.privacy.security.permissions.firewall.filevault.encryption",
                name: "Privacy & Security",
                icon: sfSymbol("hand.raised.fill"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension") }
            ),
            SystemCommand(
                identifier: "settings.touch.id.password.fingerprint.biometric.login",
                name: "Touch ID & Password",
                icon: sfSymbol("touchid"),
                averageColor: redColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Touch-ID-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.users.groups.accounts.admin.guest",
                name: "Users & Groups",
                icon: sfSymbol("person.2.fill"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Users-Groups-Settings.extension") }
            ),

            // ── Accounts & Services ──────────────────────────────
            SystemCommand(
                identifier: "settings.internet.accounts.email.calendar.contacts.exchange.google",
                name: "Internet Accounts",
                icon: sfSymbol("at"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.game.center.gaming.achievements.friends",
                name: "Game Center",
                icon: sfSymbol("gamecontroller.fill"),
                averageColor: orangeColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Game-Center-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.icloud.apple.id.sync.backup.drive.photos",
                name: "iCloud",
                icon: sfSymbol("icloud.fill"),
                averageColor: blueColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.iCloud-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.wallet.apple.pay.payment.card.contactless",
                name: "Wallet & Apple Pay",
                icon: sfSymbol("creditcard.fill"),
                averageColor: orangeColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.WalletSettingsExtension") }
            ),

            // ── Input & Peripherals ──────────────────────────────
            SystemCommand(
                identifier: "settings.keyboard.typing.shortcuts.input.sources.text.replacement.dictation",
                name: "Keyboard",
                icon: sfSymbol("keyboard"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Keyboard-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.mouse.tracking.scrolling.clicking.cursor.pointer",
                name: "Mouse",
                icon: sfSymbol("computermouse.fill"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Mouse-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.trackpad.gestures.scroll.tap.click.force",
                name: "Trackpad",
                icon: sfSymbol("rectangle.and.hand.point.up.left.filled"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Trackpad-Settings.extension") }
            ),
            SystemCommand(
                identifier: "settings.printers.scanners.printing.scanner",
                name: "Printers & Scanners",
                icon: sfSymbol("printer.fill"),
                averageColor: grayColor,
                action: { openSettingsPane("x-apple.systempreferences:com.apple.Print-Scan-Settings.extension") }
            ),
        ]
    }
}
