import Foundation

// MARK: - Sample Data Generator
// This file contains sample data for testing the community feature
// To remove sample data later, simply delete this file and remove any references to it

struct SampleData {
    static var isEnabled = true // Set to false to disable sample data
    
    // Quick toggle for testing
    static func toggleSampleData() {
        isEnabled.toggle()
        print("Sample data \(isEnabled ? "enabled" : "disabled")")
    }
    
    // Sample user names for variety
    private static let sampleNames = [
        "Sarah Johnson", "Michael Chen", "Emma Rodriguez", "David Thompson", "Lisa Wang",
        "James Wilson", "Maria Garcia", "Robert Brown", "Jennifer Lee", "Christopher Davis",
        "Amanda Miller", "Daniel Martinez", "Jessica Taylor", "Matthew Anderson", "Ashley White",
        "Joshua Jackson", "Stephanie Harris", "Andrew Clark", "Nicole Lewis", "Kevin Hall",
        "Rachel Young", "Steven Allen", "Megan King", "Ryan Wright", "Lauren Scott",
        "Brandon Green", "Hannah Baker", "Tyler Adams", "Victoria Nelson", "Sean Carter",
        "Olivia Mitchell", "Nathan Perez", "Sophia Roberts", "Adam Turner", "Isabella Phillips",
        "Ethan Campbell", "Ava Parker", "Justin Evans", "Mia Edwards", "Austin Collins",
        "Chloe Stewart", "Cody Morris", "Zoe Rogers", "Dylan Reed", "Lily Cook",
        "Jordan Morgan", "Grace Bell", "Cameron Murphy", "Layla Bailey", "Hunter Rivera",
        "Riley Cooper", "Blake Richardson", "Nora Cox", "Hayden Howard", "Eva Ward",
        "Grayson Torres", "Brooklyn Peterson", "Lincoln Gray", "Savannah Ramirez", "Owen James",
        "Avery Watson", "Landon Brooks", "Ellie Kelly", "Roman Sanders", "Scarlett Price",
        "Easton Bennett", "Madison Wood", "Greyson Barnes", "Luna Ross", "Brayden Henderson",
        "Stella Coleman", "Kayden Jenkins", "Nova Perry", "Miles Powell", "Aria Long",
        "Sawyer Patterson", "Elliot Hughes", "Atlas Flores", "Skylar Butler", "Rhett Simmons",
        "Paisley Foster", "Beckett Gonzales", "Willow Bryant", "Oakley Alexander", "Violet Russell",
        "Weston Griffin", "Claire Diaz", "Sage Hayes", "Iris Sanders", "Knox Price",
        "Sage Bennett", "Atlas Wood", "Luna Barnes", "River Ross", "Phoenix Henderson",
        "Wren Coleman", "Jasper Jenkins", "Ivy Perry", "Felix Powell", "Daisy Long",
        "Finn Patterson", "Ruby Hughes", "Kai Flores", "Luna Butler", "Rowan Simmons"
    ]
    
    // Sample herbal topics and content
    private static let herbalTopics = [
        "Chamomile tea for better sleep",
        "Echinacea for immune support",
        "Lavender for stress relief",
        "Peppermint for digestion",
        "Ginger for nausea",
        "Turmeric for inflammation",
        "Aloe vera for skin care",
        "Eucalyptus for respiratory health",
        "Rosemary for memory",
        "Sage for sore throat",
        "Thyme for cough relief",
        "Calendula for wound healing",
        "St. John's Wort for mood",
        "Valerian root for anxiety",
        "Milk thistle for liver health",
        "Dandelion for detox",
        "Nettle for allergies",
        "Burdock root for skin",
        "Yarrow for bleeding",
        "Plantain for bug bites"
    ]
    
    private static let sampleTags = [
        "herbal-remedies", "natural-healing", "wellness", "holistic-health", "traditional-medicine",
        "immune-support", "sleep-aid", "stress-relief", "digestive-health", "skin-care",
        "respiratory-health", "pain-relief", "anxiety", "detox", "anti-inflammatory",
        "antioxidant", "adaptogen", "nervine", "carminative", "diaphoretic"
    ]
    
    private static let sampleComments = [
        "This really helped me with my sleep issues!",
        "I've been using this for years, great results.",
        "How long did it take to see results?",
        "Any side effects to watch out for?",
        "Where do you source your herbs?",
        "This is exactly what I needed, thank you!",
        "I'm going to try this tonight.",
        "Has anyone tried this with children?",
        "What's the best time of day to take this?",
        "I prefer organic sources for herbs.",
        "This worked wonders for my anxiety.",
        "How do you prepare this remedy?",
        "I've heard good things about this herb.",
        "Is this safe during pregnancy?",
        "What's the recommended dosage?",
        "I love the natural approach to healing.",
        "This is a great alternative to pharmaceuticals.",
        "How long can you safely use this?",
        "I'm excited to try this remedy!",
        "This is such valuable information, thank you!"
    ]
    
    // Generate sample users
    static func generateSampleUsers() -> [User] {
        guard isEnabled else { return [] }
        
        return (0..<100).map { index in
            let name = sampleNames[index % sampleNames.count]
            return User(
                id: "sample_user_\(index)",
                email: "user\(index)@example.com",
                displayName: name,
                consented: true,
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...7776000)), // Up to 90 days ago
                updatedAt: Date()
            )
        }
    }
    
    // Generate sample posts
    static func generateSamplePosts(users: [User]) -> [Post] {
        guard isEnabled else { return [] }
        
        return (0..<100).map { index in
            let user = users[index % users.count]
            let topic = herbalTopics[index % herbalTopics.count]
            let numTags = Int.random(in: 1...4)
            let tags = Array(sampleTags.shuffled().prefix(numTags))
            
            return Post(
                id: "sample_post_\(index)",
                userId: user.id ?? "unknown",
                authorName: user.displayName ?? "Anonymous",
                content: generatePostContent(topic: topic, index: index),
                tags: tags,
                likes: Int.random(in: 0...50),
                likedBy: generateLikedBy(users: users, maxLikes: 50),
                favoritedBy: generateFavoritedBy(users: users, maxFavorites: 20),
                comments: [], // Will be populated separately
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...2592000)), // Up to 30 days ago
                updatedAt: Date()
            )
        }
    }
    
    // Generate sample comments for posts
    static func generateSampleComments(posts: [Post], users: [User]) -> [Comment] {
        guard isEnabled else { return [] }
        
        var allComments: [Comment] = []
        
        for (postIndex, post) in posts.enumerated() {
            let numComments = Int.random(in: 0...8)
            
            for commentIndex in 0..<numComments {
                let user = users.randomElement() ?? users[0]
                let comment = Comment(
                    id: "sample_comment_\(postIndex)_\(commentIndex)",
                    postId: post.id,
                    userId: user.id ?? "unknown",
                    authorName: user.displayName ?? "Anonymous",
                    content: sampleComments.randomElement() ?? "Great post!",
                    createdAt: post.createdAt.addingTimeInterval(Double.random(in: 0...604800)) // Within a week of post
                )
                allComments.append(comment)
            }
        }
        
        return allComments
    }
    
    // Helper functions
    private static func generatePostContent(topic: String, index: Int) -> String {
        let templates = [
            "I've been using \(topic.lowercased()) for the past few weeks and the results have been amazing! Has anyone else tried this?",
            "Looking for advice on \(topic.lowercased()). What's your experience with this remedy?",
            "Just discovered \(topic.lowercased()) and I'm wondering about the best way to prepare it. Any tips?",
            "\(topic) has been a game-changer for me. Here's what I learned about using it effectively.",
            "Does anyone have experience with \(topic.lowercased())? I'm considering trying it for my health issues.",
            "I've been researching \(topic.lowercased()) and found some interesting information. What do you think?",
            "\(topic) seems to be working well for me. How long should I continue using it?",
            "Looking for natural alternatives and came across \(topic.lowercased()). Any recommendations?",
            "I'm new to herbal remedies and \(topic.lowercased()) caught my attention. Where should I start?",
            "Has anyone compared \(topic.lowercased()) with other natural remedies? I'd love to hear your thoughts."
        ]
        
        return templates[index % templates.count]
    }
    
    private static func generateLikedBy(users: [User], maxLikes: Int) -> [String] {
        let numLikes = Int.random(in: 0...maxLikes)
        return Array(users.shuffled().prefix(numLikes).compactMap { $0.id })
    }
    
    private static func generateFavoritedBy(users: [User], maxFavorites: Int) -> [String] {
        let numFavorites = Int.random(in: 0...maxFavorites)
        return Array(users.shuffled().prefix(numFavorites).compactMap { $0.id })
    }
}

// MARK: - Sample Data Manager
class SampleDataManager {
    static let shared = SampleDataManager()
    
    private init() {}
    
    func loadSampleData() -> (users: [User], posts: [Post], comments: [Comment]) {
        let users = SampleData.generateSampleUsers()
        let posts = SampleData.generateSamplePosts(users: users)
        let comments = SampleData.generateSampleComments(posts: posts, users: users)
        
        // Attach comments to posts
        var postsWithComments = posts
        for comment in comments {
            if let postIndex = postsWithComments.firstIndex(where: { $0.id == comment.postId }) {
                postsWithComments[postIndex].comments.append(comment)
            }
        }
        
        return (users: users, posts: postsWithComments, comments: comments)
    }
    
    func clearSampleData() {
        // This function can be called to clear sample data
        // In a real implementation, you would clear from your data source
        print("Sample data cleared")
    }
} 