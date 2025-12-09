import Cocoa
import Carbon.HIToolbox

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let appState: AppState
    
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
            callback: { proxy, type, event, refcon in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
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
        print("Keyboard monitor started successfully")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap being disabled by system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        if type == .flagsChanged {
            let flags = event.flags
            let commandKeyDown = flags.contains(.maskCommand)
            
            // When Cmd is released and switcher is visible, activate selected app
            if !commandKeyDown && appState.isVisible {
                DispatchQueue.main.async {
                    self.appState.activateSelectedApp()
                }
            }
            return Unmanaged.passRetained(event)
        }
        
        if type == .keyDown {
            let flags = event.flags
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            
            // Cmd+Tab pressed
            if flags.contains(.maskCommand) && keyCode == kVK_Tab {
                DispatchQueue.main.async {
                    if self.appState.isVisible {
                        let shift = flags.contains(.maskShift)
                        self.appState.moveSelection(by: shift ? -1 : 1)
                    } else {
                        self.appState.show()
                    }
                }
                return nil // Consume the event
            }
            
            // Escape to cancel
            if keyCode == kVK_Escape && appState.isVisible {
                DispatchQueue.main.async {
                    self.appState.hide()
                }
                return nil
            }
            
            // Backspace to delete last character
            if keyCode == kVK_Delete && appState.isVisible {
                DispatchQueue.main.async {
                    self.appState.deleteLastCharacter()
                }
                return nil
            }
            
            // Letter keys while Cmd is held and switcher is visible
            if flags.contains(.maskCommand) && appState.isVisible {
                if let letter = self.letterFromKeyCode(keyCode) {
                    DispatchQueue.main.async {
                        self.appState.handleKeyPress(letter)
                    }
                    return nil
                }
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    // Map key codes to letters
    private func letterFromKeyCode(_ keyCode: Int) -> String? {
        let keyMap: [Int: String] = [
            kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d",
            kVK_ANSI_E: "e", kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h",
            kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
            kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o", kVK_ANSI_P: "p",
            kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
            kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
            kVK_ANSI_Y: "y", kVK_ANSI_Z: "z"
        ]
        return keyMap[keyCode]
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
    }
}
