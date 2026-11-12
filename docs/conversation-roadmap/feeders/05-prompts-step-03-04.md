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
