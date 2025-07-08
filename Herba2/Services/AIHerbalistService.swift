import Foundation

class AIHerbalistService {
    private let baseURL = "https://herba-ai-proxy.vercel.app" // Vercel deployment URL
    
    func getHerbalAdvice(for query: String) async throws -> [HerbalRemedy] {
        guard let url = URL(string: "\(baseURL)/advice") else {
            throw AIHerbalistError.invalidURL("Invalid URL for /advice")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["query": query]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AIHerbalistError.invalidResponse("Invalid HTTP response for /advice")
            }
            
            let remedies = try JSONDecoder().decode([HerbalRemedy].self, from: data)
            return remedies
        } catch let error as DecodingError {
            throw AIHerbalistError.decodingError(error)
        } catch {
            throw AIHerbalistError.apiError(error.localizedDescription)
        }
    }
    
    func searchRemedies(query: String) async throws -> [HerbalRemedy] {
        guard let url = URL(string: "\(baseURL)/search") else {
            throw AIHerbalistError.invalidURL("Invalid URL for /search")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["query": query]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AIHerbalistError.invalidResponse("Invalid HTTP response for /search")
            }
            
            let remedies = try JSONDecoder().decode([HerbalRemedy].self, from: data)
            return remedies
        } catch let error as DecodingError {
            throw AIHerbalistError.decodingError(error)
        } catch {
            throw AIHerbalistError.apiError(error.localizedDescription)
        }
    }
} 