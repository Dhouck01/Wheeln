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
