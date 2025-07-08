import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let authorName: String
    let content: String
    let tags: [String]
    var likes: Int
    var likedBy: [String] // Array of user IDs who liked the post
    var favoritedBy: [String] // Array of user IDs who favorited the post
    var comments: [Comment]
    let createdAt: Date
    let updatedAt: Date
}

struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let userId: String
    let authorName: String
    let content: String
    let createdAt: Date
}

// PostFilter for filtering posts in the community
enum PostFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case myPosts = "My Posts"
    case favorites = "Favorites"
    
    var id: String { rawValue }
}

// MARK: - Firebase Integration
extension Post {
    var firestoreData: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "authorName": authorName,
            "content": content,
            "tags": tags,
            "likes": likes,
            "likedBy": likedBy,
            "favoritedBy": favoritedBy,
            "comments": comments.map { $0.firestoreData },
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> Post? {
        guard
            let id = data["id"] as? String,
            let userId = data["userId"] as? String,
            let authorName = data["authorName"] as? String,
            let content = data["content"] as? String,
            let tags = data["tags"] as? [String],
            let likes = data["likes"] as? Int,
            let likedBy = data["likedBy"] as? [String],
            let favoritedBy = data["favoritedBy"] as? [String],
            let commentsData = data["comments"] as? [[String: Any]],
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        let comments = commentsData.compactMap { Comment.fromFirestore($0) }
        
        return Post(
            id: id,
            userId: userId,
            authorName: authorName,
            content: content,
            tags: tags,
            likes: likes,
            likedBy: likedBy,
            favoritedBy: favoritedBy,
            comments: comments,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Comment {
    var firestoreData: [String: Any] {
        [
            "id": id,
            "postId": postId,
            "userId": userId,
            "authorName": authorName,
            "content": content,
            "createdAt": createdAt
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> Comment? {
        guard
            let id = data["id"] as? String,
            let postId = data["postId"] as? String,
            let userId = data["userId"] as? String,
            let authorName = data["authorName"] as? String,
            let content = data["content"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        return Comment(
            id: id,
            postId: postId,
            userId: userId,
            authorName: authorName,
            content: content,
            createdAt: createdAt
        )
    }
} 