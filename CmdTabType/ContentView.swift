import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    private var iconSize: CGFloat {
        let appCount = max(appState.filteredApps.count, 1)
        let screenWidth = currentScreen.visibleFrame.width
        let maxPanelWidth = screenWidth - 100
        let totalSpacing = CGFloat(max(appCount - 1, 0)) * 12
        let availablePerIcon = (maxPanelWidth - 40 - totalSpacing) / CGFloat(appCount) - 36
        return min(max(availablePerIcon, 48), 128)
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
    
    var body: some View {
        VStack(spacing: 8) {
            if !appState.searchText.isEmpty {
                Text("Search: \(appState.searchText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                if appState.filteredApps.isEmpty {
                    Text("No matches for \"\(appState.searchText)\"")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(Array(appState.filteredApps.enumerated()), id: \.offset) { index, app in
                        AppIconView(
                            app: app,
                            isSelected: index == appState.selectedIndex,
                            searchText: appState.searchText,
                            iconSize: iconSize
                        )
                        .onTapGesture { appState.activate(app) }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct AppIconView: View {
    let app: AppModel
    let isSelected: Bool
    let searchText: String
    let iconSize: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
            
            highlightedName
                .font(iconSize < 64 ? .system(size: 9) : .caption)
                .lineLimit(1)
                .frame(width: iconSize + 12)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    private var highlightedName: Text {
        let baseColor: Color = isSelected ? .accentColor : .primary
        let weight: Font.Weight = isSelected ? .bold : .regular
        
        guard let match = app.matchRange(for: searchText) else {
            return Text(app.name).foregroundColor(baseColor).fontWeight(weight)
        }
        
        return Text(match.before).foregroundColor(baseColor) +
               Text(match.match).foregroundColor(.orange).fontWeight(.bold) +
               Text(match.after).foregroundColor(baseColor)
    }
}
