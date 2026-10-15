import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
            AppearanceTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            PrivacyTab()
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .frame(minWidth: 480, idealWidth: 560, minHeight: 480, idealHeight: 580)
        .padding(.top, 8)
    }
}

// MARK: - General Tab
private struct GeneralTab: View {
    @AppStorage(CueSettingsKey.launchAtLogin) private var launchAtLogin: Bool = false
    @AppStorage(CueSettingsKey.resultLimit)   private var wedgeCount: Int = 7

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        launchAtLogin = newValue
                        DispatchQueue.main.async {
                            CueSettings.applyLaunchAtLogin(newValue)
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                        Text("Cue will start automatically and be ready with ⌥Space.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Startup")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Wedge Count")
                        Spacer()
                        Text("\(wedgeCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(wedgeCount) },
                            set: { wedgeCount = Int($0) }
                        ),
                        in: 4...12,
                        step: 1
                    ) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("4").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("12").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                    }

                    Text("How many results to show in the radial fan at once.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Results")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Tab (with inline Theme Builder)
private struct AppearanceTab: View {
    @AppStorage(CueSettingsKey.themePreset)        private var themePresetRaw: String = ThemePreset.glass.rawValue
    @AppStorage(CueSettingsKey.bleedIntensity)     private var bleedIntensity: Double = 1.0
    @AppStorage(CueSettingsKey.dynamicThemeMode)   private var dynamicThemeModeRaw: String = DynamicThemeMode.timeOfDay.rawValue

    // Custom theme HSB values
    @AppStorage(CueSettingsKey.customTintHue)         private var tintHue: Double = 0.6
    @AppStorage(CueSettingsKey.customTintSaturation)  private var tintSat: Double = 0.4
    @AppStorage(CueSettingsKey.customTintBrightness)  private var tintBri: Double = 0.3
    @AppStorage(CueSettingsKey.customTintOpacity)     private var tintOpa: Double = 0.2
    @AppStorage(CueSettingsKey.customStrokeHue)       private var strokeHue: Double = 0.6
    @AppStorage(CueSettingsKey.customStrokeSaturation) private var strokeSat: Double = 0.8
    @AppStorage(CueSettingsKey.customStrokeBrightness) private var strokeBri: Double = 1.0
    @AppStorage(CueSettingsKey.customStrokeOpacity)   private var strokeOpa: Double = 1.0

    private var themePreset: Binding<ThemePreset> {
        Binding(
            get: { ThemePreset(rawValue: themePresetRaw) ?? .glass },
            set: { themePresetRaw = $0.rawValue }
        )
    }

    private var dynamicThemeMode: Binding<DynamicThemeMode> {
        Binding(
            get: { DynamicThemeMode(rawValue: dynamicThemeModeRaw) ?? .timeOfDay },
            set: { dynamicThemeModeRaw = $0.rawValue }
        )
    }

    private var isCustom: Bool { themePresetRaw == ThemePreset.custom.rawValue }
    private var isDynamic: Bool { themePresetRaw == ThemePreset.dynamic.rawValue }

    private var liveStrokeColor: Color {
        Color(hue: strokeHue, saturation: strokeSat, brightness: strokeBri, opacity: strokeOpa)
    }
    private var liveTintColor: Color {
        Color(hue: tintHue, saturation: tintSat, brightness: tintBri, opacity: tintOpa)
    }

    var body: some View {
        ScrollView {
            Form {
                Section {
                    // Theme grid — shows all presets as tappable swatches
                    ThemePresetGrid(
                        selectedRaw: $themePresetRaw,
                        onSelectCustomFrom: { preset in
                            // "Start from" workflow: initialize custom HSB from the tapped preset
                            let s = preset.strokeHSB
                            let t = preset.tintHSB
                            strokeHue = s.h; strokeSat = s.s; strokeBri = s.b; strokeOpa = s.o
                            tintHue = t.h; tintSat = t.s; tintBri = t.b; tintOpa = t.o
                            themePresetRaw = ThemePreset.custom.rawValue
                        }
                    )

                    // Dynamic theme sub-options
                    if isDynamic {
                        Picker("Mode", selection: dynamicThemeMode) {
                            ForEach(DynamicThemeMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Text(dynamicThemeModeRaw == DynamicThemeMode.timeOfDay.rawValue
                            ? "Theme shifts automatically based on time of day."
                            : "Theme adapts to your desktop wallpaper's dominant color.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Inline Custom Theme Builder
                    if isCustom {
                        VStack(spacing: 10) {
                            RadialWedgePreview(
                                tintColor: liveTintColor,
                                strokeColor: liveStrokeColor
                            )
                            .frame(height: 120)

                            // Stroke color
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Stroke")
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    ColorPicker("", selection: strokeColorBinding)
                                        .labelsHidden()
                                        .frame(width: 28, height: 28)
                                }
                                hsbSlider(label: "Hue", value: $strokeHue)
                                hsbSlider(label: "Sat", value: $strokeSat)
                                hsbSlider(label: "Bright", value: $strokeBri)
                                opacitySlider(value: $strokeOpa)
                            }

                            Divider()

                            // Tint color
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Tint Fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    ColorPicker("", selection: tintColorBinding)
                                        .labelsHidden()
                                        .frame(width: 28, height: 28)
                                }
                                hsbSlider(label: "Hue", value: $tintHue)
                                hsbSlider(label: "Sat", value: $tintSat)
                                hsbSlider(label: "Bright", value: $tintBri)
                                opacitySlider(value: $tintOpa)
                            }

                            Button(action: resetCustomDefaults) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset to Defaults")
                                }
                                .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25), value: isCustom)
                    }
                } header: {
                    Text("Theme")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Transparency")
                            Spacer()
                            Text("\(Int(bleedIntensity * 100))%")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $bleedIntensity, in: 0...1.0, step: 0.05)
                        Text("Controls how opaque the frosted glass surface is. Lower values let more of your desktop show through.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Surface")
                }
            }
            .formStyle(.grouped)
            .padding()
        }
    }

    // MARK: - ColorPicker Bindings (sync NSColor ↔ HSB sliders)

    private var strokeColorBinding: Binding<Color> {
        Binding(
            get: { Color(hue: strokeHue, saturation: strokeSat, brightness: strokeBri) },
            set: { newColor in
                if let hsb = newColor.toHSB() {
                    strokeHue = hsb.h; strokeSat = hsb.s; strokeBri = hsb.b
                }
            }
        )
    }

    private var tintColorBinding: Binding<Color> {
        Binding(
            get: { Color(hue: tintHue, saturation: tintSat, brightness: tintBri) },
            set: { newColor in
                if let hsb = newColor.toHSB() {
                    tintHue = hsb.h; tintSat = hsb.s; tintBri = hsb.b
                }
            }
        )
    }

    // MARK: - Sliders

    private func hsbSlider(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 38, alignment: .leading)
            Slider(value: value, in: 0...1.0, step: 0.01)
            Text("\(Int(value.wrappedValue * 100))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func opacitySlider(value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text("Alpha")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 38, alignment: .leading)
            Slider(value: value, in: 0...1.0, step: 0.01)
            Text("\(Int(value.wrappedValue * 100))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func resetCustomDefaults() {
        tintHue = 0.6; tintSat = 0.4; tintBri = 0.3; tintOpa = 0.2
        strokeHue = 0.6; strokeSat = 0.8; strokeBri = 1.0; strokeOpa = 1.0
    }
}

// MARK: - Theme Preset Grid

private struct ThemePresetGrid: View {
    @Binding var selectedRaw: String
    let onSelectCustomFrom: (ThemePreset) -> Void

    private let columns = [GridItem(.adaptive(minimum: 70), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ThemePreset.allCases) { preset in
                let isSelected = selectedRaw == preset.rawValue
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(preset.tintColor)
                            .frame(width: 48, height: 32)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(preset.strokeColor, lineWidth: isSelected ? 2.5 : 1.5)
                            .frame(width: 48, height: 32)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    Text(preset.rawValue)
                        .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRaw = preset.rawValue
                    }
                }
                .contextMenu {
                    if preset != .custom && preset != .dynamic {
                        Button("Use as Custom Starting Point") {
                            onSelectCustomFrom(preset)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Radial Wedge Preview (realistic mini fan)

private struct RadialWedgePreview: View {
    let tintColor: Color
    let strokeColor: Color

    private let previewItems: [(icon: String, name: String)] = [
        ("safari", "Safari"),
        ("gear", "Settings"),
        ("music.note", "Music"),
        ("envelope.fill", "Mail"),
        ("photo", "Photos")
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08))

            // Mini radial fan
            ZStack {
                ForEach(0..<previewItems.count, id: \.self) { i in
                    let total = Double(previewItems.count)
                    let step = 360.0 / total
                    let startOffset = -90.0 - (step * total / 2.0) + (step / 2.0)
                    let startDeg = startOffset + (step * Double(i)) + 1.5
                    let endDeg = startOffset + (step * Double(i + 1)) - 1.5
                    let start = Angle(degrees: startDeg)
                    let end = Angle(degrees: endDeg)
                    let midAngle = Angle(degrees: (startDeg + endDeg) / 2.0)
                    let midR: CGFloat = 34

                    ZStack {
                        AnnularSector(startAngle: start, endAngle: end, innerRadius: 18, outerRadius: 50)
                            .fill(tintColor)
                        AnnularSector(startAngle: start, endAngle: end, innerRadius: 18, outerRadius: 50)
                            .stroke(
                                LinearGradient(
                                    colors: [strokeColor, strokeColor.opacity(0.3), strokeColor.opacity(0.0)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )

                        VStack(spacing: 1) {
                            Image(systemName: previewItems[i].icon)
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.8))
                            Text(previewItems[i].name)
                                .font(.system(size: 5, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .offset(
                            x: midR * CGFloat(Darwin.cos(midAngle.radians)),
                            y: midR * CGFloat(Darwin.sin(midAngle.radians))
                        )
                    }
                }

                // Center hub
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .overlay(
                        Text("CUE")
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
    }
}

// MARK: - Color HSB Extraction

private extension Color {
    func toHSB() -> (h: Double, s: Double, b: Double)? {
        guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b))
    }
}

// MARK: - Privacy Tab (with app dropdown)
private struct PrivacyTab: View {
    @AppStorage(CueSettingsKey.exclusionList) private var exclusionListRaw: String = ""
    @State private var selectedApp: String = ""

    private var entries: [String] {
        exclusionListRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// All user-visible installed app names for the dropdown
    /// (AppRegistry already filters hidden system apps, so this list is clean)
    private var availableApps: [String] {
        AppRegistry.shared.installedApps
            .map { $0.name }
            .sorted()
            .filter { !entries.contains($0) }
    }

    var body: some View {
        Form {
            Section {
                Text("Apps listed here are hidden from Cue's search results.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Picker("Select app", selection: $selectedApp) {
                        Text("Choose an app…").tag("")
                        ForEach(availableApps, id: \.self) { appName in
                            Text(appName).tag(appName)
                        }
                    }
                    .labelsHidden()
                    
                    Button("Hide") {
                        addEntry(selectedApp)
                    }
                    .disabled(selectedApp.isEmpty)
                }

                if entries.isEmpty {
                    Text("No hidden apps.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(entries, id: \.self) { name in
                        HStack {
                            // Show app icon if available
                            if let app = AppRegistry.shared.installedApps.first(where: { $0.name == name }) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Text(name)
                            Spacer()
                            Button {
                                remove(name)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                Text("Hidden Apps")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addEntry(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !entries.contains(trimmed) else { return }
        let updated = (entries + [trimmed]).joined(separator: ",")
        exclusionListRaw = updated
        selectedApp = ""
    }

    private func remove(_ name: String) {
        let updated = entries.filter { $0 != name }.joined(separator: ",")
        exclusionListRaw = updated
    }
}

#Preview {
    SettingsView()
}
