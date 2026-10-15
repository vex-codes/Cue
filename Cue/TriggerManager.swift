import Cocoa
import Carbon

class TriggerManager {
    static let shared = TriggerManager()
    
    private init() {}
    
    func startListening() {
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(fourCharCode: "CUEH")
        hotKeyID.id = 1
        
        // 2048 is Option/Alt Key flag in Carbon, 49 is Spacebar keycode.
        let status = RegisterEventHotKey(UInt32(49), UInt32(2048), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status != noErr {
            print("Failed to register global hotkey Option+Space")
        }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            DispatchQueue.main.async {
                WindowManager.shared.toggleWindow()
            }
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
    }
}

extension OSType {
    init(fourCharCode: String) {
        var out: OSType = 0
        for char in fourCharCode.utf8 {
            out = (out << 8) | OSType(char)
        }
        self = out
    }
}
