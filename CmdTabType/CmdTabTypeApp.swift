import SwiftUI

@main
struct CmdTabTypeApp: App {
    @StateObject private var appState = AppState.shared
    private let appHistory = AppHistory.shared
    private let keyboardMonitor: KeyboardMonitor
    private let switcherPanel: SwitcherPanel
    
    init() {
        keyboardMonitor = KeyboardMonitor(appState: AppState.shared)
        switcherPanel = SwitcherPanel(appState: AppState.shared)
        keyboardMonitor.start()
    }
    
    var body: some Scene {
        MenuBarExtra("CmdTabType", systemImage: "command") {
            Text("CmdTabType is running").padding()
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
