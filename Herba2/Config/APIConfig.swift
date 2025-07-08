import Foundation

struct APIConfig {
    // Load API key from environment or configuration file
    static var openAIKey: String {
        // First try to get from environment variable
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        
        // Then try to get from configuration file
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["OpenAIAPIKey"] as? String {
            return key
        }
        
        // Return empty string if not found (you should handle this case in your app)
        return ""
    }
    
    static let baseURL = "https://api.openai.com/v1"
} 