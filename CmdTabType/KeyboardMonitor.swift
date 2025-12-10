import Cocoa
import Carbon.HIToolbox

final class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let appState: AppState
    
    private static let keyMap: [Int: String] = [
        kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d",
        kVK_ANSI_E: "e", kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h",
        kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
        kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o", kVK_ANSI_P: "p",
        kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
        kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
        kVK_ANSI_Y: "y", kVK_ANSI_Z: "z"
    ]
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, refcon in
                Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue().handleEvent(type, event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap. Check Accessibility permissions!")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    private func handleEvent(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable tap if system disabled it
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            eventTap.map { CGEvent.tapEnable(tap: $0, enable: true) }
            return Unmanaged.passRetained(event)
        }
        
        let flags = event.flags
        
        // Handle Cmd key release
        if type == .flagsChanged {
            if !flags.contains(.maskCommand) && appState.isVisible {
                DispatchQueue.main.async { self.appState.activateSelected() }
            }
            return Unmanaged.passRetained(event)
        }
        
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        // Cmd+Tab: show/cycle switcher
        if flags.contains(.maskCommand) && keyCode == kVK_Tab {
            DispatchQueue.main.async {
                if self.appState.isVisible {
                    self.appState.moveSelection(by: flags.contains(.maskShift) ? -1 : 1)
                } else {
                    self.appState.show()
                }
            }
            return nil
        }
        
        // Only handle remaining keys when switcher is visible
        guard appState.isVisible else {
            return Unmanaged.passRetained(event)
        }
        
        switch keyCode {
        case kVK_Escape:
            DispatchQueue.main.async { self.appState.hide() }
            return nil
        case kVK_Delete:
            DispatchQueue.main.async { self.appState.deleteLastCharacter() }
            return nil
        default:
            if flags.contains(.maskCommand), let letter = Self.keyMap[keyCode] {
                DispatchQueue.main.async { self.appState.handleKeyPress(letter) }
                return nil
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    func stop() {
        eventTap.map { CGEvent.tapEnable(tap: $0, enable: false) }
        runLoopSource.map { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), $0, .commonModes) }
    }
}
