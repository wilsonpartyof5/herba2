import Foundation
import SwiftUI

@MainActor
class AIHerbalistViewModel: ObservableObject {
    private let service = AIHerbalistService()
    
    @Published var remedies: [HerbalRemedy] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchQuery = ""
    
    func getHerbalAdvice(for query: String) async {
        isLoading = true
        error = nil
        
        do {
            remedies = try await service.getHerbalAdvice(for: query)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func searchRemedies() async {
        guard !searchQuery.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            remedies = try await service.searchRemedies(query: searchQuery)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearResults() {
        remedies = []
        error = nil
        searchQuery = ""
    }
} 