import SwiftUI
import AppKit
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isVisible: Bool = false
    @Published var apps: [AppModel] = []
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = ""
    
    var filteredApps: [AppModel] {
        if searchText.isEmpty {
            return apps
        }
        let search = searchText.lowercased()
        return apps.filter { app in
            // Check if any word in the app name starts with the search text
            let words = app.name.lowercased().split(separator: " ")
            return words.contains { word in
                word.hasPrefix(search)
            }
        }
    }
    
    func show() {
        apps = AppModel.getRunningApps()
        searchText = ""
        // Pre-select the SECOND app (index 1) so Cmd+Tab toggles between last two
        selectedIndex = apps.count > 1 ? 1 : 0
        isVisible = true
        print("Showing switcher with \(apps.count) apps, selected: \(selectedIndex)")
        print("Apps: \(apps.map { $0.name })")
    }
    
    func hide() {
        isVisible = false
        searchText = ""
    }
    
    func activateSelectedApp() {
        let appsToShow = filteredApps
        guard !appsToShow.isEmpty, selectedIndex < appsToShow.count else {
            hide()
            return
        }
        let app = appsToShow[selectedIndex]
        
        print("Activating: \(app.name)")
        
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.id }) {
            runningApp.activate()
        }
        hide()
    }
    
    func activateApp(_ app: AppModel) {
        print("Activating (click): \(app.name)")
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == app.id }) {
            runningApp.activate()
        }
        hide()
    }
    
    func handleKeyPress(_ characters: String) {
        let newSearchText = searchText + characters.lowercased()
        let wouldMatch = apps.contains { app in
            let words = app.name.lowercased().split(separator: " ")
            return words.contains { word in
                word.hasPrefix(newSearchText)
            }
        }
        if wouldMatch {
            searchText = newSearchText
            selectedIndex = 0
        }
    }
    
    func deleteLastCharacter() {
        if !searchText.isEmpty {
            searchText.removeLast()
            selectedIndex = 0
        }
    }
    
    func moveSelection(by offset: Int) {
        let count = filteredApps.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + offset + count) % count
    }
}
