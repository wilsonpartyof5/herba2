import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Herba2")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Profile Operations
    
    func saveProfile(_ profile: Profile) {
        let cdProfile = CDProfile(context: context)
        cdProfile.id = profile.id
        cdProfile.userId = profile.userId
        cdProfile.name = profile.name
        cdProfile.dateOfBirth = profile.dateOfBirth
        cdProfile.allergies = profile.allergies
        cdProfile.chronicConditions = profile.chronicConditions
        cdProfile.medications = profile.medications
        cdProfile.isPrimaryProfile = profile.isPrimaryProfile
        cdProfile.createdAt = profile.createdAt
        cdProfile.updatedAt = profile.updatedAt
        
        saveContext()
    }
    
    func fetchProfiles(for userId: String) -> [Profile] {
        let request: NSFetchRequest<CDProfile> = CDProfile.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let cdProfiles = try context.fetch(request)
            return cdProfiles.map { cdProfile in
                Profile(
                    id: cdProfile.id,
                    userId: cdProfile.userId ?? "",
                    name: cdProfile.name ?? "",
                    dateOfBirth: cdProfile.dateOfBirth ?? Date(),
                    allergies: cdProfile.allergies ?? [],
                    chronicConditions: cdProfile.chronicConditions ?? [],
                    medications: cdProfile.medications ?? [],
                    isPrimaryProfile: cdProfile.isPrimaryProfile,
                    createdAt: cdProfile.createdAt ?? Date(),
                    updatedAt: cdProfile.updatedAt ?? Date()
                )
            }
        } catch {
            print("Error fetching profiles: \(error)")
            return []
        }
    }
    
    // MARK: - Chat Message Operations
    
    func saveChatMessage(_ message: ChatMessage) {
        let cdMessage = CDChatMessage(context: context)
        cdMessage.id = message.id
        cdMessage.profileId = message.profileId
        cdMessage.role = message.role.rawValue
        cdMessage.text = message.text
        cdMessage.evidenceSnippets = message.evidenceSnippets
        cdMessage.preparationSteps = message.preparationSteps
        cdMessage.safetyDosage = message.safetyDosage
        cdMessage.freshnessDate = message.freshnessDate
        cdMessage.createdAt = message.createdAt
        
        saveContext()
    }
    
    func fetchChatMessages(for profileId: String) -> [ChatMessage] {
        let request: NSFetchRequest<CDChatMessage> = CDChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "profileId == %@", profileId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let cdMessages = try context.fetch(request)
            return cdMessages.compactMap { cdMessage in
                guard let role = ChatMessage.MessageRole(rawValue: cdMessage.role ?? "") else { return nil }
                
                return ChatMessage(
                    id: cdMessage.id,
                    profileId: cdMessage.profileId ?? "",
                    role: role,
                    text: cdMessage.text ?? "",
                    evidenceSnippets: cdMessage.evidenceSnippets,
                    preparationSteps: cdMessage.preparationSteps,
                    safetyDosage: cdMessage.safetyDosage,
                    freshnessDate: cdMessage.freshnessDate,
                    createdAt: cdMessage.createdAt ?? Date()
                )
            }
        } catch {
            print("Error fetching chat messages: \(error)")
            return []
        }
    }
} 