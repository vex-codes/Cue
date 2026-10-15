import SwiftUI
import ServiceManagement

// MARK: - Setting Keys (single source of truth)
enum CueSettingsKey {
    static let bleedIntensity     = "cue.bleedIntensity"
    static let blurMaterial       = "cue.blurMaterial"
    static let adaptiveSaturation = "cue.adaptiveSaturation"
    static let themePreset        = "cue.themePreset"
    static let resultLimit        = "cue.resultLimit"
    static let exclusionList      = "cue.exclusionList"
    static let launchAtLogin      = "cue.launchAtLogin"
    
    // Dynamic Theme
    static let dynamicThemeMode   = "cue.dynamicThemeMode"
    
    // Custom Theme Builder
    static let customTintHue         = "cue.customTintHue"
    static let customTintSaturation  = "cue.customTintSaturation"
    static let customTintBrightness  = "cue.customTintBrightness"
    static let customTintOpacity     = "cue.customTintOpacity"
    static let customStrokeHue       = "cue.customStrokeHue"
    static let customStrokeSaturation = "cue.customStrokeSaturation"
    static let customStrokeBrightness = "cue.customStrokeBrightness"
    static let customStrokeOpacity   = "cue.customStrokeOpacity"
}

// MARK: - Enums

enum BlurMaterial: String, CaseIterable, Identifiable {
    case frosted  = "Frosted"
    case dark     = "Dark"
    case vibrant  = "Vibrant"
    var id: String { rawValue }

    var nsValue: NSVisualEffectView.Material {
        switch self {
        case .frosted: return .hudWindow
        case .dark:    return .underWindowBackground
        case .vibrant: return .selection
        }
    }

    var subtitle: String {
        switch self {
        case .frosted: return "Soft frosted glass effect"
        case .dark:    return "Deep dark translucency"
        case .vibrant: return "Picks up colors from behind"
        }
    }
}

enum DynamicThemeMode: String, CaseIterable, Identifiable {
    case timeOfDay = "Time of Day"
    case wallpaper = "Wallpaper"
    var id: String { rawValue }
}

enum ThemePreset: String, CaseIterable, Identifiable {
    case glass      = "Glass"
    case midnight   = "Midnight"
    case neon       = "Neon"
    case catppuccin = "Catppuccin"
    case dracula    = "Dracula"
    case nord       = "Nord"
    case rosePine   = "Rosé Pine"
    case tokyoNight = "Tokyo Night"
    case dynamic    = "Dynamic"
    case custom     = "Custom"
    var id: String { rawValue }

    // Stroke: full-luminosity accent from each palette's canonical spec
    var strokeColor: Color {
        switch self {
        case .glass:      return .white
        case .midnight:   return Color.white.opacity(0.35)
        case .neon:       return Color(red: 0.00, green: 0.80, blue: 1.00)   // #00CCFF electric cyan
        case .catppuccin: return Color(red: 0.796, green: 0.651, blue: 0.969) // #CBA6F7 Mocha Mauve
        case .dracula:    return Color(red: 0.741, green: 0.576, blue: 0.976) // #BD93F9 Purple
        case .nord:       return Color(red: 0.533, green: 0.753, blue: 0.816) // #88C0D0 Frost
        case .rosePine:   return Color(red: 0.922, green: 0.737, blue: 0.729) // #EBBCBA Rose
        case .tokyoNight: return Color(red: 0.478, green: 0.635, blue: 0.969) // #7AA2F7 Blue
        case .dynamic:    return DynamicThemeEngine.shared.strokeColor
        case .custom:     return CustomThemeEngine.strokeColor
        }
    }

    // Tint: palette base at controlled opacity — low enough for frosted glass to bleed through
    var tintColor: Color {
        switch self {
        case .glass:      return Color.white.opacity(0.05)
        case .midnight:   return Color.black.opacity(0.40)
        case .neon:       return Color(red: 0.00, green: 0.20, blue: 0.30).opacity(0.35)
        case .catppuccin: return Color(red: 0.118, green: 0.118, blue: 0.180).opacity(0.50) // #1E1E2E
        case .dracula:    return Color(red: 0.157, green: 0.165, blue: 0.212).opacity(0.50) // #282A36
        case .nord:       return Color(red: 0.180, green: 0.204, blue: 0.251).opacity(0.45) // #2E3440
        case .rosePine:   return Color(red: 0.098, green: 0.090, blue: 0.141).opacity(0.50) // #191724
        case .tokyoNight: return Color(red: 0.102, green: 0.106, blue: 0.149).opacity(0.50) // #1A1B26
        case .dynamic:    return DynamicThemeEngine.shared.tintColor
        case .custom:     return CustomThemeEngine.tintColor
        }
    }

    /// HSB values for initializing the custom theme builder from this preset
    var strokeHSB: (h: Double, s: Double, b: Double, o: Double) {
        switch self {
        case .glass:      return (0.0, 0.0, 1.0, 1.0)
        case .midnight:   return (0.0, 0.0, 1.0, 0.3)
        case .neon:       return (0.55, 1.0, 1.0, 1.0)
        case .catppuccin: return (0.76, 0.30, 0.96, 1.0)
        case .dracula:    return (0.71, 0.41, 0.98, 1.0)
        case .nord:       return (0.53, 0.35, 0.82, 1.0)
        case .rosePine:   return (0.94, 0.20, 0.92, 1.0)
        case .tokyoNight: return (0.65, 0.49, 0.94, 1.0)
        case .dynamic:    return (0.6, 0.8, 1.0, 1.0)
        case .custom:     return (0.6, 0.8, 1.0, 1.0)
        }
    }

    var tintHSB: (h: Double, s: Double, b: Double, o: Double) {
        switch self {
        case .glass:      return (0.0, 0.0, 1.0, 0.04)
        case .midnight:   return (0.0, 0.0, 0.0, 0.35)
        case .neon:       return (0.55, 0.7, 0.2, 0.25)
        case .catppuccin: return (0.72, 0.35, 0.18, 0.6)
        case .dracula:    return (0.72, 0.24, 0.21, 0.6)
        case .nord:       return (0.60, 0.28, 0.25, 0.55)
        case .rosePine:   return (0.76, 0.32, 0.19, 0.6)
        case .tokyoNight: return (0.66, 0.42, 0.19, 0.6)
        case .dynamic:    return (0.6, 0.4, 0.3, 0.2)
        case .custom:     return (0.6, 0.4, 0.3, 0.2)
        }
    }
}

// MARK: - CueSettings (static read-only accessor used by the engine at runtime)
// SettingsView uses @AppStorage directly for live two-way bindings.
enum CueSettings {
    static var resultLimit: Int {
        let val = UserDefaults.standard.integer(forKey: CueSettingsKey.resultLimit)
        return val >= 4 && val <= 12 ? val : 7
    }

    static var exclusionList: [String] {
        let raw = UserDefaults.standard.string(forKey: CueSettingsKey.exclusionList) ?? ""
        return raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // Launch at Login helper
    static func applyLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable { try SMAppService.mainApp.register() }
                else       { try SMAppService.mainApp.unregister() }
            } catch {
                print("[CueSettings] LaunchAtLogin error: \(error)")
            }
        }
    }
}

// MARK: - Dynamic Theme Engine
class DynamicThemeEngine {
    static let shared = DynamicThemeEngine()
    
    private var cachedWallpaperStroke: Color?
    private var cachedWallpaperTint: Color?
    private var lastWallpaperCompute: Date?
    
    var strokeColor: Color {
        let mode = DynamicThemeMode(rawValue:
            UserDefaults.standard.string(forKey: CueSettingsKey.dynamicThemeMode) ?? DynamicThemeMode.timeOfDay.rawValue
        ) ?? .timeOfDay
        
        switch mode {
        case .timeOfDay: return timeOfDayStroke
        case .wallpaper: return wallpaperStroke
        }
    }
    
    var tintColor: Color {
        let mode = DynamicThemeMode(rawValue:
            UserDefaults.standard.string(forKey: CueSettingsKey.dynamicThemeMode) ?? DynamicThemeMode.timeOfDay.rawValue
        ) ?? .timeOfDay
        
        switch mode {
        case .timeOfDay: return timeOfDayTint
        case .wallpaper: return wallpaperTint
        }
    }
    
    // MARK: Time of Day
    
    private var timeOfDayStroke: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return Color(hue: 0.08, saturation: 0.8, brightness: 1.0)   // Morning amber
        case 12..<18: return Color(hue: 0.58, saturation: 0.7, brightness: 1.0)   // Afternoon blue
        case 18..<22: return Color(hue: 0.78, saturation: 0.7, brightness: 0.9)   // Evening violet
        default:      return Color.white.opacity(0.4)                               // Night silver
        }
    }
    
    private var timeOfDayTint: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return Color(hue: 0.08, saturation: 0.4, brightness: 0.3).opacity(0.2)
        case 12..<18: return Color(hue: 0.58, saturation: 0.3, brightness: 0.3).opacity(0.2)
        case 18..<22: return Color(hue: 0.78, saturation: 0.5, brightness: 0.2).opacity(0.25)
        default:      return Color.black.opacity(0.4)
        }
    }
    
    // MARK: Wallpaper
    
    private var wallpaperStroke: Color {
        refreshWallpaperCacheIfNeeded()
        return cachedWallpaperStroke ?? .white
    }
    
    private var wallpaperTint: Color {
        refreshWallpaperCacheIfNeeded()
        return cachedWallpaperTint ?? Color.white.opacity(0.04)
    }
    
    private func refreshWallpaperCacheIfNeeded() {
        // Cache wallpaper colors for 60 seconds
        if let lastCompute = lastWallpaperCompute, Date().timeIntervalSince(lastCompute) < 60 {
            return
        }
        computeWallpaperColors()
    }
    
    private func computeWallpaperColors() {
        lastWallpaperCompute = Date()
        
        guard let screen = NSScreen.main,
              let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen),
              let image = NSImage(contentsOf: wallpaperURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            cachedWallpaperStroke = .white
            cachedWallpaperTint = Color.white.opacity(0.04)
            return
        }
        
        // Scale to 1x1 pixel for average color
        var pixelData: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: &pixelData, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: colorSpace, bitmapInfo: bitmapInfo
        ) else {
            cachedWallpaperStroke = .white
            cachedWallpaperTint = Color.white.opacity(0.04)
            return
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let r = Double(pixelData[0]) / 255.0
        let g = Double(pixelData[1]) / 255.0
        let b = Double(pixelData[2]) / 255.0
        
        // Stroke: a lighter, more vibrant version
        cachedWallpaperStroke = Color(
            red: min(r + 0.3, 1.0),
            green: min(g + 0.3, 1.0),
            blue: min(b + 0.3, 1.0)
        )
        // Tint: the color at low opacity
        cachedWallpaperTint = Color(red: r, green: g, blue: b).opacity(0.2)
    }
}

// MARK: - Custom Theme Engine
enum CustomThemeEngine {
    static var strokeColor: Color {
        let h = UserDefaults.standard.object(forKey: CueSettingsKey.customStrokeHue) as? Double ?? 0.6
        let s = UserDefaults.standard.object(forKey: CueSettingsKey.customStrokeSaturation) as? Double ?? 0.8
        let b = UserDefaults.standard.object(forKey: CueSettingsKey.customStrokeBrightness) as? Double ?? 1.0
        let o = UserDefaults.standard.object(forKey: CueSettingsKey.customStrokeOpacity) as? Double ?? 1.0
        return Color(hue: h, saturation: s, brightness: b, opacity: o)
    }
    
    static var tintColor: Color {
        let h = UserDefaults.standard.object(forKey: CueSettingsKey.customTintHue) as? Double ?? 0.6
        let s = UserDefaults.standard.object(forKey: CueSettingsKey.customTintSaturation) as? Double ?? 0.4
        let b = UserDefaults.standard.object(forKey: CueSettingsKey.customTintBrightness) as? Double ?? 0.3
        let o = UserDefaults.standard.object(forKey: CueSettingsKey.customTintOpacity) as? Double ?? 0.2
        return Color(hue: h, saturation: s, brightness: b, opacity: o)
    }
}
