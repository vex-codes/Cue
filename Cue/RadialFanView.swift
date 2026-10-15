import SwiftUI
import AppKit
import QuickLookThumbnailing

// MARK: - Annular Sector Shape
struct AnnularSector: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.radians, endAngle.radians) }
        set {
            startAngle = Angle(radians: newValue.first)
            endAngle = Angle(radians: newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * CGFloat(Darwin.cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(Darwin.sin(endAngle.radians))
        ))
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Native Backdrop Blur (Hardcoded: Frosted Glass + Vibrant + Always Active)
struct BackdropBlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow       // Frosted glass — immutable
        view.isEmphasized = true          // Vibrant color sampling — immutable
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Immutable defaults — no user-configurable material
    }
}

// MARK: - Radial Fan View
struct RadialFanView: View {
    @EnvironmentObject var engine: AppSearchEngine
    @EnvironmentObject var windowManager: WindowManager
    
    // Layout Constants
    private let innerRadius: CGFloat = 85
    private let outerRadius: CGFloat = 230
    private let spacing: Double = 3.0
    
    @State private var hoverLocation: CGPoint? = nil
    @State private var lastHoverUpdate: TimeInterval = 0
    @State private var isAppearing: Bool = false
    @State private var eventMonitor: Any? = nil
    @State private var isPulsing: Bool = false
    
    // Haptic Ticks
    @State private var currentHoverIndex: Int? = nil
    @State private var lastHapticTime: TimeInterval = 0
    
    // QuickLook Preview
    @State private var previewImage: NSImage? = nil
    @State private var previewFilePath: String? = nil
    
    // Adaptive Typography Weight
    private var queryWeight: Font.Weight {
        if engine.currentQuery.isEmpty { return .black }
        switch engine.currentQuery.count {
        case 1...2: return .bold
        case 3...4: return .semibold
        case 5...6: return .medium
        default: return .regular
        }
    }
    
    /// Extracts calculator result from search results (if any)
    private var calculatorAnswer: CalculatorResult? {
        for result in engine.searchResults {
            if case .calculatorAnswer(let calc) = result {
                return calc
            }
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Full-screen dismiss area
            Color.black.opacity(0.01)
                .contentShape(Rectangle())
                .onTapGesture {
                    windowManager.dismissWindow()
                }
            
            // The Wedge Grid
            ZStack {
                ForEach(Array(engine.searchResults.enumerated()), id: \.element.id) { index, result in
                    WedgeSegment(
                        result: result,
                        index: index,
                        total: engine.searchResults.count,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        spacing: spacing,
                        hoverLocation: hoverLocation,
                        action: {
                            engine.execute(result: result)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    ))
                    .scaleEffect(isAppearing ? 1.0 : 0.01)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(
                        isAppearing ? .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.04)
                                    : .easeIn(duration: 0.2).delay(Double(engine.searchResults.count - index) * 0.01),
                        value: isAppearing
                    )
                }
                
                // Central Search Hub
                ZStack {
                    BackdropBlurView()
                        .clipShape(Circle())
                        .frame(width: innerRadius * 2 - 4, height: innerRadius * 2 - 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 30)
                    
                    VStack(spacing: 0) {
                        // QuickLook preview for files
                        if let preview = previewImage {
                            Image(nsImage: preview)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Show calculator answer prominently in center hub
                        if let calcResult = calculatorAnswer {
                            Text(calcResult.answer)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(Color(hue: 0.35, saturation: 0.8, brightness: 1.0))
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                                .frame(width: innerRadius * 1.5)
                                .shadow(color: Color(hue: 0.35, saturation: 0.8, brightness: 1.0).opacity(0.5), radius: 8)
                            
                            Text(engine.currentQuery)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                                .padding(.top, 2)
                            
                            Text("⌘ tap to copy")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.top, 1)
                        } else {
                            Text(engine.currentQuery.isEmpty ? "CUE" : engine.currentQuery.uppercased())
                                .font(.system(size: previewImage != nil ? 16 : 28, weight: queryWeight, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(width: innerRadius * 1.5)
                            
                            if !engine.currentQuery.isEmpty {
                                Text("\(engine.searchResults.count) results")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
                .zIndex(100)
                .scaleEffect(isAppearing ? 1.0 : 0.01)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(isAppearing ? .spring(response: 0.35, dampingFraction: 0.8) : .easeIn(duration: 0.2), value: isAppearing)
                .scaleEffect(isPulsing ? 1.02 : 1.0)
                .animation(.spring(response: 0.15, dampingFraction: 0.5), value: isPulsing)
            }
            .frame(width: 800, height: 800)
            .onContinuousHover { phase in
                let now = Date().timeIntervalSince1970
                if now - lastHoverUpdate > 0.016 {
                    lastHoverUpdate = now
                    switch phase {
                    case .active(let location):
                        hoverLocation = location
                        updateHaptics(at: location)
                        updatePreview(at: location)
                    case .ended:
                        hoverLocation = nil
                        currentHoverIndex = nil
                        withAnimation(.easeOut(duration: 0.2)) {
                            previewImage = nil
                        }
                        previewFilePath = nil
                    }
                }
            }
        }
        .onReceive(windowManager.$isVisible) { isVisible in
            if !isVisible {
                isAppearing = false
                engine.reset()
                hoverLocation = nil
                currentHoverIndex = nil
                previewImage = nil
                previewFilePath = nil
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    eventMonitor = nil
                }
            } else {
                engine.reset()
                isAppearing = true
                if eventMonitor == nil {
                    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        engine.handleKeyEvent(event)
                        return nil
                    }
                }
            }
        }
        .onAppear {
            if windowManager.isVisible {
                engine.reset()
                isAppearing = true
                
                if eventMonitor == nil {
                    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        engine.handleKeyEvent(event)
                        return nil
                    }
                }
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onChange(of: engine.currentQuery) { _, _ in
            guard isAppearing else { return }
            isPulsing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPulsing = false
            }
        }
    }
    
    // MARK: - Haptic Ticks
    
    private func updateHaptics(at location: CGPoint) {
        let center = CGPoint(x: 400, y: 400)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        
        guard distance >= innerRadius && distance <= outerRadius else {
            if currentHoverIndex != nil {
                currentHoverIndex = nil
            }
            return
        }
        
        let total = engine.searchResults.count
        guard total > 0 else { return }
        
        let angle = atan2(dy, dx) * 180 / .pi
        let normAngle = angle < 0 ? angle + 360 : angle
        
        // Compute which wedge index we're in
        let step = 360.0 / Double(total)
        let startOffset = -90.0 - (step * Double(total) / 2.0) + (step / 2.0)
        var relativeAngle = normAngle - startOffset.truncatingRemainder(dividingBy: 360)
        if relativeAngle < 0 { relativeAngle += 360 }
        relativeAngle = relativeAngle.truncatingRemainder(dividingBy: 360)
        
        let wedgeIndex = Int(relativeAngle / step) % total
        
        if wedgeIndex != currentHoverIndex {
            let now = Date().timeIntervalSince1970
            if now - lastHapticTime > 0.05 { // Throttle to prevent buzzing
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                lastHapticTime = now
            }
            currentHoverIndex = wedgeIndex
        }
    }
    
    // MARK: - QuickLook Preview
    
    private func updatePreview(at location: CGPoint) {
        let center = CGPoint(x: 400, y: 400)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        
        guard distance >= innerRadius && distance <= outerRadius,
              let hoveredIndex = currentHoverIndex,
              hoveredIndex < engine.searchResults.count else {
            if previewImage != nil {
                withAnimation(.easeOut(duration: 0.15)) {
                    previewImage = nil
                }
                previewFilePath = nil
            }
            return
        }
        
        let result = engine.searchResults[hoveredIndex]
        
        // Only generate QuickLook preview for file results
        if case .file(let file) = result {
            // Avoid re-generating thumbnail for the same file
            guard file.path != previewFilePath else { return }
            previewFilePath = file.path
            
            let fileURL = URL(fileURLWithPath: file.path)
            let request = QLThumbnailGenerator.Request(
                fileAt: fileURL,
                size: CGSize(width: 120, height: 120),
                scale: 2.0,
                representationTypes: .thumbnail
            )
            
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
                DispatchQueue.main.async {
                    if let cgImage = thumbnail?.cgImage {
                        withAnimation(.easeIn(duration: 0.15)) {
                            previewImage = NSImage(cgImage: cgImage, size: NSSize(width: 120, height: 120))
                        }
                    } else {
                        // Fallback to file icon
                        withAnimation(.easeIn(duration: 0.15)) {
                            previewImage = file.icon
                        }
                    }
                }
            }
        } else {
            if previewImage != nil {
                withAnimation(.easeOut(duration: 0.15)) {
                    previewImage = nil
                }
                previewFilePath = nil
            }
        }
    }
}

// MARK: - Wedge Segment
struct WedgeSegment: View {
    let result: CueResult
    let index: Int
    let total: Int
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let spacing: Double
    let hoverLocation: CGPoint?
    let action: () -> Void
    
    // Appearance settings — read live from UserDefaults via @AppStorage
    @AppStorage(CueSettingsKey.bleedIntensity)  private var bleedIntensity: Double  = 1.0
    @AppStorage(CueSettingsKey.themePreset)     private var themePresetRaw: String  = ThemePreset.glass.rawValue
    
    private var themePreset: ThemePreset {
        ThemePreset(rawValue: themePresetRaw) ?? .glass
    }
    
    // Mathematical hit-testing
    private var isHovering: Bool {
        guard let loc = hoverLocation else { return false }
        
        let center = CGPoint(x: 400, y: 400) // ZStack frame is 800x800
        let dx = loc.x - center.x
        let dy = loc.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        
        guard distance >= innerRadius && distance <= outerRadius else { return false }
        
        let angle = atan2(dy, dx) * 180 / .pi
        let (start, end) = getAngles()
        
        let normAngle = (angle < 0 ? angle + 360 : angle).truncatingRemainder(dividingBy: 360)
        
        var startNorm = start.degrees.truncatingRemainder(dividingBy: 360)
        if startNorm < 0 { startNorm += 360 }
        
        var endNorm = end.degrees.truncatingRemainder(dividingBy: 360)
        if endNorm < 0 { endNorm += 360 }
        
        if startNorm < endNorm {
            return normAngle >= startNorm && normAngle <= endNorm
        } else {
            return normAngle >= startNorm || normAngle <= endNorm
        }
    }
    
    /// Badge icon for special result types
    private var badgeSymbol: String? {
        switch result {
        case .systemCommand(_): return "terminal.fill"
        case .file(_): return "doc.fill"
        case .calculatorAnswer(_): return "equal.circle.fill"
        case .app(_): return nil
        }
    }
    
    var body: some View {
        let (start, end) = getAngles()
        let midAngle = Angle(radians: (start.radians + end.radians) / 2)
        let midRadius = (innerRadius + outerRadius) / 2
        
        ZStack {
            // 1. Backdrop blur
            BackdropBlurView()
                .clipShape(AnnularSector(startAngle: start, endAngle: end, innerRadius: innerRadius, outerRadius: outerRadius))
                .opacity(bleedIntensity)
                .shadow(color: isHovering ? .black.opacity(0.4) : .clear, radius: isHovering ? 15 : 0, x: 0, y: isHovering ? 10 : 0)
            
            // 2. Theme tint overlay + stroke
            ZStack {
                AnnularSector(startAngle: start, endAngle: end, innerRadius: innerRadius, outerRadius: outerRadius)
                    .fill(themePreset.tintColor)
                
                AnnularSector(startAngle: start, endAngle: end, innerRadius: innerRadius, outerRadius: outerRadius)
                    .fill(Color.white.opacity(isHovering ? 0.15 : 0.0))
                    .overlay(
                        AnnularSector(startAngle: start, endAngle: end, innerRadius: innerRadius, outerRadius: outerRadius)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        themePreset.strokeColor,
                                        themePreset.strokeColor.opacity(0.5),
                                        themePreset.strokeColor.opacity(0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isHovering ? 2.0 : 1.2
                            )
                            .opacity(isHovering ? 1.0 : 0.7)
                    )
                
                // Icon and Text
                VStack(spacing: 4) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(nsImage: result.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(result.averageColor)
                                    .opacity(isHovering ? 0.4 : 0.0)
                                    .blur(radius: 10)
                                    .scaleEffect(isHovering ? 1.4 : 1.0)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(isHovering ? 0.4 : 0.0), radius: isHovering ? 8 : 0, y: isHovering ? 4 : 0)
                        
                        // Badge for special types
                        if let badge = badgeSymbol {
                            Image(systemName: badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .offset(x: 4, y: 4)
                        }
                    }
                    
                    Text(result.name)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(width: 100)
                }
                .offset(x: midRadius * CGFloat(Darwin.cos(midAngle.radians)), y: midRadius * CGFloat(Darwin.sin(midAngle.radians)))
            }
            .allowsHitTesting(false)
            
            // 3. Invisible Hitbox
            AnnularSector(startAngle: start, endAngle: end, innerRadius: innerRadius, outerRadius: outerRadius)
                .fill(Color.black.opacity(0.001))
                .allowsHitTesting(isHovering)
                .onTapGesture { action() }
        }
        .scaleEffect(isHovering ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        .zIndex(isHovering ? 10 : Double(total - index))
    }
    
    private func getAngles() -> (Angle, Angle) {
        let gapDegrees = 3.0
        let n = Double(max(total, 1))
        let step = 360.0 / n
        let startOffset = -90.0 - (step * n / 2.0) + (step / 2.0)
        
        let start = startOffset + (step * Double(index)) + (gapDegrees / 2)
        let end   = startOffset + (step * Double(index + 1)) - (gapDegrees / 2)
        
        return (Angle(degrees: start), Angle(degrees: end))
    }
}
