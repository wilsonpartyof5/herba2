import Foundation

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let communityService = CommunityService()
    var currentUserId: String
    
    init(appState: AppState) {
        self.currentUserId = appState.currentUser?.id ?? ""
        Task {
            await loadPosts()
        }
    }
    
    func filteredPosts(for filter: PostFilter) -> [Post] {
        switch filter {
        case .all:
            return posts
        case .myPosts:
            return posts.filter { $0.userId == currentUserId }
        case .favorites:
            return posts.filter { $0.favoritedBy.contains(currentUserId) }
        }
    }
    
    func loadPosts() async {
        // Check if sample data is enabled
        if SampleData.isEnabled {
            let sampleData = SampleDataManager.shared.loadSampleData()
            posts = sampleData.posts
            return
        }
        
        // Fallback to Firebase
        do {
            posts = try await communityService.fetchPosts()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func createPost(_ post: Post) {
        Task {
            do {
                try await communityService.createPost(post)
                await loadPosts()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePost(_ post: Post) {
        Task {
            do {
                try await communityService.deletePost(post.id)
                await loadPosts()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleLike(_ post: Post) {
        // Optimistic UI update
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        var updatedPost = posts[index]
        let alreadyLiked = updatedPost.likedBy.contains(currentUserId)
        if alreadyLiked {
            updatedPost.likedBy.removeAll { $0 == currentUserId }
            updatedPost.likes -= 1
        } else {
            updatedPost.likedBy.append(currentUserId)
            updatedPost.likes += 1
        }
        posts[index] = updatedPost
        // Backend update
        Task {
            do {
                try await communityService.toggleLike(postId: post.id, userId: currentUserId)
                // Optionally reload from backend for consistency
                // await loadPosts()
            } catch {
                // Revert optimistic update
                var revertedPost = posts[index]
                if alreadyLiked {
                    revertedPost.likedBy.append(currentUserId)
                    revertedPost.likes += 1
                } else {
                    revertedPost.likedBy.removeAll { $0 == currentUserId }
                    revertedPost.likes -= 1
                }
                posts[index] = revertedPost
                showError = true
                errorMessage = "Failed to update like. Please try again."
            }
        }
    }
    
    func hasUserLikedPost(_ post: Post) -> Bool {
        post.likedBy.contains(currentUserId)
    }
    
    func addComment(_ comment: Comment) {
        Task {
            do {
                try await communityService.addComment(comment)
                await loadPosts()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await communityService.deleteComment(comment.id, postId: comment.postId)
                await loadPosts()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleFavorite(_ post: Post) {
        Task {
            do {
                try await communityService.toggleFavorite(postId: post.id, userId: currentUserId)
                await loadPosts()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func hasUserFavoritedPost(_ post: Post) -> Bool {
        post.favoritedBy.contains(currentUserId)
    }
} 