import Foundation
import FirebaseFirestore

class CommunityService {
    private let db = Firestore.firestore()
    private let postsCollection = "posts"
    private let commentsCollection = "comments"
    
    // MARK: - Posts
    
    func createPost(_ post: Post) async throws {
        try await db.collection(postsCollection).document(post.id).setData(post.firestoreData)
    }
    
    func updatePost(_ post: Post) async throws {
        try await db.collection(postsCollection).document(post.id).setData(post.firestoreData)
    }
    
    func deletePost(_ postId: String) async throws {
        // Delete all comments for this post
        let commentsSnapshot = try await db.collection(commentsCollection)
            .whereField("postId", isEqualTo: postId)
            .getDocuments()
        
        for document in commentsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete the post
        try await db.collection(postsCollection).document(postId).delete()
    }
    
    func fetchPosts() async throws -> [Post] {
        let snapshot = try await db.collection(postsCollection)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Post.fromFirestore(document.data())
        }
    }
    
    func fetchUserPosts(userId: String) async throws -> [Post] {
        let snapshot = try await db.collection(postsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Post.fromFirestore(document.data())
        }
    }
    
    // MARK: - Likes
    
    func toggleLike(postId: String, userId: String) async throws {
        let postRef = db.collection(postsCollection).document(postId)
        let postDoc = try await postRef.getDocument()
        
        guard var post = Post.fromFirestore(postDoc.data() ?? [:]) else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        
        if post.likedBy.contains(userId) {
            // Unlike
            post.likedBy.removeAll { $0 == userId }
            post.likes -= 1
        } else {
            // Like
            post.likedBy.append(userId)
            post.likes += 1
        }
        
        try await updatePost(post)
    }
    
    func hasUserLikedPost(postId: String, userId: String) async throws -> Bool {
        let postDoc = try await db.collection(postsCollection).document(postId).getDocument()
        guard let post = Post.fromFirestore(postDoc.data() ?? [:]) else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        return post.likedBy.contains(userId)
    }
    
    // MARK: - Favorites
    func toggleFavorite(postId: String, userId: String) async throws {
        let postRef = db.collection(postsCollection).document(postId)
        let postDoc = try await postRef.getDocument()
        
        guard var post = Post.fromFirestore(postDoc.data() ?? [:]) else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        
        if post.favoritedBy.contains(userId) {
            // Unfavorite
            post.favoritedBy.removeAll { $0 == userId }
        } else {
            // Favorite
            post.favoritedBy.append(userId)
        }
        
        try await updatePost(post)
    }
    
    func hasUserFavoritedPost(postId: String, userId: String) async throws -> Bool {
        let postDoc = try await db.collection(postsCollection).document(postId).getDocument()
        guard let post = Post.fromFirestore(postDoc.data() ?? [:]) else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        return post.favoritedBy.contains(userId)
    }
    
    // MARK: - Comments
    
    func addComment(_ comment: Comment) async throws {
        // Add the comment to the comments collection
        try await db.collection(commentsCollection).document(comment.id).setData(comment.firestoreData)
        
        // Update the post's comments array
        let postRef = db.collection(postsCollection).document(comment.postId)
        try await postRef.updateData([
            "comments": FieldValue.arrayUnion([comment.firestoreData])
        ])
    }
    
    func deleteComment(_ commentId: String, postId: String) async throws {
        // Get the comment data before deleting
        let commentDoc = try await db.collection(commentsCollection).document(commentId).getDocument()
        guard let commentData = commentDoc.data() else { return }
        
        // Delete the comment from the comments collection
        try await db.collection(commentsCollection).document(commentId).delete()
        
        // Remove the comment from the post's comments array
        let postRef = db.collection(postsCollection).document(postId)
        try await postRef.updateData([
            "comments": FieldValue.arrayRemove([commentData])
        ])
    }
    
    func fetchComments(for postId: String) async throws -> [Comment] {
        let snapshot = try await db.collection(commentsCollection)
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Comment.fromFirestore(document.data())
        }
    }
} 