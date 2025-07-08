import Foundation

/// Error type for general AI Herbalist operations
public enum AIHerbalistError: LocalizedError {
    case invalidURL(String)
    case invalidResponse(String)
    case decodingError(DecodingError)
    case apiError(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL configuration: \(url)"
        case .invalidResponse(let details):
            return "Invalid response: \(details)"
        case .decodingError(let error):
            return "Error decoding response: \(error.localizedDescription)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let details):
            return "Network Error: \(details)"
        }
    }
}

/// Error type specifically for OpenAI service operations
public enum OpenAIServiceError: LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case networkError
    case invalidResponse(String)
    case serverError(Int)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your configuration."
        case .rateLimitExceeded:
            return "OpenAI rate limit exceeded. Please try again in a moment."
        case .networkError:
            return "Network error connecting to OpenAI. Please check your internet connection."
        case .invalidResponse(let details):
            return "Invalid response from OpenAI: \(details)"
        case .serverError(let code):
            return "OpenAI server error (HTTP \(code)). Please try again later."
        case .unknownError(let message):
            return "Unknown OpenAI error: \(message)"
        }
    }
} 