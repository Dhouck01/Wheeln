# Wheeln — Database Schema Notes

Source of truth for the executable schema is `wheeln_migration.sql` (same folder). This file explains it.

**Naming note:** the first-pass schema in the spec used `profiles` and `checkins`. The migration follows the founder's requested names instead: `users` and `posts`. Anything in the spec that says profiles/checkins maps to users/posts.

## Tables
| Table | Purpose |
|---|---|
| users | Core identity. `auth_id` links to Supabase `auth.users`. Holds subscription_status, total_checkins and badge_count (trigger-maintained counters). |
| locations | Curated tracks/trails/strips/parks/shows. `admin_approved` defaults false; avg_rating, avg_difficulty, total_checkins maintained by triggers. Type enum: track, autocross, drag_strip, off_road_trail, off_road_park, car_show, overlanding, karting, moto_track, gravel_ride, rock_crawl, cars_and_coffee, other. |
| posts | A check-in: photo, message, star_rating (1-5), difficulty_rating (1-5), is_event_checkin, event_id, like_count, comment_count, soft-delete flag, GPS. |
| likes | One like per user per post (UNIQUE user_id, post_id). Trigger updates posts.like_count. |
| comments | Max 300 chars, soft delete. Trigger updates posts.comment_count. |
| friends | requester_id, addressee_id, status pending/accepted/declined; no self-friending; UNIQUE pair. |
| badge_definitions | Badge rules: category, threshold_type, threshold_value, optional location_type. Seeded with 13 standard badges. Adding a badge = INSERT. |
| user_badges | Who earned what. UNIQUE (user_id, badge_id). Written only by service role. |
| events | Organizer events: organizer_email, badge/QR/logo URLs, package_type, stripe ids, status, expiry, Elite feature window. |
| event_checkins | A user's QR check-in to an event. UNIQUE (user_id, event_id). |
| organizer_orders | Purchase audit trail: stripe_session_id, amount_paid (cents), fulfillment_status, printful_order_id. |

## Triggers (denormalized counters)
- Post insert -> location counters/averages + user.total_checkins
- Post soft delete -> recalculates location counters/averages, decrements user count
- Like insert/delete -> posts.like_count
- Comment insert/soft delete -> posts.comment_count
- user_badges insert -> users.badge_count
- set_updated_at() on users, locations, events, friends, organizer_orders

## Views
- `v_feed` — posts joined with user and location info
- `v_location_rankings` — approved locations with >= 5 check-ins, ranked by rating, difficulty, popularity

## RLS summary
- users: public read; insert/update only own row (auth_id = auth.uid())
- locations: public read of approved only; authenticated insert with admin_approved = false
- posts/comments: public read of non-deleted; insert/update only own (soft delete via update)
- likes: public read; insert/delete own
- friends: only parties can read; requester inserts; addressee updates status; either deletes
- badge_definitions: public read of active; no client writes
- user_badges: public read; writes via service role only
- events: organizer (matched by email) reads own; public can read active events inside an Elite feature window
- event_checkins: user reads/inserts own
- organizer_orders: organizer reads own via event join
- Helper: `current_user_id()` maps auth.uid() to users.id

## Known gaps to confirm with the developer
- No automatic creation of a `users` row when someone signs up in Supabase Auth (needs an auth trigger or client insert on first login).
- No `is_admin` flag, so "admins" are served only by the service role; an admin read policy for events/orders and an admin view of unapproved locations are not yet written.
- Unapproved locations are invisible to everyone, including the user who submitted them.
- The check-in flow does not yet block check-ins to unapproved locations beyond the visibility rule.
- RLS for UPDATE on soft-deleted rows should be tested end to end.
