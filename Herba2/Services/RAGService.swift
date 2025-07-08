import Foundation

class RAGService {
    private var herbalKnowledge: [String: String] = [:]
    
    init() {
        loadHerbalKnowledge()
    }
    
    private func loadHerbalKnowledge() {
        // Load herbal knowledge from bundled resources
        if let path = Bundle.main.path(forResource: "herbal_knowledge", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let knowledge = try JSONDecoder().decode([String: String].self, from: data)
                self.herbalKnowledge = knowledge
            } catch {
                print("Error loading herbal knowledge: \(error)")
            }
        }
    }
    
    func getRelevantContext(for query: String) -> String {
        // Simple keyword matching for now
        // In a production environment, you'd want to use more sophisticated
        // semantic search or embedding-based retrieval
        var relevantContext = ""
        
        let keywords = query.lowercased().components(separatedBy: " ")
        
        for (key, value) in herbalKnowledge {
            if keywords.contains(where: { key.lowercased().contains($0) }) {
                relevantContext += value + "\n\n"
            }
        }
        
        return relevantContext.isEmpty ? "No specific herbal knowledge found for this query." : relevantContext
    }
    
    func addHerbalKnowledge(key: String, value: String) {
        herbalKnowledge[key] = value
    }
} 