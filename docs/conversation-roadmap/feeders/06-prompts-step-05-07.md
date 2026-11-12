# 06 — Prompts for Steps 5-7 (Claude Code)
(Originally written with the placeholder name "revline"; updated here to Wheeln.)

## STEP 5 — feed, posts, check-in
```
Build the social feed system for the Wheeln app.

1. /src/screens/FeedScreen.tsx
   - Fetches posts from Supabase (posts joined with users and locations)
   - Toggle at top: "Friends" / "Community" feed
   - Infinite scroll with pagination (20 posts per page)
   - Each post shows: user avatar, username, location name, location type badge, photo, message, star rating, difficulty rating, like count, comment count, timestamp
   - Pull to refresh

2. /src/components/PostCard.tsx
   - Full post card with all above fields
   - Heart button to like/unlike (optimistic update)
   - Comment button opens comment sheet
   - Location name is tappable and goes to LocationDetailScreen

3. /src/screens/CheckInScreen.tsx
   - Search or browse locations
   - Select a location
   - Take or upload a photo (expo-image-picker)
   - Write a message (optional)
   - Rate the experience (1-5 stars) and difficulty (1-5 stars)
   - Submit: uploads photo to Supabase Storage, creates post record
   - After submit, triggers badge check (useBadges hook)

4. /src/hooks/useFeed.ts — all Supabase queries for the feed

Dark theme: #0D0D0D background, #FF5A00 accent, #1A1A1A cards.
```

## STEP 6 — badge system
```
Build the badge system for the Wheeln app.

1. /src/constants/badges.ts — define:
   CHECK-IN MILESTONES: "First Timer" 1, "Regular" 10, "Veteran" 50, "Legend" 100, "Obsessed" 500 check-ins
   VARIETY: "Track Rat" 5 different tracks; "Dirt Dog" 5 different off-road locations; "Quarter Miler" 3 different drag strips; "Explorer" 10 different locations total
   SOCIAL: "Influencer" 50 likes received; "Community Builder" 25 friends
   EVENT BADGES: awarded via QR code scan, defined per event in the database

2. /src/hooks/useBadges.ts
   - checkAndAwardBadges(userId): after every check-in, compare user stats to thresholds and insert newly earned badges into user_badges
   - getUserBadges(userId)

3. /src/screens/BadgesScreen.tsx
   - Grid of all badges; earned = full color with earn date; unearned = grayscale/locked
   - Separate "Event" section for event badges

4. Badge icon component: hexagon shape, icon inside, name below, orange border when earned

Dark theme consistent with the rest of the app.
```
NOTE: the SQL migration restricts user_badges writes to the service role, so awarding badges from the client will be blocked by RLS. Award badges in a Supabase Edge Function or database trigger instead.

## STEP 7 — rankings and recommendations
```
Build the rankings and recommendations screens for the Wheeln app.

1. /src/screens/RankingsScreen.tsx with three tabs:
   - "Top Rated": locations by average star rating (min 3 check-ins)
   - "Most Challenging": by average difficulty rating
   - "Most Popular": by total check-in count
   Each entry: name, type badge, rating, check-in count, photo if available

2. Recommendations (HomeScreen or a feed card):
   - From the user's check-in history, find most-visited location types
   - Return 3 never-visited locations of those types with high ratings
   - Horizontal scroll cards with an "I want to go!" save button

3. /src/screens/LocationDetailScreen.tsx
   - Name, type, address/region, average rating and difficulty, total check-ins
   - Map view (react-native-maps) with pin
   - Gallery of recent post photos, recent posts filtered to this location
   - "Check In Here" button

All Supabase queries in /src/hooks/useLocation.ts
```
