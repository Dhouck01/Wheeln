# Wheeln — Expo Project Structure (planned)

Root files: app.json, app.config.ts, package.json, tsconfig.json, babel.config.js, metro.config.js, eas.json, .env.local (never commit), .env.example, .gitignore.

## src/app (Expo Router)
- (auth): login.tsx, register.tsx, forgot-password.tsx
- (tabs): _layout.tsx, feed.tsx, explore.tsx, checkin.tsx, badges.tsx, profile.tsx
- location/[id].tsx, checkin/[id].tsx, user/[username].tsx
- notifications.tsx, search.tsx
- settings/: index.tsx, subscription.tsx, account.tsx
- admin/: index.tsx, locations.tsx (approval queue), reports.tsx

## src/components
ui (Button, Input, Card, Avatar, Badge, Modal, Skeleton, BottomSheet), feed (FeedCard, FeedList, FeedHeader, FeedToggle), checkin (CheckInForm, CheckInCard, RatingPicker, DifficultyPicker, PhotoPicker), location (LocationCard, LocationMap, LocationFilters, RatingChart), badges (BadgeGrid, BadgeItem, BadgeModal), profile (ProfileHeader, ProfileStats, ProfileBadgeRow), ads (BannerAd, InterstitialAdManager)

## Other src folders
- hooks: useAuth, useFeed, useCheckin, useLocation, useBadges, useFriends, useNotifications, useSubscription, useAI
- lib: supabase.ts, revenuecat.ts, admob.ts, stripe.ts
- services: checkins, locations, badges, friends, notifications, ai
- types, constants, store (Zustand: authStore, feedStore, notificationStore), utils (formatDate, truncateText, getDistanceKm, validateImageSize, deepLink)

## supabase/
- migrations/ (versioned SQL)
- functions/: evaluate-badges, ai-recommendations, generate-event-badge, generate-qr-code, stripe-webhook, revenuecat-webhook, send-event-email, printful-order

## portal/ (separate Next.js app on Vercel)
app/page.tsx (package selection), app/checkout/page.tsx, app/success/page.tsx, app/api/create-checkout/route.ts, components (PackageCard, EventForm, LogoUpload), lib/stripe.ts

## Status on this computer
The folder `C:\Users\12176\wheeln` already contains an early Expo project (App.tsx, src/lib/supabase.ts, src/store/authStore.ts, src/hooks/useAuth.ts, src/screens/AuthScreen.tsx, src/navigation/*). It uses a classic `src/screens` + `src/navigation` layout, not the Expo Router layout above. Decide which layout to keep before building further.
