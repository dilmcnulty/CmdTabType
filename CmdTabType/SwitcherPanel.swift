import SwiftUI
import AppKit
import Combine

class SwitcherPanel {
    private var panel: NSPanel?
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    init(appState: AppState) {
        self.appState = appState
        setupPanel()
        observeState()
    }
    
    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        guard let panel = panel else { return }
        
        let contentView = ContentView().environmentObject(appState)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    private func updatePanelSize() {
        guard let panel = panel, let hostingView = panel.contentView else { return }
        
        // Get the screen where the mouse currently is
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first!
        
        // Let the view calculate its ideal size
        let fittingSize = hostingView.fittingSize
        
        // Clamp to screen bounds
        let screenFrame = screen.visibleFrame
        let width = min(fittingSize.width, screenFrame.width - 40)
        let height = min(fittingSize.height, screenFrame.height - 40)
        
        // Center on screen
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - height) / 2
        
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
    
    private func observeState() {
        // Watch for visibility changes
        appState.$isVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                if visible {
                    self?.showPanel()
                } else {
                    self?.hidePanel()
                }
            }
            .store(in: &cancellables)
        
        // Watch for filter changes to resize panel
        appState.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.appState.isVisible == true {
                    self?.updatePanelSize()
                }
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
}
