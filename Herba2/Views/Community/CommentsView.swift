import SwiftUI

struct CommentsView: View {
    let post: Post
    @ObservedObject var viewModel: CommunityViewModel
    @EnvironmentObject private var appState: AppState
    @State private var newComment = ""
    @State private var commentToDelete: Comment?
    @State private var showingDeleteConfirmation = false
    
    init(post: Post, viewModel: CommunityViewModel) {
        self.post = post
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Original post
                PostRow(post: post, viewModel: viewModel)
                    .padding()
                    .background(AppTheme.Styles.cardBackground)
                
                Divider()
                
                // Comments list
                List {
                    ForEach(post.comments) { comment in
                        CommentRow(comment: comment, viewModel: viewModel, onDelete: {
                            commentToDelete = comment
                            showingDeleteConfirmation = true
                        })
                    }
                }
                
                // New comment input
                VStack {
                    Divider()
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .appInputStyle()
                        
                        Button {
                            if let user = appState.currentUser {
                                let comment = Comment(
                                    id: UUID().uuidString,
                                    postId: post.id,
                                    userId: user.id ?? "",
                                    authorName: user.displayName ?? "Anonymous",
                                    content: newComment,
                                    createdAt: Date()
                                )
                                viewModel.addComment(comment)
                                newComment = ""
                            } else {
                                // Show error if not logged in
                                // You can add an error state if desired
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(newComment.isEmpty ? AppTheme.colors.lightText : AppTheme.colors.sageGreen)
                        }
                        .disabled(newComment.isEmpty)
                    }
                    .padding()
                }
                .background(AppTheme.Styles.cardBackground)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Delete Comment", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    commentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let comment = commentToDelete {
                        viewModel.deleteComment(comment)
                    }
                    commentToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this comment? This action cannot be undone.")
            }
            .background(AppTheme.colors.background)
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let viewModel: CommunityViewModel
    let onDelete: () -> Void
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.authorName)
                    .appHeadline()
                Spacer()
                Text(comment.createdAt.formatted())
                    .appCaption()
                if comment.userId == appState.currentUser?.id {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            Text(comment.content)
                .appBody()
        }
        .padding(.vertical, 4)
    }
}

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let post: Post
    
    init(post: Post) {
        self.post = post
        self.comments = post.comments
        Task {
            await loadComments()
        }
    }
    
    @MainActor
    func loadComments() async {
        // TODO: Implement Firebase fetch
        // For now, just use the comments from the post
        comments = post.comments
    }
    
    func addComment(_ comment: Comment) {
        comments.append(comment)
        // TODO: Implement Firebase save
    }
    
    func deleteComment(_ comment: Comment) {
        comments.removeAll { $0.id == comment.id }
        // TODO: Implement Firebase delete
    }
}

#Preview {
    CommentsView(post: Post(
        id: "preview",
        userId: "user1",
        authorName: "John Doe",
        content: "This is a preview post",
        tags: ["herbs", "health"],
        likes: 5,
        likedBy: [],
        favoritedBy: [],
        comments: [
            Comment(
                id: "comment1",
                postId: "preview",
                userId: "user2",
                authorName: "Jane Smith",
                content: "Great post!",
                createdAt: Date()
            )
        ],
        createdAt: Date(),
        updatedAt: Date()
    ), viewModel: CommunityViewModel(appState: AppState()))
} 