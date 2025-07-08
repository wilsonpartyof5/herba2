import Foundation
import FirebaseFirestore

struct Profile: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    var name: String
    var dateOfBirth: Date
    var allergies: [String]
    var chronicConditions: [String]
    var medications: [String]
    var isPrimaryProfile: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case dateOfBirth
        case allergies
        case chronicConditions
        case medications
        case isPrimaryProfile
        case createdAt
        case updatedAt
    }
} 