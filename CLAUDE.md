# Wheeln

Wheeln is a social check-in community app for motorsport and off-road enthusiasts. Users check in at tracks, autocross courses, drag strips, off-road parks and trails, post a photo and message, rate how much they liked it and how hard it was, and earn badges. Others like and comment. Event organizers buy packages on a web portal and receive a QR code and custom badge so attendees can check in at their event.

The owner is a solo, non-technical founder building with AI tools.

## Working rules (read first)
- Explain things in plain English. Avoid jargon, or define it in one line.
- Work on ONE feature at a time. Do not start the next feature unprompted.
- Before changing more than 3 files, show a short plan and wait for approval.
- Never put secrets in code. Never commit `.env`. Only `.env.example` is tracked.
- After each feature, give a numbered checklist to test on a phone, with the exact thing to see at each step.
- Do not mark something done until the owner confirms it works.
- After the owner confirms, commit with a clear message and update "Current status" below.
- When fixing a bug, explain the cause first, then fix it. Make no unrelated changes.
- If a roadmap item conflicts with the current code or database, say so before building.

## Stack
- App: React Native with Expo (TypeScript), one codebase for iOS and Android
- Backend: Supabase (Postgres, Auth, Storage). Row Level Security is ON for every table
- Payments: Stripe (organizer packages)
- Subscriptions: RevenueCat ($1/month removes ads)
- Ads: Google AdMob via react-native-google-mobile-ads (not expo-ads-admob, which is deprecated)
- Merch fulfillment: Printful API
- Email: Resend (QR code and badge delivery)
- Organizer portal: Next.js on Vercel
- Builds and store submission: Expo EAS Build

## Identifiers
- App name: Wheeln
- iOS bundle ID and Android package: `com.wheeln.app`
- Supabase project: `wheeln`
- Organizer portal: "Wheeln for Organizers" (Vercel project `wheeln-organizers`)

## Brand and UI
- Dark theme: background `#0D0D0D`, accent orange `#FF5A00`, cards `#1A1A1A`, white text
- Tab bar: background `#1A1A1A`, active `#FF5A00`, inactive `#666666`, icons only
- Tagline: "The motorsport community"
- Motorsport feel: bold, high contrast, simple layouts

## Project structure (src/)
- `screens/` one file per screen
- `components/` reusable UI (PostCard, BadgeIcon, LocationCard, RatingStars, AdBanner, CheckInModal)
- `lib/` service clients (supabase, stripe, revenuecat)
- `hooks/` data and logic (useAuth, useFeed, useLocation, useBadges, useSubscription)
- `store/` Zustand stores (authStore, feedStore)
- `navigation/` AppNavigator (auth gate) and TabNavigator
- `types/` shared TypeScript types matching the database
- `constants/` badges and organizer packages

Folder rules:
- Use this classic `screens/` + `navigation/` layout. Do not switch to Expo Router (the planned layout in `docs/context/feeders/04-project-structure.md` is out of date).
- Screens only show things and call hooks. Database calls go in `hooks/` or `lib/`, never inside a screen or component.
- Only `lib/supabase.ts` creates the Supabase client. Everything else imports it.
- Shared types live in `types/` and must match the database columns.
- Colors and fixed values live in `constants/`, not typed inline.
- Edge Functions live in `supabase/functions/`, and database changes in `supabase/migrations/`, both outside `src/`.

## Database
Schema lives in `docs/context/feeders/wheeln_migration.sql` (table list and notes in `docs/context/feeders/03-database-schema.md`). Row Level Security (RLS, the rules for who can read or write each row) is ON for every table. Never turn it off to make something work.

Tables: users, locations, posts, likes, comments, friends, badge_definitions, user_badges, events, event_checkins, organizer_orders.
- Locations are submitted with `admin_approved = false` and must be approved before they appear.
- `user_badges` is writable only by the service role. Award badges from a Supabase Edge Function or database trigger, never directly from the app.
- Events and organizer_orders are readable only by the organizer email or admins.
- Check the RLS policies before building any feature that reads or writes a table.

## Business rules
- Free users see ads (banner, plus an interstitial after every 5th check-in). Subscribers ($1/month) see none. Always check `isPremium` before rendering an ad.
- Organizer packages: Starter $100 (badge + QR code). Pro $250 and Elite $500 are proposed and not final.
- Launch communities: on-road track/autocross, off-road trails and parks, drag racing. Other communities come later.

## Reference docs
Full planning context, prompts and decisions are in `docs/conversation-roadmap/`:
- `WHEELN_CHAT_CONTEXT.md` is the combined master file
- `feeders/` holds the individual pieces (vision and decisions, stack and accounts, phased plan, prompts for Steps 1-10, auth checklist, progress and open items)
Read the relevant feeder before starting a feature. A separate earlier save with the spec and SQL migration is in `docs/context/`.

## Build order
1. Auth (login, signup, session)
2. Feed, posts and check-in
3. Badges
4. Rankings, recommendations, location detail
5. Organizer portal and Stripe
6. Ads and $1 subscription
7. Store builds, TestFlight and Play beta, launch

## Known issues
- Use `expo-camera` for QR scanning; `expo-barcode-scanner` is deprecated.
- Expo Go cannot run Stripe, RevenueCat or AdMob. These need an EAS development build.
- Confirm `signUp` creates a row in the public `users` table, or add a trigger on `auth.users`.
- If Supabase email confirmation is on, sign-in fails until the email is confirmed. Turn it off during development. (Currently off.)
- Supabase Authentication must have the Email provider enabled, or sign-up shows "Email signups are disabled". (Currently on.)
- `users` rows need `auth_id` (the login's ID) and `display_name`. `signUp()` sets both. If sign-up is ever changed, keep them.
- `isLoading` in the auth store means "checking for a saved session at app start". Do not set it during sign-in or sign-up, or the sign-in screen is rebuilt and loses its form and error text.
- Starting the app on this Windows PC, in PowerShell: use `npm.cmd start` (plain `npm` is blocked). Before it, set `$env:NODE_OPTIONS="--use-system-ca"` (fixes a certificate error) and `$env:REACT_NATIVE_PACKAGER_HOSTNAME="<PC Wi-Fi IP>"` (so the phone can find it; currently 192.168.50.180, check with `ipconfig`). These last only for that terminal tab. Expo CLI must be logged in (`npx expo login`).
- The iPhone's Expo Go only supports the newest SDK, so the project must stay on it. Upgrade the project when Expo Go moves on.
- Node.js is installed. If `node` is not found in a new session, restart the app.

## Current status
- Done: Supabase project and database migration; project scaffold; git set up (GitHub: https://github.com/Dhouck01/Wheeln, branch main); project upgraded to Expo SDK 58; auth confirmed on a phone (sign up creates the `users` row, sign in, wrong-password error, session survives closing the app, Sign Out on the Profile tab)
- Next: build the feed and check-in system (build order step 2)
- Missing: no `.env.example` yet (add one with placeholder values only); app icon, splash image and adaptive icon files in `assets/` do not exist yet (needed before store builds); `app.json` still has the old `splash` setting, which SDK 58 replaces with the expo-splash-screen plugin
- Placeholders: Feed, Check In and Rankings tabs are placeholder screens; Profile only shows email and Sign Out
(Update this section at the end of every session.)
