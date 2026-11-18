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
- `navigation/` AppNavigator (auth gate, plus a root stack so screens can open on top of the tabs with a Back button: add new full screens like Badges and Location Detail to that stack and to `RootStackParamList` in `types/`) and TabNavigator
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

Tables: users, locations, posts, likes, comments, friends, badge_definitions, user_badges, events, event_checkins, organizer_orders, courses, post_courses, course_reports, course_merges (the last four were added in `supabase/migrations/20261117000000_course_tables.sql`), badge_ladders (added in `supabase/migrations/20261118000000_badge_ladders.sql`).
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
- Done (build order step 2, slice 1): Feed screen confirmed on a phone: Friends/Community toggle, 20-per-page scrolling, pull to refresh, likes, comments. Lock-down migration `supabase/migrations/20261112000000_lock_down_posts_and_comments.sql` applied and tested (app users can only edit a post's message). 18 starter locations loaded from `supabase/seed/locations_seed.sql`; `[TEST]` posts from `supabase/seed/test_posts.sql` are placeholder data (delete with the cleanup line at the bottom of that file)
- Done (build order step 4, slice 1): Rankings tab confirmed on a phone: Top Rated / Most Challenging / Most Popular, places need 3+ check-ins (`RANKINGS_MIN_CHECKINS` in `constants/theme.ts`), reads `locations` directly. `[RANK-TEST]` posts from `supabase/seed/test_checkins_for_rankings.sql` are placeholder data (cleanup line at the bottom of that file)
- Done (UI polish): real Ionicons tab icons (import `@expo/vector-icons/Ionicons` directly, not the package root, which loads every icon set), Check In "coming soon" screen, page titles on Feed and Rankings. Profile left alone until it is built properly. After installing a native package, restart Expo with `npm.cmd start -- --clear`
- Done (build order step 2, slice 2): Check-in confirmed on a phone: search approved places, camera or library photo (shrunk to 1080px), star + difficulty ratings, optional message, upload to public `post-photos` bucket (`supabase/migrations/20261115000000_post_photos_storage.sql`, uploads only into your own login-id folder), post appears at top of Feed. Skipped on purpose: GPS, repeat-check-in limit, badge check (badges step). The first real check-in was made by the owner (not marked as test)
- Done (security, Step A): `supabase/migrations/20261116000000_lock_down_users_friends_events.sql` applied and tested with `supabase/tests/lock_down_users_friends_events_test.sql` (all PASS) and on a phone. App users can no longer change `subscription_status`, `revenuecat_user_id`, counters, `is_suspended`, `email` or `auth_id` on `users`; friend requests always start `pending` and the receiver can only change `status`; the direct insert rule on `event_checkins` is removed (QR check-ins will come from a server function)
- Done (Step B2, badge ladders in the database): `supabase/migrations/20261118000000_badge_ladders.sql` applied and tested with `supabase/tests/badge_ladders_test.sql` (73 of 73 PASS). No app code uses it yet. 12 ladders in `badge_ladders` and 160 badges in `badge_definitions` (columns `ladder_id`, `tier`; the number needed is `threshold_value`; slug is `<ladder>_<tier>`, e.g. `road_visits_5`). The 12 old starter badges were replaced; `early_adopter` stays and is manual. Ladders: `road_visits` (Asphalt), `offroad_visits` (Dirt), `drag_visits` (Quarter Mile), `all_visits` (Odometer), `road_venues` (Circuit Hopper), `offroad_venues` (Trail Seeker), `drag_venues` (Strip Hopper), `all_venues` (Explorer), `courses` (Course Collector), `states` (Road Trip), `likes` (Crowd Favorite), `friends` (Crew). Volume ladders have 20 steps, the rest 10. Badge names are the ladder name plus the level, with special titles at levels 5/10/15/20 (volume) or 5/10 (others). Rules: visits count one per venue per Eastern-time day; Road = track, autocross, karting, moto_track; Off-road = off_road_trail, off_road_park, rock_crawl, overlanding, gravel_ride; Drag = drag_strip; other types count only toward all-places ladders; Course Collector counts only approved courses; own likes do not count; badges are permanent (deleting a check-in never removes one). The database awards badges by trigger on check-ins, trails attached, likes, accepted friends and course approval (a badge error only logs a warning, never blocks the action). App functions: `my_badge_progress()` returns `(ladder_slug, metric_value)` for the signed-in user. Admin SQL: recount one person `SELECT public.admin_recompute_badges('<user id>');` (no argument = everyone; wipes ladder badges only and recounts; use after deleting the `[TEST]` and `[RANK-TEST]` posts). Hand out Early Adopter at launch with `INSERT INTO public.user_badges (user_id, badge_id) SELECT u.id, (SELECT id FROM public.badge_definitions WHERE slug = 'early_adopter') FROM public.users u WHERE u.created_at < '<cutoff date>' ON CONFLICT (user_id, badge_id) DO NOTHING;`. The backfill awarded 21 badges to existing users, including from placeholder posts
- Done (Step B3, Badges screen): confirmed on a phone. Profile has a Badges row showing the count of badges earned (`useBadgeCount`), which opens the Badges screen on a new root stack (`@react-navigation/native-stack` v6 installed; after installing, restart Expo with `npm.cmd start -- --clear`). Badges screen: sections Overall / Road / Off-road / Drag / Social, one tile per ladder (hexagon icon built from Views, no drawing package; bronze/silver/gold/platinum by quarter of the ladder, gray if not started; current step; progress bar toward the next step), tap a tile for a sheet listing every step with earned dates, a Special section for one-off badges like Early Adopter, pull to refresh, reloads each time it is opened. Files: `constants/badges.ts` (icons, sections, colors per ladder slug), `hooks/useBadges.ts` (reads `badge_ladders`, `badge_definitions`, `user_badges` and calls `my_badge_progress()`), `components/BadgeIcon.tsx`, `LadderCard.tsx`, `LadderSheet.tsx`, `screens/BadgesScreen.tsx`. Not included: a "you earned a badge" message after check-in (planned in B4) and other people's badges (no public profile screen yet)
- Decided (courses, not built): one check-in per venue visit with optional trails inside, each with its own stars and difficulty (1-5); the overall venue rating stays required. New tables `courses`, `post_courses`, `course_reports`, `course_merges`. Courses are seeded from real data before launch; user-added courses start `pending` (submitter sees their own), you approve by hand in the Supabase dashboard, then `approved`/`removed`. Max 5 new courses per user per day. Only approved courses count toward the Course Collector ladder. Venues stay approval-first
- Done (Step B1, course tables): `supabase/migrations/20261117000000_course_tables.sql` applied and tested with `supabase/tests/course_tables_test.sql` (48 of 48 PASS). No app code uses these tables yet. A course is a trail inside a venue (a `locations` row). Everyone sees `approved` courses; the adder also sees their own `pending` one; `removed` is hidden. App users can only add (forced `pending`, zero counters, venue must be approved, max 5 per rolling 24 hours counting removed ones, blocked when `users.is_suspended`); they cannot edit or delete. A trail on a check-in (`post_courses`) needs both stars and difficulty (1-5), the same venue as the check-in, and is insert-only from the app. Course averages and ride counts are recalculated by the database. A newly submitted location now always starts unapproved with zero counters. Moderation is by hand in the Supabase SQL editor: approve `UPDATE public.courses SET status = 'approved' WHERE id = '<id>';`, remove (same with `'removed'`), fix a typo (`SET name = ...`), merge a duplicate `SELECT public.admin_merge_courses('<duplicate id>', '<original id>', 'reason');` (returns a merge id), undo `SELECT public.admin_undo_course_merge('<merge id>');`, reports are in the `course_reports` table (empty `resolved_at` = open). Courses you load with SQL are not limited, so seed them with `status = 'approved'`
- Done (Step B4a, check-in function): `supabase/migrations/20261119000000_create_checkin_function.sql` applied and tested with `supabase/tests/create_checkin_test.sql` (23 of 23 PASS). No app code uses it yet. `create_checkin(p_location_id, p_photo_url, p_message, p_star_rating, p_difficulty_rating, p_trails jsonb)` saves a post and its trails in one transaction and returns the post id. It runs as the signed-in user (SECURITY INVOKER), so all existing rules apply; signed-out callers are refused. `p_trails` is a list of at most 10 like `[{"course_id": "...", "star_rating": 4, "difficulty_rating": 3}]`; each trail needs both ratings (1-5). Error messages are written to be shown to people (for example "Pick a place first", "You can add up to 10 trails to one check-in"); trail rule violations come back as "row-level security" (wrong venue, or someone else's pending trail) or "duplicate key" (same trail twice). Badges awarded by a check-in are linked to it through `user_badges.post_id`, so the app finds new badges with: select `user_badges` rows where `post_id` is the new post id
- Decided (B4b, B4c, not built): B4b = check-in screen with a trail picker after the place is chosen (approved trails plus your own pending ones marked "Waiting for approval", community stats or "New" under 3 rides, tap a trail to rate stars and difficulty, both required, "Can't find your trail? Add it" form with naming rules "Use the name on the trail sign. No ratings, emojis or extra words like 'best'", similar-name hints, friendly messages for the 5-per-day limit and duplicate names, trails cleared when the place changes), saving through `create_checkin`. B4c = feed cards show trail names on a second line under the place (e.g. "Sand Mountain, Lone Mountain +2 more") and a "Badge earned!" slide-up after posting that lists new badges before going to the Feed
- Next: B4b (check-in with trails), B4c (feed trails and badge popup), B5 (course seed research). Build one at a time
- Open: `users` table is publicly readable including `email`, `revenuecat_user_id` and `is_suspended` (privacy fix needed before launch; organizer rules use email). Expect soft-delete of a post from the app to be blocked by the current posts rules; check when a delete button is added
- Not built yet: tapping a location name (location detail screen is build order step 4); Friends screen, so the Friends tab only shows your own posts
- Missing: app icon, splash image and adaptive icon files in `assets/` do not exist yet (needed before store builds); `app.json` still has the old `splash` setting, which SDK 58 replaces with the expo-splash-screen plugin
- Placeholders: Rankings rows are not tappable yet (needs Location Detail); Profile only shows email, the Badges row and Sign Out
(Update this section at the end of every session.)
