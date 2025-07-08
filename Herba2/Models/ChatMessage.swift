import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let profileId: String
    let role: MessageRole
    var text: String
    var evidenceSnippets: [String]?
    var preparationSteps: String?
    var safetyDosage: String?
    var freshnessDate: Date?
    var createdAt: Date
    var isDiagnosticQuestion: Bool?
    var isSolution: Bool?
    var context: MessageContext?
    var userFeedback: String?
    
    struct MessageContext: Codable, Equatable {
        var ailment: String?
        var severity: Int?
        var duration: String?
        var previousRemedies: [String]?
        var userPreferences: [String: String]?
        var followUpDate: Date?
        var remedyName: String?
    }
    
    enum MessageRole: String, Codable {
        case user
        case ai
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId
        case role
        case text
        case evidenceSnippets
        case preparationSteps
        case safetyDosage
        case freshnessDate
        case createdAt
        case isDiagnosticQuestion
        case isSolution
        case context
        case userFeedback
    }
}

extension ChatMessage {
    var isUser: Bool { role == .user }
}

extension ChatMessage {
    /// Factory for AI messages
    static func makeAI(text: String, isDiagnosticQuestion: Bool? = nil, isSolution: Bool? = nil, evidenceSnippets: [String]? = nil, preparationSteps: String? = nil, safetyDosage: String? = nil, context: MessageContext? = nil) -> ChatMessage {
        ChatMessage(
            id: UUID().uuidString,
            profileId: "ai_herbalist",
            role: .ai,
            text: text,
            evidenceSnippets: evidenceSnippets,
            preparationSteps: preparationSteps,
            safetyDosage: safetyDosage,
            createdAt: Date(),
            isDiagnosticQuestion: isDiagnosticQuestion,
            isSolution: isSolution,
            context: context
        )
    }
    /// Factory for user messages
    static func makeUser(text: String, profileId: String, context: MessageContext? = nil) -> ChatMessage {
        ChatMessage(
            id: UUID().uuidString,
            profileId: profileId,
            role: .user,
            text: text,
            createdAt: Date(),
            context: context
        )
    }
}

// Rename this struct for OpenAI API compatibility
struct OpenAIChatMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
} 