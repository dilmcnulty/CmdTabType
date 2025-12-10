import AppKit

struct AppModel: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    
    /// Check if this app matches a search query (word-prefix matching)
    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let search = query.lowercased()
        return name.lowercased()
            .split(separator: " ")
            .contains { $0.hasPrefix(search) }
    }
    
    /// Find the range of the matched text for highlighting
    func matchRange(for query: String) -> (before: String, match: String, after: String)? {
        guard !query.isEmpty else { return nil }
        let searchLower = query.lowercased()
        var charIndex = 0
        
        for word in name.components(separatedBy: " ") {
            if word.lowercased().hasPrefix(searchLower) {
                let before = String(name.prefix(charIndex))
                let match = String(name.dropFirst(charIndex).prefix(query.count))
                let after = String(name.dropFirst(charIndex + query.count))
                return (before, match, after)
            }
            charIndex += word.count + 1
        }
        return nil
    }
    
    /// Activate this application
    func activate() {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == id }?
            .activate()
    }
    
    static func getRunningApps() -> [AppModel] {
        AppHistory.shared.getOrderedApps()
    }
}
