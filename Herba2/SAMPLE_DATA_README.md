# Sample Data for Community Feature

This document explains how to use and remove the sample data feature for testing the community functionality.

## What's Included

The sample data includes:
- **100 sample users** with realistic names
- **100 sample posts** about herbal remedies and natural healing
- **Random comments** (0-8 per post) with engaging content
- **Realistic engagement** with likes and favorites
- **Herbal-themed content** relevant to the app's purpose

## How to Use

### Enable/Disable Sample Data
1. **Toggle via code**: Set `SampleData.isEnabled = false` in `SampleData.swift`
2. **Toggle via UI**: Long press (2 seconds) on the "Community" navigation title
3. **Runtime toggle**: Call `SampleData.toggleSampleData()` from anywhere

### Sample Data Features
- Posts are created with realistic timestamps (up to 30 days ago)
- Users have varied engagement levels (0-50 likes, 0-20 favorites)
- Content focuses on herbal remedies and natural healing
- Tags are relevant to the herbal/wellness community
- Comments are engaging and realistic

## File Structure

```
Herba2/Models/SampleData.swift          # Main sample data generator
Herba2/ViewModels/CommunityViewModel.swift  # Integration point
Herba2/Views/Community/CommunityView.swift  # UI toggle (long press)
```

## How to Remove Sample Data

When you're ready to remove sample data and use only Firebase:

### Option 1: Quick Disable
1. Set `SampleData.isEnabled = false` in `SampleData.swift`
2. The app will automatically use Firebase data instead

### Option 2: Complete Removal
1. Delete `Herba2/Models/SampleData.swift`
2. Remove the sample data integration from `CommunityViewModel.swift`:
   ```swift
   // Remove these lines from loadPosts():
   if SampleData.isEnabled {
       let sampleData = SampleDataManager.shared.loadSampleData()
       posts = sampleData.posts
       return
   }
   ```
3. Remove the long press gesture from `CommunityView.swift`:
   ```swift
   // Remove this block:
   .onLongPressGesture(minimumDuration: 2) {
       SampleData.toggleSampleData()
       Task {
           await viewModel.loadPosts()
       }
   }
   ```
4. Delete this README file

### Option 3: Gradual Migration
1. Set `SampleData.isEnabled = false`
2. Test with Firebase data
3. Once confirmed working, follow Option 2 for complete removal

## Sample Data Content

### Users
- 100 users with realistic names
- Created dates spread over 90 days
- All users have consented to data usage

### Posts
- Topics: Chamomile, Echinacea, Lavender, Peppermint, Ginger, etc.
- Content templates that feel natural and engaging
- 1-4 relevant tags per post
- Realistic engagement metrics

### Comments
- 20 different comment templates
- Realistic questions and responses
- Timestamps within a week of post creation

## Testing Scenarios

The sample data supports testing:
- ✅ Post filtering (All, My Posts, Favorites)
- ✅ Post sorting (Newest, Oldest, Most Liked)
- ✅ Like/unlike functionality
- ✅ Favorite/unfavorite functionality
- ✅ Comment viewing and interaction
- ✅ User's own posts highlighting
- ✅ Empty states (when filtering)
- ✅ Loading states
- ✅ Error handling

## Notes

- Sample data is completely separate from Firebase
- No risk of sample data appearing in production
- Easy to toggle for development vs testing
- Content is relevant to herbal/wellness community
- Realistic engagement patterns for testing UI states 