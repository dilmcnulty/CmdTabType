import SwiftUI

@main
struct CmdTabTypeApp: App {
    @StateObject private var appState = AppState.shared
    private let keyboardMonitor: KeyboardMonitor
    private let switcherPanel: SwitcherPanel
    
    init() {
        let state = AppState.shared
        keyboardMonitor = KeyboardMonitor(appState: state)
        switcherPanel = SwitcherPanel(appState: state)
        keyboardMonitor.start()
    }
    
    var body: some Scene {
        MenuBarExtra("CmdTabType", systemImage: "command") {
            VStack {
                Text("CmdTabType is running")
                    .padding()
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}
