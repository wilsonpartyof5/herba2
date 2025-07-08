import SwiftUI

struct NewPostView: View {
    let onSave: (Post) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .appInputStyle()
                }
                
                Section("Tags") {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .appBody()
                    }
                    .onDelete { indexSet in
                        tags.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add Tag", text: $newTag)
                            .appInputStyle()
                        Button("Add") {
                            let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedTag.isEmpty && trimmedTag.count <= 30 && !tags.contains(trimmedTag) {
                                tags.append(trimmedTag)
                                newTag = ""
                            } else if trimmedTag.count > 30 {
                                showingError = true
                                errorMessage = "Tag cannot exceed 30 characters."
                            } else if tags.contains(trimmedTag) {
                                showingError = true
                                errorMessage = "Tag already added."
                            }
                        }
                        .appButtonStyle()
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.colors.sageGreen)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        savePost()
                    }
                    .foregroundColor(AppTheme.colors.sageGreen)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || content.count > 500)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .background(AppTheme.colors.background)
        }
    }
    
    private func savePost() {
        guard let user = appState.currentUser else {
            showingError = true
            errorMessage = "You must be logged in to create a post"
            return
        }
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            showingError = true
            errorMessage = "Post content cannot be empty."
            return
        }
        guard trimmedContent.count <= 500 else {
            showingError = true
            errorMessage = "Post content cannot exceed 500 characters."
            return
        }
        let post = Post(
            id: UUID().uuidString,
            userId: user.id ?? "",
            authorName: user.displayName ?? "Anonymous",
            content: trimmedContent,
            tags: tags,
            likes: 0,
            likedBy: [],
            favoritedBy: [],
            comments: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        onSave(post)
        dismiss()
    }
}

#Preview {
    NewPostView { _ in }
        .environmentObject(AppState())
} 