import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isVisible = false
    @Published var apps: [AppModel] = []
    @Published var selectedIndex = 0
    @Published var searchText = ""
    
    // Cached screen for current session (computed once when shown)
    var currentScreen: NSScreen = NSScreen.main ?? NSScreen.screens[0]
    
    var filteredApps: [AppModel] {
        apps.filter { $0.matches(searchText) }
    }
    
    func show() {
        // Cache the screen once (NSScreen.main is the screen with the key window - fast!)
        currentScreen = NSScreen.main ?? NSScreen.screens[0]
        apps = AppModel.getRunningApps()
        searchText = ""
        selectedIndex = apps.count > 1 ? 1 : 0
        isVisible = true
    }
    
    func hide() {
        isVisible = false
        searchText = ""
    }
    
    func activateSelected() {
        guard let app = filteredApps[safe: selectedIndex] else {
            hide()
            return
        }
        app.activate()
        hide()
    }
    
    func activate(_ app: AppModel) {
        app.activate()
        hide()
    }
    
    func handleKeyPress(_ char: String) {
        let newSearch = searchText + char.lowercased()
        if apps.contains(where: { $0.matches(newSearch) }) {
            searchText = newSearch
            selectedIndex = 0
        }
    }
    
    func deleteLastCharacter() {
        guard !searchText.isEmpty else { return }
        searchText.removeLast()
        selectedIndex = 0
    }
    
    func moveSelection(by offset: Int) {
        let count = filteredApps.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + offset + count) % count
    }
}

// Safe array subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
