import SwiftUI

struct AuthenticationView: View {
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: Error?
    
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Welcome Text
                VStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.colors.sageGreen)
                    
                    Text("Welcome to Herba")
                        .appTitle()
                    
                    Text("Your AI-Powered Herbalist")
                        .appCaption()
                }
                .padding(.top, 50)
                
                // Form Fields
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .appInputStyle()
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .appInputStyle()
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = error {
                    Text(error.localizedDescription)
                        .foregroundColor(AppTheme.colors.error)
                        .appCaption()
                        .padding(.horizontal)
                }
                
                // Sign In/Up Button
                Button(action: handleAuthentication) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .appHeadline()
                    }
                }
                .appButtonStyle()
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Toggle Sign In/Up
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(AppTheme.colors.sageGreen)
                        .appCaption()
                }
                
                Spacer()
                
                // Medical Disclaimer
                Text(AIService.medicalDisclaimer)
                    .appCaption()
                    .foregroundColor(AppTheme.colors.lightText)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .background(AppTheme.colors.background)
            .navigationBarHidden(true)
        }
    }
    
    private func handleAuthentication() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let user: User
                if isSignUp {
                    user = try await FirebaseService.shared.signUp(email: email, password: password)
                } else {
                    user = try await FirebaseService.shared.signIn(email: email, password: password)
                }
                
                await MainActor.run {
                    appState.currentUser = user
                    appState.isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppState())
} 