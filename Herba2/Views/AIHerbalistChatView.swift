import SwiftUI
import UIKit

struct AIHerbalistChatView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AIHerbalistChatViewModel
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isTyping = false
    @State private var showTypingIndicator = false
    @State private var messageText = ""
    @State private var animateNewMessage = false
    
    // Haptic feedback
    let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    init() {
        _viewModel = StateObject(wrappedValue: AIHerbalistChatViewModel(profile: nil))
    }
    
    var body: some View {
        ChatContentView(
            viewModel: viewModel,
            scrollProxy: $scrollProxy,
            showTypingIndicator: $showTypingIndicator,
            messageText: $messageText,
            lightHaptic: lightHaptic,
            mediumHaptic: mediumHaptic
        )
                    .onAppear {
            if viewModel.messages.isEmpty {
                Task {
                    await viewModel.startConversation()
                    }
                }
        }
        .onChange(of: appState.selectedProfile) { _, newProfile in
            viewModel.userProfile = newProfile.map { profile in
                UserProfile(
                    id: profile.id ?? "current_user",
                    firstName: profile.name,
                    allergies: profile.allergies,
                    chronicConditions: profile.chronicConditions,
                    medications: profile.medications,
                    preferences: [:]
                )
            }
            Task {
                await viewModel.startConversation()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
    }
}

// MARK: - Chat Content View
private struct ChatContentView: View {
    @ObservedObject var viewModel: AIHerbalistChatViewModel
    @Binding var scrollProxy: ScrollViewProxy?
    @Binding var showTypingIndicator: Bool
    @Binding var messageText: String
    let lightHaptic: UIImpactFeedbackGenerator
    let mediumHaptic: UIImpactFeedbackGenerator
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack(spacing: 0) {
                HeaderView(viewModel: viewModel, mediumHaptic: mediumHaptic)
                
                ChatMessagesView(
                    viewModel: viewModel,
                    scrollProxy: $scrollProxy,
                    showTypingIndicator: showTypingIndicator,
                    lightHaptic: lightHaptic
                )
                
                ChatInputView(
                    messageText: $messageText,
                    viewModel: viewModel,
                    mediumHaptic: mediumHaptic,
                    showTypingIndicator: $showTypingIndicator,
                    lightHaptic: lightHaptic
                )
            }
        }
    }
}

// MARK: - Header View
private struct HeaderView: View {
    @ObservedObject var viewModel: AIHerbalistChatViewModel
    let mediumHaptic: UIImpactFeedbackGenerator
    
    var body: some View {
        HStack {
            Image("herbalist_avatar")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppTheme.colors.sageGreen, lineWidth: 2)
                )
                .shadow(color: AppTheme.colors.accent.opacity(0.2), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading) {
                Text("Herba")
                    .appHeadline()
                Text("Your AI Wellness Guide")
                    .appCaption()
            }
            
            Spacer()
            
            Button(action: {
                mediumHaptic.impactOccurred()
                Task {
                    await viewModel.startConversation()
                }
            }) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(AppTheme.colors.sageGreen)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: AppTheme.colors.sageGreen.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .padding()
        .background(AppTheme.Styles.cardBackground)
    }
}

// MARK: - Background View
private struct BackgroundView: View {
    var body: some View {
        AppTheme.colors.background
            .overlay(
                Image("paper_texture")
                    .resizable()
                    .opacity(0.1)
                    .blendMode(.multiply)
            )
            .ignoresSafeArea()
    }
}

// MARK: - Chat Messages View
private struct ChatMessagesView: View {
    @ObservedObject var viewModel: AIHerbalistChatViewModel
    @Binding var scrollProxy: ScrollViewProxy?
    let showTypingIndicator: Bool
    let lightHaptic: UIImpactFeedbackGenerator
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(for: message)
                    }
                    if showTypingIndicator {
                        TypingIndicator()
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }
    
    @ViewBuilder
    private func messageBubble(for message: ChatMessage) -> some View {
        MessageBubble(
            message: message,
            onTryRemedy: { remedyName, ailment in
                let name = message.context?.remedyName ?? remedyName
                let ailmentName = message.context?.ailment ?? ailment
                print("[DEBUG] onTryRemedy called with remedyName: \(name), ailment: \(ailmentName)")
            },
            onAskAlternatives: {
                Task {
                    let lastRemedy = message.context?.remedyName ?? "this remedy"
                    viewModel.inputText = "Can you suggest any alternatives to \(lastRemedy)?"
                    await viewModel.sendMessage()
                    }
                }
        )
        .id(message.id)
        .transition(.opacity.combined(with: .scale))
        .onAppear {
            if message.role == .ai {
                lightHaptic.impactOccurred(intensity: 0.3)
        }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Chat Input View
private struct ChatInputView: View {
    @Binding var messageText: String
    @ObservedObject var viewModel: AIHerbalistChatViewModel
    let mediumHaptic: UIImpactFeedbackGenerator
    @Binding var showTypingIndicator: Bool
    let lightHaptic: UIImpactFeedbackGenerator
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $messageText)
                .appInputStyle()
                .onChange(of: messageText) { _, _ in
                    lightHaptic.impactOccurred(intensity: 0.3)
                }
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.colors.sageGreen)
                    .shadow(color: AppTheme.colors.sageGreen.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .disabled(messageText.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(AppTheme.Styles.cardBackground)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        mediumHaptic.impactOccurred()
        showTypingIndicator = true
        
        Task {
            viewModel.inputText = messageText
            messageText = ""
            await viewModel.sendMessage()
            withAnimation {
                showTypingIndicator = false
            }
            UIApplication.shared.endEditing() // Dismiss the keyboard after sending
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var onTryRemedy: ((String, String) -> Void)? = nil
    var onAskAlternatives: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: message.role == .ai ? .leading : .trailing) {
                // Always use the default message bubble, even for solutions
                    Text(message.text)
                        .appBody()
                        .padding(12)
                        .background(
                            message.role == .ai ?
                                AppTheme.colors.tertiary :
                                AppTheme.colors.sageGreen
                        )
                        .foregroundColor(message.role == .ai ? AppTheme.colors.text : .white)
                        .cornerRadius(20)
                        .shadow(color: AppTheme.colors.sageGreen.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            if message.role == .user {
                Spacer(minLength: 40)
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Message Parsing Extensions
    func parseRemedyName(from text: String) -> String {
        // First try to get from context
        if let remedyName = message.context?.remedyName {
            return remedyName
        }
        
        // Otherwise parse from text
        let lines = text.components(separatedBy: .newlines)
        if let firstLine = lines.first {
            // Try to extract remedy name after "Here's a natural remedy:" or similar patterns
            let patterns = [
                "Here's a natural remedy for you: ",
                "I recommend ",
                "Try ",
                "You might benefit from "
            ]
            
            for pattern in patterns {
                if firstLine.contains(pattern),
                   let remedyName = firstLine.components(separatedBy: pattern).last?.trimmingCharacters(in: .punctuationCharacters) {
                    return remedyName
                }
            }
            
            // If no pattern matches, return the first line up to the first period or comma
            if let endIndex = firstLine.firstIndex(where: { $0 == "." || $0 == "," }) {
                return String(firstLine[..<endIndex]).trimmingCharacters(in: .whitespaces)
                            }
            
            // Fallback to first line
            return firstLine.trimmingCharacters(in: .whitespaces)
                    }
        
        return "Remedy"
    }
    
    func parseSection(from text: String, section: String) -> [String]? {
        let lines = text.components(separatedBy: .newlines)
        var sectionContent: [String] = []
        var inSection = false
        
        for line in lines {
            if line.lowercased().contains(section.lowercased() + ":") {
                inSection = true
                continue
            } else if inSection && (line.isEmpty || line.hasSuffix(":")) {
                break
            }
            
            if inSection && !line.isEmpty {
                // Clean up bullet points and extra spaces
                var cleanLine = line.trimmingCharacters(in: .whitespaces)
                if cleanLine.hasPrefix("•") || cleanLine.hasPrefix("-") {
                    cleanLine = cleanLine.dropFirst().trimmingCharacters(in: .whitespaces)
                }
                sectionContent.append(cleanLine)
                }
            }
            
        return sectionContent.isEmpty ? nil : sectionContent
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.colors.accent)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: animationOffset
                    )
            }
        }
        .padding(12)
        .background(AppTheme.colors.tertiary)
        .cornerRadius(20)
        .onAppear {
            animationOffset = -5
        }
    }
}

#Preview {
    NavigationView {
        AIHerbalistChatView()
            .environmentObject(AppState())
    }
}

extension Notification.Name {
    static let herbalistFeedback = Notification.Name("herbalistFeedback")
    static let startTrackingRemedy = Notification.Name("startTrackingRemedy")
    static let setRemindersForRemedy = Notification.Name("setRemindersForRemedy")
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 
 