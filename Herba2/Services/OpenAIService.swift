import Foundation

class OpenAIService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateResponse(messages: [OpenAIChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIServiceError.invalidAPIKey
        }
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7
        ]
        
        do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw OpenAIServiceError.invalidResponse("Failed to serialize request body: \(error.localizedDescription)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIServiceError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return openAIResponse.choices.first?.message.content ?? ""
                } catch {
                    throw OpenAIServiceError.invalidResponse("Failed to decode response: \(error.localizedDescription)")
                }
            case 401:
                throw OpenAIServiceError.invalidAPIKey
            case 429:
                throw OpenAIServiceError.rateLimitExceeded
            case 500...599:
                throw OpenAIServiceError.serverError(httpResponse.statusCode)
            default:
                throw OpenAIServiceError.unknownError("Unexpected status code: \(httpResponse.statusCode)")
            }
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            throw OpenAIServiceError.networkError
        }
    }
    
    // Intent detection helper
    func detectIntent(userMessage: String, systemPrompt: String) async throws -> Bool {
        let messages = [
            OpenAIChatMessage(role: "system", content: systemPrompt),
            OpenAIChatMessage(role: "user", content: userMessage)
        ]
        let response = try await generateResponse(messages: messages)
        return response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("yes")
        }
    
    // Universal intent detection
    func classifyIntent(userMessage: String) async throws -> String {
        let systemPrompt = "Classify the user's intent as one of: remedy, alternative, track, reminder, general, feedback, other. Respond only with the intent label."
        let messages = [
            OpenAIChatMessage(role: "system", content: systemPrompt),
            OpenAIChatMessage(role: "user", content: userMessage)
        ]
        let response = try await generateResponse(messages: messages)
        return response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// Response models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: OpenAIResponseMessage
}

struct OpenAIResponseMessage: Codable {
    let content: String
} 