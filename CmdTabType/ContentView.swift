import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(Array(appState.filteredApps.enumerated()), id: \.offset) { index, app in
                AppIconView(
                    app: app,
                    isSelected: index == appState.selectedIndex,
                    searchText: appState.searchText
                )
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
    
    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
            
            Text(highlightedName)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 72)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        )
    }
    
    private var highlightedName: AttributedString {
        var result = AttributedString(app.name)
        if !searchText.isEmpty {
            let prefixLength = min(searchText.count, app.name.count)
            if let range = result.range(of: String(app.name.prefix(prefixLength)), options: .caseInsensitive) {
                result[range].foregroundColor = .accentColor
                result[range].font = .caption.bold()
            }
        }
        return result
    }
}
