import Foundation

struct RemedyProgress: Identifiable, Codable {
    let id: UUID
    let remedyName: String
    let ailment: String
    let startDate: Date
    var isActive: Bool
    var dailyLogs: [RemedyLog]
    var reminderTime: DateComponents? // e.g., 8:00 AM
    
    init(remedyName: String, ailment: String, startDate: Date = Date(), isActive: Bool = true, dailyLogs: [RemedyLog] = [], reminderTime: DateComponents? = nil) {
        self.id = UUID()
        self.remedyName = remedyName
        self.ailment = ailment
        self.startDate = startDate
        self.isActive = isActive
        self.dailyLogs = dailyLogs
        self.reminderTime = reminderTime
    }
}

struct RemedyLog: Identifiable, Codable {
    let id: UUID
    let date: Date
    let note: String
    let symptomSeverity: Int? // 1-10 scale, optional
    
    init(date: Date = Date(), note: String, symptomSeverity: Int? = nil) {
        self.id = UUID()
        self.date = date
        self.note = note
        self.symptomSeverity = symptomSeverity
    }
} 