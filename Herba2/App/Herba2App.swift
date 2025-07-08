import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct Herba2App: App {
    @StateObject private var appState = AppState()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// Global app state
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var currentUser: User?
    @Published var selectedProfile: Profile?
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        // Bypass authentication for development
        self.isAuthenticated = true
        self.currentUser = User(
            id: "testuser",
            email: "test@herba.com",
            displayName: "Test User",
            consented: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // Add more app-wide state as needed
} 