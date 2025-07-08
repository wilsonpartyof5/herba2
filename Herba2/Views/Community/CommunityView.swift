import SwiftUI

struct CommunityView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: CommunityViewModel
    @State private var showingNewPostSheet = false
    @State private var selectedFilter: PostFilter = .all
    @State private var selectedSort: PostSort = .newest
    @State private var postToDelete: Post?
    @State private var showingDeleteConfirmation = false
    
    init() {
        _viewModel = StateObject(wrappedValue: CommunityViewModel(appState: AppState()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(PostFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .background(AppTheme.Styles.cardBackground)
                // Sort picker
                Picker("Sort", selection: $selectedSort) {
                    ForEach(PostSort.allCases) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .bottom])
                .background(AppTheme.Styles.cardBackground)
                // Posts list with loading, empty, and error states
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading posts...")
                        .padding()
                    Spacer()
                } else if viewModel.showError {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Failed to load posts.")
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task { await viewModel.loadPosts() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else if viewModel.filteredPosts(for: selectedFilter).isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "leaf")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.colors.sageGreen)
                        Text("No posts yet. Be the first to share!")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    PostsListView(
                        posts: sortedPosts,
                        viewModel: viewModel,
                        onDelete: { post in
                            postToDelete = post
                            showingDeleteConfirmation = true
                        },
                        onRefresh: {
                            await viewModel.loadPosts()
                        }
                    )
                }
            }
            .navigationTitle("Community")
            .onLongPressGesture(minimumDuration: 2) {
                // Developer option: long press to toggle sample data
                SampleData.toggleSampleData()
                Task {
                    await viewModel.loadPosts()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewPostSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppTheme.colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingNewPostSheet) {
                NewPostView { post in
                    viewModel.createPost(post)
                }
            }
            .background(AppTheme.colors.background)
            .alert("Delete Post", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    postToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let post = postToDelete {
                        viewModel.deletePost(post)
                    }
                    postToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
        }
        .onAppear {
            // Update viewModel with latest appState
            viewModel.currentUserId = appState.currentUser?.id ?? ""
        }
    }
    
    // Sorting logic
    private var sortedPosts: [Post] {
        let posts = viewModel.filteredPosts(for: selectedFilter)
        switch selectedSort {
        case .newest:
            return posts.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return posts.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            return posts.sorted { $0.likes > $1.likes }
        }
    }
}

struct PostRow: View {
    let post: Post
    @ObservedObject var viewModel: CommunityViewModel
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack {
                Text(post.authorName)
                    .appHeadline()
                Spacer()
                Text(post.createdAt.formatted())
                    .appCaption()
            }
            
            // Post content
            Text(post.content)
                .appBody()
            
            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(post.tags, id: \.self) { tag in
                            Text(tag)
                                .appCaption()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.colors.sageGreen.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Interaction buttons
            HStack {
                Button {
                    viewModel.toggleLike(post)
                } label: {
                    Label("\(post.likes)", systemImage: viewModel.hasUserLikedPost(post) ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.hasUserLikedPost(post) ? .red : AppTheme.colors.accent)
                }
                
                Button {
                    viewModel.toggleFavorite(post)
                } label: {
                    Image(systemName: viewModel.hasUserFavoritedPost(post) ? "star.fill" : "star")
                        .foregroundColor(viewModel.hasUserFavoritedPost(post) ? .yellow : AppTheme.colors.accent)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                Button {
                    showingComments = true
                } label: {
                    Label("\(post.comments.count)", systemImage: "bubble.right")
                        .foregroundColor(AppTheme.colors.accent)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingComments) {
            CommentsView(post: post, viewModel: viewModel)
        }
    }
}

// Container for PostRow with background and swipe actions
struct PostRowContainer: View {
    let post: Post
    @ObservedObject var viewModel: CommunityViewModel
    let onDelete: () -> Void
    
    var body: some View {
        PostRow(post: post, viewModel: viewModel)
            .listRowBackground(
                post.userId == viewModel.currentUserId ? AppTheme.colors.sageGreen.opacity(0.15) : Color.clear
            )
            .swipeActions {
                if post.userId == viewModel.currentUserId {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}

private struct PostsListView: View {
    let posts: [Post]
    let viewModel: CommunityViewModel
    let onDelete: (Post) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            ForEach(posts) { post in
                PostRowContainer(
                    post: post,
                    viewModel: viewModel,
                    onDelete: { onDelete(post) }
                )
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}

#Preview {
    CommunityView()
}

// Sorting options for posts
enum PostSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case mostLiked = "Most Liked"
    var id: String { rawValue }
} 