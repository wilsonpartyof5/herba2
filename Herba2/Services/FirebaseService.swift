import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return User(
            id: result.user.uid,
            email: result.user.email ?? "",
            consented: true,
            createdAt: result.user.metadata.creationDate ?? Date(),
            updatedAt: Date()
        )
    }
    
    func signUp(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = User(
            id: result.user.uid,
            email: result.user.email ?? "",
            consented: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await saveUser(user)
        return user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - User Operations
    
    private func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.id!).setData(from: user)
    }
    
    func fetchUser(_ userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        return try document.data(as: User.self)
    }
    
    // MARK: - Profile Operations
    
    func saveProfile(_ profile: Profile) async throws {
        try db.collection("profiles").document(profile.id!).setData(from: profile)
    }
    
    func fetchProfiles(for userId: String) async throws -> [Profile] {
        let snapshot = try await db.collection("profiles")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Profile.self)
        }
    }
    
    // MARK: - Chat Operations
    
    func saveChatMessage(_ message: ChatMessage) async throws {
        try db.collection("chatLogs").document(message.id!).setData(from: message)
    }
    
    func fetchChatMessages(for profileId: String) async throws -> [ChatMessage] {
        let snapshot = try await db.collection("chatLogs")
            .whereField("profileId", isEqualTo: profileId)
            .order(by: "createdAt")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: ChatMessage.self)
        }
    }
    
    // MARK: - Community Operations
    
    func saveCommunityPost(_ post: Post) async throws {
        try db.collection("communityPosts").document(post.id).setData(from: post)
    }
    
    func fetchCommunityPosts() async throws -> [Post] {
        let snapshot = try await db.collection("communityPosts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Post.self)
        }
    }
    
    // MARK: - Remedy Progress Operations
    
    func saveRemedyProgress(_ progress: RemedyProgress, for userId: String) async throws {
        try db.collection("users").document(userId)
            .collection("remedyProgress").document(progress.id.uuidString)
            .setData(from: progress)
    }
    
    func fetchRemedyProgress(for userId: String) async throws -> [RemedyProgress] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("remedyProgress").getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: RemedyProgress.self)
        }
    }
    
    func updateRemedyProgress(_ progress: RemedyProgress, for userId: String) async throws {
        try await saveRemedyProgress(progress, for: userId)
    }
    
    func deleteRemedyProgress(_ progress: RemedyProgress, for userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("remedyProgress").document(progress.id.uuidString).delete()
    }
    
    // MARK: - Remedy Log Operations
    
    func saveRemedyLog(_ log: RemedyLog, for progressId: String, userId: String) async throws {
        try db.collection("users").document(userId)
            .collection("remedyProgress").document(progressId)
            .collection("logs").document(log.id.uuidString)
            .setData(from: log)
    }
    
    func fetchRemedyLogs(for progressId: String, userId: String) async throws -> [RemedyLog] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("remedyProgress").document(progressId)
            .collection("logs")
            .order(by: "date", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: RemedyLog.self)
        }
    }
    
    func deleteRemedyLog(_ log: RemedyLog, for progressId: String, userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("remedyProgress").document(progressId)
            .collection("logs").document(log.id.uuidString).delete()
    }
} 
 