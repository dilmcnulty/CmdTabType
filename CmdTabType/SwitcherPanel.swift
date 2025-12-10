import SwiftUI
import Combine

final class SwitcherPanel {
    private var panel: NSPanel?
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    init(appState: AppState) {
        self.appState = appState
        setupPanel()
        observeState()
    }
    
    private func setupPanel() {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.contentView = NSHostingView(rootView: ContentView().environmentObject(appState))
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.panel = panel
    }
    
    private func observeState() {
        appState.$isVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                visible ? self?.showPanel() : self?.hidePanel()
            }
            .store(in: &cancellables)
        
        appState.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard self?.appState.isVisible == true else { return }
                self?.updatePanelSize()
            }
            .store(in: &cancellables)
    }
    
    private func showPanel() {
        updatePanelSize()
        panel?.orderFrontRegardless()
    }
    
    private func hidePanel() {
        panel?.orderOut(nil)
    }
    
    private func updatePanelSize() {
        guard let panel = panel, let contentView = panel.contentView else { return }
        
        let screen = currentScreen
        let fittingSize = contentView.fittingSize
        let screenFrame = screen.visibleFrame
        
        let width = min(fittingSize.width, screenFrame.width - 40)
        let height = min(fittingSize.height, screenFrame.height - 40)
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - height) / 2
        
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
    
    private var currentScreen: NSScreen {
        // Get the screen where the frontmost app's main window is
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
           let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
            for window in windows {
                guard let pid = window[kCGWindowOwnerPID as String] as? Int32,
                      pid == frontmostApp.processIdentifier,
                      let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                      let x = bounds["X"], let y = bounds["Y"] else { continue }
                
                let point = NSPoint(x: x, y: y)
                if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
                    return screen
                }
            }
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }
}
