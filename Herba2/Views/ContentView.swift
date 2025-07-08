import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .background(AppTheme.colors.background)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
} 