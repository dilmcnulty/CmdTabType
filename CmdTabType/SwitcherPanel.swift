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
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        guard let panel = panel else { return }
        
        let contentView = ContentView().environmentObject(appState)
        let hostingView = NSHostingView(rootView: contentView)
        
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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
    
    private func updatePanelSize() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let appCount = max(appState.filteredApps.count, 1)
        let width = min(CGFloat(appCount) * 100 + 40, screen.frame.width - 100)
        let height: CGFloat = 120
        
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - height) / 2
        
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
    
    private func showPanel() {
        updatePanelSize()
        panel?.orderFrontRegardless()
    }
    
    private func hidePanel() {
        panel?.orderOut(nil)
    }
}
