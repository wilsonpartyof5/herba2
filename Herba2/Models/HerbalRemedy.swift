import Foundation

struct HerbalRemedy: Identifiable, Codable {
    let id: UUID
    let name: String
    let properties: [String]
    let uses: [String]
    let preparationMethods: [String]
    let cautions: [String]?
    let description: String
    
    init(id: UUID = UUID(), name: String, properties: [String], uses: [String], preparationMethods: [String], cautions: [String]? = nil, description: String) {
        self.id = id
        self.name = name
        self.properties = properties
        self.uses = uses
        self.preparationMethods = preparationMethods
        self.cautions = cautions
        self.description = description
    }
}

// MARK: - Sample Data
extension HerbalRemedy {
    static let sampleRemedies = [
        HerbalRemedy(
            name: "Chamomile",
            properties: ["Calming", "Anti-inflammatory", "Antispasmodic"],
            uses: ["Sleep aid", "Digestive support", "Stress relief"],
            preparationMethods: ["Tea", "Tincture", "Essential oil"],
            cautions: ["May cause allergic reactions in some people"],
            description: "A gentle herb known for its calming properties and ability to support restful sleep."
        ),
        HerbalRemedy(
            name: "Echinacea",
            properties: ["Immune-stimulating", "Antiviral", "Anti-inflammatory"],
            uses: ["Immune support", "Cold and flu prevention", "Wound healing"],
            preparationMethods: ["Tincture", "Tea", "Capsules"],
            cautions: ["Not recommended for long-term use"],
            description: "A powerful immune-supporting herb traditionally used to prevent and treat colds and infections."
        )
    ]
} 