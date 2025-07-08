import Foundation

class AIService {
    static let shared = AIService()
    private let baseURL = "https://herba-ai-proxy.vercel.app"
    
    private init() {}
    
    struct HerbalistResponse: Codable {
        let advice: String
        let evidenceSnippets: [String]
        let preparationSteps: String
        let safetyDosage: String
        let freshnessDate: Date
        let followUpQuestions: [String]?
    }
    
    func getHerbalistResponse(
        query: String,
        profile: Profile
    ) async throws -> HerbalistResponse {
        guard let url = URL(string: "\(baseURL)/getHerbalistResponse") else {
            throw AIHerbalistError.invalidURL("\(baseURL)/getHerbalistResponse")
        }
        
        let requestBody: [String: Any] = [
            "query": query,
            "profile": [
                "id": profile.id ?? "",
                "name": profile.name,
                "allergies": profile.allergies,
                "chronicConditions": profile.chronicConditions,
                "medications": profile.medications
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIHerbalistError.invalidResponse("Failed to serialize request body: \(error.localizedDescription)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
        
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIHerbalistError.networkError("Invalid HTTP response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
        return try JSONDecoder().decode(HerbalistResponse.self, from: data)
                } catch let error as DecodingError {
                    throw AIHerbalistError.decodingError(error)
                } catch {
                    throw AIHerbalistError.invalidResponse("Failed to decode response: \(error.localizedDescription)")
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
        } catch let error as AIHerbalistError {
            throw error
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            throw AIHerbalistError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Medical Disclaimer
    
    static let medicalDisclaimer = """
    Important: The information provided by Herba is for educational purposes only and is not intended to diagnose, treat, cure, or prevent any disease. Always consult with a qualified healthcare professional before starting any new treatment or if you have any questions about your health. In case of emergency, call your local emergency services immediately.
    """
} 