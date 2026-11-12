# Wheeln — PRD: User Stories, Acceptance Criteria, Edge Cases

## Authentication & accounts
**US-01 Registration** — Email+password or Google/Apple OAuth; verification email; profile auto-created; username unique, 3-30 chars, alphanumeric + underscore. Edge: email exists -> offer login/reset; OAuth email match -> prompt to link; username taken -> suggest alternatives. Out of MVP: phone auth, 2FA.
**US-02 Login** — Email/password and OAuth; session persists; forgot-password via Supabase; biometric login if device allows. Edge: unverified email -> resend; suspended -> message; expired session -> silent refresh, else login.
**US-03 Profile** — Display name, username, avatar (resized 400x400, Supabase Storage), bio max 200, vehicle types, home region; shows check-in count, badge count, member-since. Edge: avatar upload fails -> keep old; username change cooldown 30 days.

## Locations
**US-04 Browse** — List + map; filter by type, state/region, rating, difficulty; card shows name, type, city/state, avg rating, check-in count, hero photo; sort nearest/highest rated/most checked-in. Edge: location permission denied -> sort by rating; empty filter result -> empty state; skeleton loaders.
**US-05 Detail** — Name, address, type, description, avg rating/difficulty, check-in count, photo gallery, paginated reviews (20/page), Maps link, rating distribution. Edge: no check-ins -> "be the first"; archived location notice.
**US-06 Submit location** — Name, type, address (required), GPS via map picker, description, website, photo; enters pending, invisible to others; push on approve/reject; admin queue. Edge: duplicate within 500 m warning; rejection reason shown.

## Check-ins
**US-07 Create check-in** — Select location, 1 photo (required), message (max 500, optional), stars 1-5 (required), difficulty 1-5 (required); saved with timestamp + GPS; badge evaluation runs after save. Edge: photo failure blocks submit; GPS unavailable -> manual selection; multiple same-day check-ins at one location count once for badge milestones; pending locations can't be checked into.
**US-08 Event QR check-in** — QR deep link `wheeln://checkin?event={eventId}`; logged-in user gets event check-in + badge automatically; one redemption per user per event; logged-out user registers first, badge awarded after. Edge: expired event, repeat scan idempotent, invalid event ID.

## Social feed
**US-09 Feed** — Cards with avatar, username, location, photo, ratings, message snippet, timestamp, like/comment counts; toggle Community vs Friends; infinite scroll 20/page; pull-to-refresh. Edge: empty friends feed prompts adding friends; offline shows cached feed; deleted posts disappear.
**US-10 Likes & comments** — Single-tap like (optimistic); comments max 300; push for likes (max 1 per post per liker) and comments; delete own comments; report offensive content. Edge: self-like allowed with no notification; comment on deleted post blocked; double-tap dedupe.

## Friends
**US-11 Add friends** — Search by username/display name; request, accept/decline; mutual friend count; unfriend. Edge: no self-request; duplicate -> pending state; blocked users; optional private profile.

## Badges
**US-12 Earn badges** — Server-side evaluation (Edge Function) after every check-in; push on new badge; profile grid; detail shows description, date, rarity.
Standard badges: First Wheel (1 check-in), Road Warrior (10), Track Regular (25), Century Driver (100), Explorer (5 locations), Globe Trotter (5 states), Track Rat (10 track/autocross), Dirt Slinger (10 off-road), Quarter Mile Club (10 drag), Weekend Warrior (4 consecutive weekends), 5-Star Rater (20 five-star ratings), Critic (20 messages over 100 chars), Early Adopter (joined in first 90 days), plus per-event "[Event Name] Attendee" badges.
Edge: multiple badges in one check-in -> batched notifications; admin revoke; never re-awarded.

## Rankings
**US-13** — Top-rated and Most Challenging require min 5 check-ins; Most Popular by count; filter by type; user leaderboard by total check-ins. Ties broken by check-in volume.

## AI recommendations
**US-14** — Exactly 3 recommendations via Edge Function calling Claude API; input is check-in history; output is 3 location IDs + reason (max 100 chars); max 3 refreshes/day; cached until next check-in or refresh; users with <3 check-ins see top-rated in region. Edge: API failure -> cached; skip removed locations.

## Monetization
**US-15 Ads (free users)** — Banner at bottom of feed and location list; interstitial after every 5th check-in; capped 3/hour; hidden for subscribers. Edge: ad load failure collapses gracefully; no interstitial in background; age gate / COPPA.
**US-16 Ad-free subscription** — $1/month via RevenueCat; webhook sets subscription status in Supabase; restore purchases; cancel -> ads resume at period end.

## Organizer portal
**US-17 Purchase package** — Separate web portal on Vercel: event name, date, location, organizer name/email, logo upload; Stripe Checkout; on success Edge Function creates event, generates badge + QR, emails via Resend; Pro/Elite place Printful order. Edge: payment failure creates no event; logo >5MB rejected; past date disallowed; duplicate name+date warning; resend-email option.
