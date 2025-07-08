import Foundation
import UserNotifications

class RemedyProgressViewModel: ObservableObject {
    @Published var activeRemedies: [RemedyProgress] = []
    private let storageKey = "activeRemedies"
    
    init() {
        load()
    }
    
    func addRemedy(_ remedyName: String, ailment: String, reminderTime: DateComponents? = nil) {
        let newRemedy = RemedyProgress(remedyName: remedyName, ailment: ailment, reminderTime: reminderTime)
        activeRemedies.append(newRemedy)
        save()
    }
    
    func logProgress(for remedyID: UUID, note: String, severity: Int?) {
        guard let idx = activeRemedies.firstIndex(where: { $0.id == remedyID }) else { return }
        let log = RemedyLog(note: note, symptomSeverity: severity)
        activeRemedies[idx].dailyLogs.append(log)
        save()
    }
    
    func completeRemedy(_ remedyID: UUID) {
        guard let idx = activeRemedies.firstIndex(where: { $0.id == remedyID }) else { return }
        activeRemedies[idx].isActive = false
        save()
    }
    
    func removeRemedy(_ remedyID: UUID) {
        activeRemedies.removeAll { $0.id == remedyID }
        save()
    }
    
    func setReminder(for remedyID: UUID, time: DateComponents) {
        guard let idx = activeRemedies.firstIndex(where: { $0.id == remedyID }) else { return }
        activeRemedies[idx].reminderTime = time
        save()
        scheduleNotification(for: activeRemedies[idx])
    }
    
    private func scheduleNotification(for remedy: RemedyProgress) {
        guard let time = remedy.reminderTime else { return }
        let content = UNMutableNotificationContent()
        content.title = "Remedy Reminder"
        content.body = "Don't forget your \(remedy.remedyName) today! Log your progress in the app."
        content.sound = .default
        var triggerDate = time
        triggerDate.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        let request = UNNotificationRequest(identifier: remedy.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeReminder(for remedyID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [remedyID.uuidString])
        if let idx = activeRemedies.firstIndex(where: { $0.id == remedyID }) {
            activeRemedies[idx].reminderTime = nil
            save()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(activeRemedies) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let remedies = try? JSONDecoder().decode([RemedyProgress].self, from: data) {
            self.activeRemedies = remedies
        }
    }
} 