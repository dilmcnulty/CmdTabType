import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    // Calculate icon size based on app count and screen width
    private var iconSize: CGFloat {
        let appCount = max(appState.filteredApps.count, 1)
        
        // Get the screen where mouse is
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first!
        
        let screenWidth = screen.visibleFrame.width
        let maxPanelWidth = screenWidth - 100
        let padding: CGFloat = 40
        let spacing: CGFloat = 12
        let extraPerItem: CGFloat = 36
        
        let totalSpacing = CGFloat(max(appCount - 1, 0)) * spacing
        let availableForIcons = maxPanelWidth - padding - totalSpacing
        let maxIconSizeForCount = (availableForIcons / CGFloat(appCount)) - extraPerItem
        
        let minSize: CGFloat = 48
        let maxSize: CGFloat = 128
        
        return min(max(maxIconSizeForCount, minSize), maxSize)
    }
    
    private var textWidth: CGFloat {
        return iconSize + 12
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
                            iconSize: iconSize,
                            textWidth: textWidth
                        )
                        .onTapGesture {
                            appState.activateApp(app)
                        }
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
    let textWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
            
            highlightedName
                .font(iconSize < 64 ? .system(size: 9) : .caption)
                .lineLimit(1)
                .frame(width: textWidth)
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
        
        guard !searchText.isEmpty else {
            return Text(app.name)
                .foregroundColor(baseColor)
                .fontWeight(isSelected ? .bold : .regular)
        }
        
        let name = app.name
        let searchLower = searchText.lowercased()
        
        let words = name.components(separatedBy: " ")
        var charIndex = 0
        
        for word in words {
            let wordLower = word.lowercased()
            
            if wordLower.hasPrefix(searchLower) {
                let beforeMatch = String(name.prefix(charIndex))
                let matchPart = String(name.dropFirst(charIndex).prefix(searchText.count))
                let afterMatch = String(name.dropFirst(charIndex + searchText.count))
                
                return Text(beforeMatch).foregroundColor(baseColor) +
                       Text(matchPart).foregroundColor(.orange).fontWeight(.bold) +
                       Text(afterMatch).foregroundColor(baseColor)
            }
            
            charIndex += word.count + 1
        }
        
        return Text(name).foregroundColor(baseColor)
    }
}
