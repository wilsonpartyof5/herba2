import Foundation
import SwiftUI
import Combine

@MainActor
class AIHerbalistChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published var chatState: ChatState = .idle
    
    private let chatService: AIHerbalistChatService
    private var isWaitingForDiagnosticAnswer = false
    private var retryCount = 0
    private let maxRetries = 3
    private var currentContext: ChatMessage.MessageContext?
    var userProfile: UserProfile?
    // Remedy progress tracking
    @Published var remedyProgressVM = RemedyProgressViewModel()
    private var lastSuggestedRemedy: String? = nil
    private var awaitingTrackingConfirmation: Bool = false
    private var awaitingReminderConfirmation: String? = nil
    
    init(profile: Profile?) {
        let apiKey = APIConfig.openAIKey
        if apiKey.isEmpty {
            self.error = "OpenAI API key is missing. Please check your configuration."
            self.showError = true
        }
        guard let knowledgeBasePath = Bundle.main.path(forResource: "herbal_knowledge_enhanced", ofType: "json") else {
            self.error = "Could not find herbal knowledge base"
            self.showError = true
            self.chatService = AIHerbalistChatService(knowledgeBasePath: "", apiKey: "")
            return
        }
        self.chatService = AIHerbalistChatService(knowledgeBasePath: knowledgeBasePath, apiKey: apiKey)
        
        if let profile = profile {
            self.userProfile = UserProfile(
                id: profile.id ?? "current_user",
                firstName: profile.name,
                allergies: profile.allergies,
                chronicConditions: profile.chronicConditions,
                medications: profile.medications,
                preferences: [:]
            )
        } else {
            self.userProfile = UserProfile(
                id: "current_user",
                firstName: "User",
                allergies: [],
                chronicConditions: [],
                medications: [],
                preferences: [:]
            )
        }
        
        NotificationCenter.default.addObserver(forName: .herbalistFeedback, object: nil, queue: .main) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let remedy = userInfo["remedy"] as? String,
                  let feedback = userInfo["feedback"] as? String else { return }
            let remedyName = remedy.components(separatedBy: "\n").first ?? remedy
            Task { @MainActor in
                self.chatService.recordFeedback(for: remedyName, feedback: feedback)
            }
        }
    }
    
    func startConversation() async {
        messages.removeAll()
        currentContext = nil
        isWaitingForDiagnosticAnswer = false
        error = nil
        showError = false
        chatState = .idle
        
        // Add personalized welcome message
        let welcomeMessage = createPersonalizedWelcome()
        messages.append(welcomeMessage)
    }
    
    private func createPersonalizedWelcome() -> ChatMessage {
        let greetings = [
            "Welcome to Herba! I'm your friendly AI Herbalist, here to support your wellness journey. How can I help you today?",
            "Hi there! 🌿 I'm your AI Herbalist. What brings you to Herba today?",
            "Hello and welcome! I'm here to help you find natural solutions for your health. How can I assist?",
            "Greetings! I'm your personal AI Herbalist. Let me know what you're looking for help with today."
        ]
        let welcomeText = greetings.randomElement() ?? greetings[0]
        return ChatMessage.makeAI(
            text: welcomeText,
            context: ChatMessage.MessageContext(userPreferences: userProfile?.preferences)
        )
    }
    
    private func makeConversationalBridge() -> String {
        let bridgePhrases = [
            "Thanks for sharing! Would you like a natural remedy suggestion?",
            "I'm here to help—would you like some herbal advice?",
            "Would you like to see some gentle herbal options that might help?",
            "I appreciate you telling me how you're feeling. Want a remedy suggestion?"
        ]
        let name = userProfile?.firstName ?? "there"
        let ailment = userProfile?.chronicConditions.first
        if let ailment = ailment, !ailment.isEmpty {
            return "Thanks for sharing, \(name). Would you like a natural remedy for your \(ailment)?"
        } else {
            return bridgePhrases.randomElement() ?? bridgePhrases[0]
        }
    }
    
    func sendMessage() async {
        guard !inputText.isEmpty else { return }
        let userMessage = ChatMessage.makeUser(
            text: inputText,
            profileId: userProfile?.id ?? "current_user",
            context: currentContext
        )
        messages.append(userMessage)
        let messageToProcess = inputText
        inputText = ""
        isLoading = true
        error = nil
        retryCount = 0
        // --- UNIVERSAL AI INTENT DETECTION ---
        var detectedIntent: String = "general"
        do {
            detectedIntent = try await chatService.openAIService.classifyIntent(userMessage: messageToProcess)
            print("[DEBUG] Detected intent: \(detectedIntent)")
        } catch {
            print("[DEBUG] Intent detection error: \(error)")
            detectedIntent = "general"
        }
        // --- TRACKING/REMINDER LOGIC (unchanged, but now only runs if intent is track/reminder) ---
        if detectedIntent == "track" && awaitingTrackingConfirmation {
            let prompt = "Does this message indicate the user wants to start tracking their remedy? Respond only with yes or no."
            var wantsTracking: Bool? = nil
            do {
                let aiResult = try await chatService.openAIService.generateResponse(messages: [
                    OpenAIChatMessage(role: "system", content: prompt),
                    OpenAIChatMessage(role: "user", content: messageToProcess)
                ])
                let trimmed = aiResult.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                print("[DEBUG] Tracking intent AI result: \(trimmed)")
                if trimmed.hasPrefix("yes") {
                    wantsTracking = true
                } else if trimmed.hasPrefix("no") {
                    wantsTracking = false
                } else {
                    wantsTracking = nil
                }
            } catch {
                print("[DEBUG] Tracking intent AI error: \(error)")
                wantsTracking = nil
            }
            if let remedyName = lastSuggestedRemedy, wantsTracking == true {
                let ailment = currentContext?.ailment ?? "General"
                remedyProgressVM.addRemedy(remedyName, ailment: ailment)
                let confirmMsg = ChatMessage.makeAI(text: "Great! I'll help you keep track of your progress with \(remedyName). Would you like a daily reminder to take your remedy and log your progress?")
                messages.append(confirmMsg)
                awaitingTrackingConfirmation = false
                isLoading = false
                awaitingReminderConfirmation = remedyName
                return
            } else if wantsTracking == false {
                let msg = ChatMessage.makeAI(text: "No problem! Let me know if you'd like to track your progress with this remedy later.")
                messages.append(msg)
                awaitingTrackingConfirmation = false
                isLoading = false
                return
            } else {
                let msg = ChatMessage.makeAI(text: "Sorry, I didn't understand. Would you like to track your progress with this remedy? Please reply yes or no.")
                messages.append(msg)
                isLoading = false
                return
            }
        }
        if detectedIntent == "reminder" && awaitingReminderConfirmation != nil {
            let remedyName = awaitingReminderConfirmation!
            let prompt = "Does this message indicate the user wants a daily reminder for their remedy? Respond only with yes or no."
            var wantsReminder: Bool? = nil
            do {
                let aiResult = try await chatService.openAIService.generateResponse(messages: [
                    OpenAIChatMessage(role: "system", content: prompt),
                    OpenAIChatMessage(role: "user", content: messageToProcess)
                ])
                let trimmed = aiResult.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                print("[DEBUG] Reminder intent AI result: \(trimmed)")
                if trimmed.hasPrefix("yes") {
                    wantsReminder = true
                } else if trimmed.hasPrefix("no") {
                    wantsReminder = false
                } else {
                    wantsReminder = nil
                }
            } catch {
                print("[DEBUG] Reminder intent AI error: \(error)")
                wantsReminder = nil
            }
            if wantsReminder == true {
                let time = parseTime(from: messageToProcess) ?? defaultReminderTime()
                if let remedy = remedyProgressVM.activeRemedies.first(where: { $0.remedyName == remedyName }) {
                    remedyProgressVM.setReminder(for: remedy.id, time: time)
                    let timeString = String(format: "%02d:%02d", time.hour ?? 9, time.minute ?? 0)
                    let confirmMsg = ChatMessage.makeAI(text: "Reminder set for \(remedyName) at \(timeString) each day. I'll nudge you to take your remedy and log your progress!")
                    messages.append(confirmMsg)
                    awaitingReminderConfirmation = nil
                    isLoading = false
                    return
                }
            } else if wantsReminder == false {
                let msg = ChatMessage.makeAI(text: "Okay, no daily reminder set. Let me know if you want one later!")
                messages.append(msg)
                awaitingReminderConfirmation = nil
                isLoading = false
                return
            } else {
                let msg = ChatMessage.makeAI(text: "Sorry, I didn't understand. Would you like a daily reminder for your remedy? Please reply yes or no.")
                messages.append(msg)
                isLoading = false
                return
            }
        }
        // --- REMEDY SUGGESTION LOGIC ---
        if detectedIntent == "remedy" && chatService.publicHasEnoughDiagnosticInfo() {
            let remedies = chatService.publicGetRecommendedRemedies()
            if let remedy = remedies.first {
                let solution = "Here's a natural remedy for you: \(remedy.name). Would you like to try it?"
                let context = ChatMessage.MessageContext(
                    ailment: currentContext?.ailment,
                    remedyName: remedy.name
                )
                let aiSolution = ChatMessage.makeAI(text: solution, isSolution: true, context: context)
                messages.append(aiSolution)
                chatState = .givingSolution
            } else {
                let fallback = "I couldn't find a specific remedy, but I can offer some general wellness tips."
                messages.append(ChatMessage.makeAI(text: fallback))
                chatState = .idle
            }
            isLoading = false
            return
        }
        // --- ALTERNATIVE REMEDY LOGIC ---
        if detectedIntent == "alternative" && chatService.publicHasEnoughDiagnosticInfo() {
            let remedies = chatService.publicGetRecommendedRemedies()
            if remedies.count > 1 {
                let remedy = remedies[1] // next alternative
                let solution = "Here's an alternative remedy for you: \(remedy.name). Would you like to try it?"
                let context = ChatMessage.MessageContext(
                    ailment: currentContext?.ailment,
                    remedyName: remedy.name
                )
                let aiSolution = ChatMessage.makeAI(text: solution, isSolution: true, context: context)
                messages.append(aiSolution)
                chatState = .givingSolution
            } else {
                let fallback = "I couldn't find an alternative remedy, but I can offer some general wellness tips."
                messages.append(ChatMessage.makeAI(text: fallback))
                chatState = .idle
            }
            isLoading = false
            return
        }
        // --- FEEDBACK/THANKS LOGIC ---
        if detectedIntent == "feedback" {
            let msg = ChatMessage.makeAI(text: "Thank you for your feedback! If you have more questions or need another remedy, just let me know.")
            messages.append(msg)
            isLoading = false
                return
            }
        // --- GENERAL/OTHER: FALLBACK TO NORMAL AI CHAT ---
        chatState = .inDiagnostics // Assume diagnostic until proven otherwise
        do {
            let aiResponse = try await chatService.processDiagnosticAnswer(messageToProcess, currentMessages: messages)
            messages.append(aiResponse)
            if aiResponse.isSolution == true {
                lastSuggestedRemedy = aiResponse.context?.remedyName ?? extractRemedyName(from: aiResponse.text)
                awaitingTrackingConfirmation = true
                chatState = .givingSolution
            } else {
                chatState = .inDiagnostics
            }
            isLoading = false
            return
        } catch let error as OpenAIServiceError {
            handleError(error.localizedDescription)
            chatState = .error(error.localizedDescription)
            isLoading = false
        } catch {
            handleError("An error occurred while processing your request. Please try again.")
            chatState = .error(error.localizedDescription)
            isLoading = false
        }
    }
    
    private func handleError(_ message: String) {
        self.error = message
        self.showError = true
        self.messages.append(ChatMessage.makeAI(
            text: "I apologize, but I'm having trouble processing your request. Please try again in a moment."
        ))
    }
    
    func clearChat() {
        Task { @MainActor in
            await startConversation()
        }
    }
    
    // Helper to extract remedy name from AI message text
    private func extractRemedyName(from text: String) -> String? {
        // Simple regex or string parsing to find remedy name after 'Remedy:' or similar
        if let range = text.range(of: "Remedy:") {
            let after = text[range.upperBound...]
            return after.components(separatedBy: "\n").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Fallback: look for first capitalized word
        let words = text.components(separatedBy: " ")
        return words.first(where: { $0.first?.isUppercase == true })
    }
    
    // Helper to parse time from user input
    private func parseTime(from text: String) -> DateComponents? {
        // Simple regex for times like '8am', '7:30 pm', etc.
        let lower = text.lowercased()
        let regex = try? NSRegularExpression(pattern: "(\\d{1,2})(?::(\\d{2}))?\\s*(am|pm)?")
        if let match = regex?.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) {
            let hourRange = Range(match.range(at: 1), in: lower)
            let minRange = Range(match.range(at: 2), in: lower)
            let ampmRange = Range(match.range(at: 3), in: lower)
            var hour = hourRange.flatMap { Int(lower[$0]) } ?? 9
            let minute = minRange.flatMap { Int(lower[$0]) } ?? 0
            let ampm = ampmRange.map { String(lower[$0]) }
            if let ampm = ampm {
                if ampm == "pm" && hour < 12 { hour += 12 }
                if ampm == "am" && hour == 12 { hour = 0 }
            }
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            return comps
        }
        return nil
    }
    
    private func defaultReminderTime() -> DateComponents {
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        return comps
    }
}

// User Profile Model
struct UserProfile {
    let id: String
    let firstName: String
    let allergies: [String]
    let chronicConditions: [String]
    let medications: [String]
    var preferences: [String: String]
}

enum ChatState: Equatable {
    case idle
    case awaitingSymptom
    case inDiagnostics
    case givingSolution
    case error(String)
} 
