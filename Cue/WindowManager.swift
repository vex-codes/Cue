import SwiftUI
import Combine

class WindowManager: NSObject, ObservableObject {
    static let shared = WindowManager()
    
    private var window: NSWindow?
    
    @Published var isVisible: Bool = false
    
    override private init() {
        super.init()
    }
    
    func setupWindow() {
        if window == nil {
            // Updated to the new app search engine and new radial fan view implementation.
            let engine = AppSearchEngine()
            
            let radialView = RadialFanView()
                .environmentObject(self)
                .environmentObject(engine)
            
            let hostingController = NSHostingController(rootView: radialView)
            
            // Create a borderless, transparent window overlay
            let newWindow = CuePanel(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 800),
                styleMask: [.borderless], // Removed .nonactivatingPanel so the OS gives the app keyboard focus instantly!
                backing: .buffered,
                defer: false
            )
            
            newWindow.isOpaque = false
            newWindow.backgroundColor = .clear
            newWindow.level = .popUpMenu // Forces to float OVER full-screen games and apps
            newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            
            newWindow.contentViewController = hostingController
            newWindow.center()
            
            self.window = newWindow
        }
    }
    
    func toggleWindow() {
        if isVisible {
            dismissWindow()
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        guard let window = window else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let windowSize = window.frame.size
        
        // Find the screen the cursor is on
        let currentScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first
        
        // Use visibleFrame to respect menu bar and Dock
        let visibleFrame = currentScreen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let edgePadding: CGFloat = 10
        
        // Start with naive center-on-cursor
        var newX = mouseLocation.x - windowSize.width / 2
        var newY = mouseLocation.y - windowSize.height / 2
        
        // Clamp horizontally
        let minX = visibleFrame.minX + edgePadding
        let maxX = visibleFrame.maxX - windowSize.width - edgePadding
        newX = max(minX, min(newX, maxX))
        
        // Clamp vertically
        let minY = visibleFrame.minY + edgePadding
        let maxY = visibleFrame.maxY - windowSize.height - edgePadding
        newY = max(minY, min(newY, maxY))
        
        let newOrigin = NSPoint(x: newX, y: newY)
        
        window.setFrameOrigin(newOrigin)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
    }
    
    func hideWindow() {
        window?.orderOut(nil)
        isVisible = false
    }
    
    func dismissWindow() {
        guard isVisible else { return }
        isVisible = false // Triggers SwiftUI Singularity collapse
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        
        // Wait for 0.2s collapse animation to finish before ordering out the physical window layer.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.hideWindow()
        }
    }
}

class CuePanel: NSPanel, NSWindowDelegate {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    override func orderFront(_ sender: Any?) {
        super.orderFront(sender)
        self.delegate = self
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        self.delegate = self
    }
    
    // Called whenever the user clicks outside this window (another app or desktop)
    func windowDidResignKey(_ notification: Notification) {
        WindowManager.shared.dismissWindow()
    }
}
