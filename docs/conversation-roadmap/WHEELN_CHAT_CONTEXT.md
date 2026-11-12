# Wheeln — Full Planning Conversation Context

_Saved 2026-11-12. Master file combining everything from the Wheeln planning chat: the idea, clarifying answers, decisions, phased plan, every paste-ready prompt (Steps 1-10), verification steps, and open items. The same content is split into `feeders/` for feeding into Claude Code or Cowork one piece at a time._

## Conversation timeline
1. Founder described the app idea and asked for clarifying questions plus a multi-tool plan (Claude Cowork + Claude Code) with paste-in prompts.
2. Clarifying questions asked and answered (platforms, communities, budget, location data, payments, technical level, team, monetization, future communities).
3. Assistant produced a 10-step roadmap (stack, phases, prompts, accounts) under the placeholder name RevLine.
4. Founder named the app **Wheeln**; identifiers updated.
5. Founder requested and received the Step 1 prompt, then Step 2. Supabase SQL ran successfully; table validation advised.
6. Step 3 (scaffold) and Step 4 (auth) prompts delivered; auth verification steps given.
7. Founder asked "what terminal?" — answer: Claude Code runs commands in its own built-in terminal.
8. Founder asked for all context as a markdown file plus feeder files saved on this computer (this folder).

## Feeder file index
| File | Contents |
|---|---|
| feeders/01-vision-and-decisions.md | Idea, Q&A, naming, decisions |
| feeders/02-tech-stack-and-accounts.md | Stack, accounts, costs, env vars |
| feeders/03-phased-plan-and-tool-map.md | Phases and which tool runs each step |
| feeders/04-prompts-step-01-02.md | Step 1 and 2 prompts |
| feeders/05-prompts-step-03-04.md | Step 3 and 4 prompts |
| feeders/06-prompts-step-05-07.md | Step 5-7 prompts |
| feeders/07-prompts-step-08-10.md | Step 8-10 prompts |
| feeders/08-step4-verification-checklist.md | Auth test checklist |
| feeders/09-progress-and-open-items.md | Status and open items |

---


# 01 — Vision, Clarifying Answers, Decisions

## The idea (founder's original description)
A community app for the on-road and off-road community. Users check in at tracks, road courses, drag strips and off-road park trails; post a message and picture; rate how much they liked it and how tough it was. Others like and comment. Rankings of favorite places and most challenging places; three recommended places to check out per user. Friends feed (focused) or random community feed.

**Organizer sales portal:** event organizers pick a sized package from a menu and get a QR code emailed so attendees can check in at the event; custom badge shows on the user's profile at check-in. Packages start at $100 for the badge; a higher package adds merchandise branded with the event badge and QR code. Architecture must integrate with a third-party platform for order fulfillment and shipping, and must handle payment.

**Monetization:** revenue-generating ads from a paying third party on the free version; $1/month to remove ads.

**Badges:** users accumulate badges at certain check-in volumes and frequencies.

**Goal:** a path to getting the app downloadable in the app stores so people can start joining. Tools: Claude Cowork and Claude Code.

## Clarifying questions and the founder's answers
| Question | Answer |
|---|---|
| Launch platforms | iOS and Android simultaneously |
| Launch communities | On-road track/autocross, Off-road trails and parks, Drag racing |
| Initial budget | Under $10K (indie/solo) |
| Location data | Admin-curated list to start, then user submissions |
| Payments / fulfillment platforms | Needs full recommendations for both |
| Technical background | Non-technical, relies heavily on AI tools |
| Team | Solo founder |
| Monetization priority | Free with ads; $1/mo removes ads (as described) |
| Future communities | Gravel/adventure riding, rock crawling/overlanding, karting, moto track days, SxS, drag and drive, car shows, Cars and Coffee, off-road parks |

## Naming
- Placeholder "RevLine" was used first. **Final name: Wheeln.**
- iOS bundle ID and Android package: `com.wheeln.app`
- Project folder / Expo name: `wheeln`
- Organizer portal headline: "Wheeln for Organizers"; Vercel project `wheeln-organizers`; Supabase project `wheeln`
- Suggested: check wheeln.com and @wheeln on Instagram/TikTok; check trademark/App Store availability.

## Decisions made by the assistant (founder did not specify these)
- Tech stack (see file 02).
- Organizer packages beyond the $100 starter: Pro $250 and Elite $500 were PROPOSED, not specified by the founder. Revisit pricing.
- Badge ladder (1/10/50/100/500 check-ins; variety and social badges) was proposed.
- Dark theme: background #0D0D0D, accent orange #FF5A00, cards #1A1A1A.
- Build order: organizer portal can be built early to sell packages before app launch.


---


# 02 — Tech Stack and Accounts

| Layer | Tool | Why |
|---|---|---|
| Mobile app | React Native (Expo) | One codebase for iOS and Android |
| Backend / DB | Supabase | Free tier, auth, storage, row-level security |
| Auth | Supabase Auth | Email, Google, Apple sign-in |
| Image storage | Supabase Storage | Same backend |
| Payments | Stripe | Organizer packages |
| Subscriptions | RevenueCat | $1/mo ad-free across iOS and Android |
| Ads | Google AdMob | Banner and interstitial for free users |
| Transactional email | Resend | QR code and badge delivery (SendGrid alternative) |
| Merch fulfillment | Printful API | Print-on-demand and shipping |
| QR codes | qrcode library | Free, open source |
| Organizer portal | Next.js on Vercel | Free hosting tier |
| App store builds | Expo EAS Build | iOS and Android builds and submission |

## Accounts to create
| Service | Cost |
|---|---|
| Supabase | Free tier |
| Expo / EAS | Free tier (build limits) |
| Apple Developer Program | $99/yr |
| Google Play Console | $25 one time |
| Stripe | Per-transaction fee |
| RevenueCat | Free up to a revenue threshold |
| Google AdMob | Free |
| Printful | Per-order cost |
| Resend | Free tier |
| Vercel | Free tier |

Upfront cost estimate in the plan: about $124 (Apple + Google). Infra about $0-$30/mo at launch. **Re-check all prices on each vendor's site before budgeting.**

## Env vars (Expo app, `.env`)
EXPO_PUBLIC_SUPABASE_URL, EXPO_PUBLIC_SUPABASE_ANON_KEY, EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY, EXPO_PUBLIC_REVENUECAT_API_KEY, EXPO_PUBLIC_ADMOB_APP_ID


---


# 03 — Phased Plan and Tool Map

## Phases
1. Foundation and MVP (weeks 1-6): check-ins, posts, feed, profiles
2. Community and badges (weeks 7-10): friends, likes, comments, badges, rankings
3. Organizer sales portal (weeks 11-14): packages, Stripe, QR codes, badge email
4. Monetization (weeks 15-17): AdMob, RevenueCat $1/mo
5. App store launch (weeks 18-20): TestFlight, Play beta, public launch

## Steps and which tool runs each
| Step | Tool | Output |
|---|---|---|
| 1 | Claude.ai chat | PRD, DB schema, project structure, services list, MVP list, accounts list |
| 2 | Claude.ai chat (same chat as 1) | Supabase SQL migration |
| 3 | Claude Code | Expo project scaffold and dependencies |
| 4 | Claude Code | Auth flow (login, signup, session) |
| 5 | Claude Code | Feed, posts, check-in |
| 6 | Claude Code | Badge system |
| 7 | Claude Code | Rankings, recommendations, location detail |
| 8 | Claude Code + Cowork | Organizer portal, Stripe, QR, email, Printful |
| 9 | Claude Code | AdMob and RevenueCat |
| 10 | Cowork | EAS builds, store submission |

Tip: Step 8 can run early so event packages are sold while the app is still being built.


---


# 04 — Prompts for Steps 1 and 2 (Claude.ai chat)

## STEP 1 — paste into a NEW Claude.ai chat
```
I am a solo non-technical founder building a mobile app called Wheeln. It is a social check-in community app for motorsport and off-road enthusiasts. Here is the full feature set:

CORE FEATURES:
- Users create accounts and profiles
- Admin-curated database of tracks, trails, drag strips, off-road parks, car shows — users can submit new locations for admin approval
- Users check in at locations, post a photo, write a message, rate the experience (1–5 stars) and rate difficulty (1–5)
- Social feed showing posts from friends or random community members (toggle)
- Likes and comments on posts
- Badge system: users earn badges for check-in milestones and frequency
- Rankings: top-rated places, most challenging places
- 3 AI-powered location recommendations per user based on their check-in history
- Friends system: add friends to filter feed

TARGET COMMUNITIES AT LAUNCH:
- On-road track days and autocross
- Off-road trails and parks
- Drag racing

FUTURE COMMUNITY PHASES:
- Overlanding and SxS
- Drag-and-drive events
- Karting
- Motorcycle track days
- Gravel and adventure riding
- Rock crawling
- Car shows, Cars & Coffee

ORGANIZER SALES PORTAL:
- Event organizers visit a web portal to purchase packages
- Package 1 — Starter ($100): custom event badge + unique QR code emailed to organizer
- Package 2 — Pro ($250): badge + QR code + 25 branded merchandise items (shirts, stickers) fulfilled via Printful
- Package 3 — Elite ($500): everything in Pro + premium badge animation + featured placement in app feed
- When attendees scan the QR code at an event, they receive a special check-in with the event badge displayed permanently on their profile
- Badges are auto-generated from a template using the event name and uploaded logo

MONETIZATION:
- Free users see banner and interstitial ads via Google AdMob
- $1/month subscription via RevenueCat removes all ads
- Organizer package purchases handled via Stripe

TECH STACK:
- React Native with Expo (iOS + Android from one codebase)
- Supabase (database, auth, image storage)
- Stripe (payments)
- RevenueCat (subscription management)
- Google AdMob (ads)
- Printful API (merch fulfillment)
- Resend (transactional email for QR code and badge delivery)
- Vercel (organizer web portal hosting)
- Expo EAS Build (app store builds)

APP IDENTIFIERS:
- App name: Wheeln
- iOS Bundle ID: com.wheeln.app
- Android package name: com.wheeln.app

Please produce all of the following:

1. A full Product Requirements Document (PRD) covering every feature in detail — user stories, acceptance criteria, edge cases
2. A complete Supabase database schema — every table, every field with data types, all foreign key relationships, and notes on indexes needed
3. A full folder and file structure for the React Native Expo project
4. A list of every third-party API and service needed, what each one does in the app, and a link to their documentation
5. A prioritized MVP feature list — what must be working on day 1 for launch versus what ships in phase 2
6. A list of every account I need to create before development begins, with any associated costs
```

## STEP 2 — paste into the SAME chat after Step 1 finishes
```
Based on the database schema you just created, write the complete SQL migration script I can paste directly into the Supabase SQL editor to create all tables, relationships, indexes, and row-level security (RLS) policies.

Include all of the following tables:

USERS & AUTH:
- users (id, email, username, display_name, avatar_url, bio, subscription_status, total_checkins, created_at)

LOCATIONS:
- locations (id, name, type, description, address, city, state, latitude, longitude, cover_photo_url, avg_rating, avg_difficulty, total_checkins, submitted_by_user_id, admin_approved, created_at)
- location_types should support: track, autocross, drag_strip, off_road_trail, off_road_park, car_show, overlanding, karting, moto_track, gravel_ride, rock_crawl, cars_and_coffee, other

POSTS & SOCIAL:
- posts (id, user_id, location_id, photo_url, message, star_rating, difficulty_rating, is_event_checkin, event_id, created_at)
- likes (id, user_id, post_id, created_at)
- comments (id, user_id, post_id, message, created_at)
- friends (id, requester_id, addressee_id, status, created_at) — status: pending, accepted, declined

BADGES:
- badge_definitions (id, name, description, icon_url, category, threshold_type, threshold_value)
- user_badges (id, user_id, badge_id, earned_at)

EVENTS & ORGANIZER:
- events (id, organizer_email, event_name, event_date, location_name, logo_url, badge_image_url, badge_animation_url, qr_code_url, package_type, stripe_payment_id, status, created_at)
- event_checkins (id, user_id, event_id, checked_in_at)
- organizer_orders (id, event_id, stripe_session_id, package_type, amount_paid, fulfillment_status, printful_order_id, created_at)

REQUIREMENTS:
- All tables use UUID primary keys
- Add created_at timestamps with defaults everywhere
- Add foreign key constraints with appropriate ON DELETE behavior
- Add indexes on all foreign keys and any field that will be filtered or sorted frequently (ratings, checkin counts, created_at, location type, user_id)
- Write Row Level Security (RLS) policies so that:
  - Users can only update and delete their own posts, comments, and profile
  - Likes and friends are user-scoped
  - Locations are readable by all but only insertable by authenticated users (admin approval field defaults to false)
  - Events and organizer_orders are readable only by the organizer email or admins
  - Badge definitions are public read-only
  - User_badges are readable by all, writable only by service role
- Enable RLS on every table
- Write the script as a single clean migration I can run once in the Supabase SQL editor

After the SQL, provide a short plain-English summary of each table and its purpose so I can refer to it during development.
```

## After running the SQL
Supabase returned "Success. No rows returned" — that is the expected result for a structure-only script. Validate in Supabase: Table Editor should list users, locations, posts, likes, comments, friends, badge_definitions, user_badges, events, event_checkins, organizer_orders.


---


# 05 — Prompts for Steps 3 and 4 (Claude Code)

## STEP 3 — project scaffold
```
Create a new React Native Expo project called "wheeln" with TypeScript. Complete the following setup in order:

1. Initialize the project with:
npx create-expo-app wheeln --template blank-typescript

2. Install these dependencies:
@supabase/supabase-js
@react-navigation/native
@react-navigation/bottom-tabs
@react-navigation/stack
react-native-screens
react-native-safe-area-context
expo-image-picker
expo-camera
expo-location
react-native-maps
@stripe/stripe-react-native
react-native-purchases
expo-barcode-scanner
react-native-qrcode-svg
date-fns
zustand
react-native-async-storage/async-storage
react-native-url-polyfill

3. Create the following complete folder and file structure inside /src:

/src
  /screens
    HomeScreen.tsx, FeedScreen.tsx, CheckInScreen.tsx, ProfileScreen.tsx, BadgesScreen.tsx,
    RankingsScreen.tsx, LocationDetailScreen.tsx, FriendsScreen.tsx, SettingsScreen.tsx,
    OrganizerPortalScreen.tsx, AuthScreen.tsx
  /components
    PostCard.tsx, BadgeIcon.tsx, LocationCard.tsx, RatingStars.tsx, AdBanner.tsx, CheckInModal.tsx
  /lib
    supabase.ts, stripe.ts, revenuecat.ts
  /hooks
    useAuth.ts, useFeed.ts, useLocation.ts, useBadges.ts, useSubscription.ts
  /store
    authStore.ts, feedStore.ts
  /navigation
    AppNavigator.tsx, TabNavigator.tsx
  /types
    index.ts
  /constants
    badges.ts, packages.ts

4. Create a .env.example file in the project root with these placeholder keys:
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url_here
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY=your_stripe_key_here
EXPO_PUBLIC_REVENUECAT_API_KEY=your_revenuecat_key_here
EXPO_PUBLIC_ADMOB_APP_ID=your_admob_app_id_here

5. Create a .env file copied from .env.example (I will fill in the real values)

6. Populate every file with complete working starter content:
- supabase.ts: initialize Supabase client using env variables with AsyncStorage for session persistence
- AppNavigator.tsx: checks auth state — shows AuthScreen if logged out, TabNavigator if logged in
- TabNavigator.tsx: bottom tabs for Feed, Check In, Rankings, and Profile using icons
- AuthScreen.tsx: email/password sign in and sign up with Supabase, clean dark UI
- All screen files: export a basic placeholder screen component with the screen name displayed, using dark background #0D0D0D and white text
- types/index.ts: TypeScript interfaces for User, Post, Location, Badge, Event, Comment matching the Supabase schema
- constants/badges.ts: full badge definitions array matching the badge_definitions table structure
- constants/packages.ts: organizer package definitions with name, price, and features array

App name: Wheeln
Bundle ID: com.wheeln.app
Theme: dark background #0D0D0D, orange accent #FF5A00, card background #1A1A1A, white text

Show me every file with its complete content after creating them.
```

## STEP 4 — authentication (same Claude Code session)
```
In the Wheeln React Native Expo project, build the complete authentication flow using Supabase Auth.

Build or update the following files with complete, fully working code:

1. /src/lib/supabase.ts
- Initialize Supabase client using EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY
- Use AsyncStorage for session persistence
- Export the supabase client as default

2. /src/store/authStore.ts
- Zustand store with these state fields: user, session, isLoading, isPremium
- Actions: setUser, setSession, setLoading, setIsPremium, clearAuth
- Persist session using AsyncStorage

3. /src/hooks/useAuth.ts
- Exposes: user, session, isLoading, signIn, signUp, signOut
- signIn(email, password): calls supabase.auth.signInWithPassword, updates authStore
- signUp(email, password, username): calls supabase.auth.signUp, then inserts a row into the public users table with id, email, username, created_at
- signOut(): calls supabase.auth.signOut, clears authStore
- On mount, call supabase.auth.getSession() to restore existing session
- Listen to supabase.auth.onAuthStateChange to keep store in sync

4. /src/screens/AuthScreen.tsx
- Full dark-themed screen matching Wheeln brand (#0D0D0D background, #FF5A00 accent)
- Wheeln logo text at top in large bold orange font
- Tagline below: "The motorsport community"
- Toggle between Sign In and Sign Up mode with animated tab switcher
- Sign In mode: email field, password field, Sign In button
- Sign Up mode: username field, email field, password field, Create Account button
- Loading spinner while auth is processing
- Error message display in red below the form
- Keyboard avoiding view so fields are not hidden by keyboard on mobile
- All inputs styled dark with subtle border, white text

5. /src/navigation/AppNavigator.tsx
- On app load, check for existing Supabase session via useAuth
- Show a full screen loading spinner while checking session
- If no session: render AuthScreen
- If session exists: render TabNavigator
- Listen to auth state changes so logout automatically returns to AuthScreen

6. /src/navigation/TabNavigator.tsx
- Bottom tab navigator with four tabs: Feed (home icon), Check In (plus-circle icon), Rankings (trophy icon), Profile (person icon)
- Tab bar background: #1A1A1A
- Active tab color: #FF5A00
- Inactive tab color: #666666
- No tab labels, icons only

After building all files, run the app with:
npx expo start

Then tell me:
- Any missing dependencies I need to install
- What I should see on screen when the app loads
- How to test sign up and sign in to confirm Supabase connection is working
- Where in the Supabase dashboard I can verify a new user was created
```


---


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


---


# 07 — Prompts for Steps 8-10

## STEP 8a — organizer portal (Claude Code)
```
Build a standalone web portal (Next.js, deployable to Vercel) called "Wheeln for Organizers" at /organizer-portal.

Pages:
1. Landing page explaining the 3 packages:
   - Starter ($100): custom event badge + unique QR code emailed to you
   - Pro ($250): badge + QR code + 25 branded items via Printful (shirt + stickers)
   - Elite ($500): everything in Pro + premium badge animation + featured placement in app
2. Order form: event name, date, location, organizer email, logo upload, package selection, Stripe checkout
3. On successful Stripe payment: save order to Supabase organizer_orders; generate QR code encoding a unique event ID; generate badge image from template + logo (Canvas API or sharp); email organizer via Resend with QR code, badge preview and instructions
4. Password-protected admin dashboard: list orders, fulfillment status, trigger Printful order for Pro/Elite via Printful API

Use Stripe test mode. Include .env.example. Make it deployable with: vercel deploy
```
(Package prices above for Pro and Elite are proposals; only the $100 starter badge came from the founder.)

## STEP 8b — verify and run (Claude Cowork)
```
I have a Next.js organizer portal project for my app Wheeln. I need you to:
1. Open the project folder
2. Create a .env.local file from .env.example and prompt me to fill in each key
3. Run npm install and confirm all dependencies are installed
4. Run the dev server and take a screenshot of the landing page
5. Walk me through creating my Stripe account, getting test API keys, and pasting them in
6. Test a $100 package purchase with Stripe test card 4242 4242 4242 4242 and confirm the order appears in the Supabase organizer_orders table
```
NOTE: Cowork should not enter card or account credentials for you; you may need to do the Stripe sign-in and key entry yourself.

## STEP 9 — ads and subscription (Claude Code)
```
Integrate monetization into the Wheeln Expo app.

1. Google AdMob:
   - Use react-native-google-mobile-ads (expo-ads-admob is deprecated)
   - /src/lib/admob.ts: initialize with App ID from env
   - /src/components/AdBanner.tsx: banner only if user does NOT have an active subscription
   - Add AdBanner to the bottom of FeedScreen
   - Interstitial after every 5th check-in for free users

2. RevenueCat subscription ($1/month):
   - /src/lib/revenuecat.ts: initialize with API key
   - Give me instructions to create the "wheeln_premium" product in App Store Connect and Google Play Console and link it in RevenueCat
   - /src/hooks/useSubscription.ts: isPremium, subscribe(), restorePurchases()
   - authStore carries an isPremium flag synced from RevenueCat
   - /src/screens/SettingsScreen.tsx: subscription status, "Go Ad-Free $1/mo" button, restore purchases button

3. Anywhere ads render, check isPremium first and render nothing if true.

Include setup instructions for both the AdMob console and RevenueCat dashboard.
```

## STEP 10 — store builds and submission (Claude Cowork)
```
I have a React Native Expo app called Wheeln ready to submit to the App Store and Google Play Store. Help me through every step:

1. Set up Expo EAS Build: install EAS CLI, run eas build:configure, create eas.json with development, preview and production profiles
2. Apple App Store: create the app in App Store Connect; bundle ID com.wheeln.app; signing via EAS; eas build --platform ios --profile production; list required screenshot sizes; write listing description, keywords and category; eas submit --platform ios
3. Google Play: create the app in Play Console; package com.wheeln.app; eas build --platform android --profile production; walk through listing requirements; eas submit --platform android
4. TestFlight beta first: submit iOS build, invite 10 testers (I will supply emails), monitor crash reports

Tell me every account I need and every fee (Apple Developer $99/yr, Google Play $25 one time).
```


---


# 08 — How to Confirm Step 4 (Auth) Works

1. **App loads:** run `npx expo start` in the Claude Code session (it has its own built-in terminal; no separate terminal app needed — ask Claude Code: "Run npx expo start and show me the output, including the QR code"). Scan the QR code with the phone camera (iOS) or Expo Go (Android), or press `i` / `a` for a simulator/emulator. Expect the dark AuthScreen: orange Wheeln logo, tagline, Sign In / Sign Up toggle.
2. **Sign up:** enter a real email, username, password; tap Create Account; expect to land on the tab screens.
3. **Supabase > Authentication > Users:** the new email should be listed.
4. **Supabase > Table Editor > users:** a matching row (same id, email, username). If Auth has the user but `users` is empty, the profile insert in `signUp()` failed.
5. **Sign out and back in** with the same credentials.
6. **Email confirmation:** if sign-in fails with "Email not confirmed", confirm via inbox or temporarily turn off "Confirm email" under Supabase > Authentication > Providers > Email during development.

Caveat: Expo Go cannot run native modules such as Stripe, RevenueCat and AdMob; those need an EAS development build (Steps 9-10).


---


# 09 — Progress and Open Items (as of 2026-11-12)

## Where the founder is
- Steps 1 and 2 done: spec produced; Supabase project created; SQL migration ran ("Success. No rows returned").
- Step 3 and 4 prompts delivered. The project folder `C:\Users\12176\wheeln` currently contains: App.tsx, app.json, babel.config.js, package.json, tsconfig.json, .env, and `src/` with hooks/useAuth.ts, lib/supabase.ts, navigation/AppNavigator.tsx, navigation/TabNavigator.tsx, screens/AuthScreen.tsx, store/authStore.ts. (Not yet present: components, constants, types, other screens/hooks.)
- Not yet confirmed: that sign-up/sign-in works end to end (see file 08).
- NEXT: confirm auth works, then run Step 5.

## Related files already in this project
`docs/context/` (a separate earlier save) holds WHEELN_CONTEXT.md, eight feeder files and `wheeln_migration.sql` from the Step 1/2 spec-and-SQL work. It was left untouched. This `docs/conversation-roadmap/` folder covers the roadmap, prompts and decisions from the planning chat.

## Open items / risks to address
1. Step 3 asks for `expo-barcode-scanner` (deprecated); QR scanning is handled by `expo-camera`. Ask Claude Code to use expo-camera instead.
2. Step 9: use `react-native-google-mobile-ads`, not `expo-ads-admob`.
3. Expo Go cannot run Stripe, RevenueCat or AdMob; plan an EAS development build before Step 9.
4. `user_badges` is service-role-write only, so badge awards need an Edge Function or trigger (affects Step 6).
5. Confirm a `users` row is created at sign-up (insert in `signUp()`), or add a Supabase trigger on auth.users.
6. Pro ($250) and Elite ($500) pricing is a proposal; confirm margins after Printful costs.
7. "AI recommendations" can start as a simple query (Step 7) before adding any model call.
8. Add Apple/Google sign-in only if wanted; Apple requires Sign in with Apple when other social logins are offered on iOS.
9. Budget under $10K assumes the founder builds with AI tools; the $124 account fees plus per-transaction fees are the known hard costs. Verify current vendor pricing.
10. Check wheeln.com, social handles and trademark.


---
