# Cue: Project Analysis & Documentation

## 1. Project Overview
**Cue** is a premium, highly visual productivity launcher for macOS. It serves as a modern, radial alternative to traditional list-based launchers (like Alfred, Raycast, or Spotlight). Designed with a focus on aesthetics and fluid interaction, Cue provides instant access to apps, system settings, calculations, and files through a unique "Radial Fan" interface.

---

## 2. Core Architecture
The app is built using **Swift and SwiftUI**, leveraging native macOS frameworks for deep system integration.

### Entry Point & Lifecycle (`CueApp.swift`)
- Runs as an **Accessory App** (`.accessory` policy), meaning it stays out of the Dock and behaves like a system utility.
- Managed via a standard `AppDelegate` which sets up the menu bar icon and handles the initial window configuration.

### Window Management (`WindowManager.swift`)
- Uses a custom `NSPanel` subclass called `CuePanel`.
- **Overlay Behavior**: The window is borderless, transparent, and set to the `.popUpMenu` level, allowing it to float over full-screen applications and games.
- **Activation Area**: The window is centered on the user's mouse cursor whenever it is triggered.
- **Dismissal**: Automatically collapses and hides when the user clicks away or presses `Escape`.

### Activation Trigger (`TriggerManager.swift`)
- Uses the low-level **Carbon framework** to register a global system-wide hotkey.
- **Default Shortcut**: `Option (⌥) + Space`.

---

## 3. The Search Engine (`AppSearchEngine.swift`)
The "brain" of Cue that processes every keystroke and coordinates multiple data providers.

### Search Categories
1. **Apps**: Scans the system for installed applications. It uses an acronym-matching algorithm (e.g., typing "fcp" for Final Cut Pro) and a scoring system.
2. **System Commands**: Quick actions like *Sleep*, *Empty Trash*, *Toggle Dark Mode*, *Restart*, and *Shut Down*.
3. **System Settings**: Direct deep-links to 20+ specific macOS settings panes (e.g., *Wi-Fi*, *Bluetooth*, *Displays*).
4. **Calculator**: Real-time math expression evaluation.
5. **Currency Conversion**: Conversions between major global currencies (e.g., "100 usd to eur").
6. **File Search**: Spotlight-integrated search restricted to *Desktop*, *Documents*, and *Downloads*.

### Intelligent Features
- **Habit Learning**: Remembers which results you select for specific queries and prioritizes them in future searches.
- **Result Cycling**: If multiple apps share the same initial (e.g., "S" for Safari and Slack), tapping the key multiple times cycles through them.
- **Adaptive UI**: The number of results displayed (the "Wedge Count") is user-configurable from 4 to 12.

---

## 4. Visual Identity & UI (`RadialFanView.swift`)
The defining feature of Cue is its **Radial Fan UI**.

### Interface Elements
- **Central Hub**: Displays the current search query or the active result (like a calculator answer).
- **Wedge Iteration**: Results appear as "wedges" (annular sectors) arranged in a circle around the hub.
- **Backdrop Blur**: Uses native macOS "Frosted Glass" (`NSVisualEffectView`) for a premium throughput of desktop colors.
- **Animations**: Uses spring-based physics for all transitions, making the fan feel "organic" and responsive.

### User Experience (UX)
- **Haptic Ticks**: Provides tactile feedback via the MacBook trackpad when moving the cursor between wedges.
- **QuickLook Previews**: Hovering over a file result generates a high-resolution thumbnail preview in the center hub using the `QuickLookThumbnailing` framework.
- **Dynamic Typography**: Font weights and sizes adjust automatically based on the length of your query to maintain legibility.

---

## 5. Themes & Personalization (`CueSettings.swift`)
Cue features one of the most advanced theme engines for a macOS utility.

### Theme Presets
- Includes 8+ curated palettes: **Glass, Midnight, Neon, Catppuccin, Dracula, Nord, Rosé Pine,** and **Tokyo Night**.

### Dynamic Themes
1. **Time of Day**: Shifts the interface hues throughout the day (Morning Amber, Afternoon Blue, Evening Violet).
2. **Wallpaper Match**: Samples the current desktop wallpaper's dominant color to create a perfectly harmonious UI tint and accent.

### Custom Theme Builder
Users can create their own themes by fine-tuning HSB (Hue, Saturation, Brightness) values for both the **Tint Fill** and the **Accent Stroke**, with a live preview in the settings panel.

---

## 6. Settings & Privacy (`SettingsView.swift`)
A comprehensive settings panel accessible from the menu bar.

- **General**: Toggle launch at login and adjust the "Wedge Count" (4-12) to control information density.
- **Appearance**: Select theme presets, toggle dynamic modes, and control the "Backdrop Bleed" (transparency intensity).
- **Privacy**: A "Hidden Apps" manager allows users to exclude specific apps from appearing in search results.

---

## 7. Technical Implementation Details
- **Math Engine**: Uses `JavaScriptCore` for safe and flexible expression evaluation.
- **System Actions**: Implemented via a mix of `AppleScript` (for UI-level actions) and `IOKit` (for power management).
- **Search Logic**: Uses `NSMetadataQuery` for high-performance Spotlight-indexed file searching.
- **Data Persistence**: Uses `@AppStorage` and `UserDefaults` for lightweight, reactive settings management.
