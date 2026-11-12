# Wheeln — Full Conversation Context

_Saved 2026-11-12. This file captures everything produced and decided in the Wheeln planning conversation. Detail lives in the feeder files in `feeders/`; this file is the map plus the key content._

## 1. Who and what
- Solo, non-technical founder building **Wheeln**, a social check-in community app for motorsport and off-road enthusiasts.
- iOS Bundle ID `com.wheeln.app`; Android package `com.wheeln.app`.
- Stack: React Native + Expo (EAS), Supabase, Stripe, RevenueCat, Google AdMob, Printful, Resend, Vercel.
- Launch communities: track days/autocross, off-road trails/parks, drag racing. Later: overlanding/SxS, drag-and-drive, karting, moto track days, gravel/adventure, rock crawling, car shows/Cars & Coffee.
- Monetization: AdMob ads for free users; $1/month ad-free via RevenueCat; organizer packages (Starter $100, Pro $250, Elite $500) via Stripe on a Vercel web portal.

## 2. What was requested and delivered (in order)

### Turn 1 — Six deliverables
1. **PRD** with user stories, acceptance criteria, edge cases (17 user stories) -> `feeders/02-prd-user-stories.md`
2. **Supabase schema** -> `feeders/03-database-schema.md`
3. **Expo project folder structure** -> `feeders/04-project-structure.md`
4. **Third-party services list with doc links** -> `feeders/05-third-party-services.md`
5. **Prioritized MVP list** (17 day-1 items, Phase 2, Phase 3) -> `feeders/06-mvp-roadmap.md`
6. **Accounts to create with costs**, setup checklists, env vars -> `feeders/07-accounts-and-costs.md`

These were delivered as a Word file, `Wheeln_Master_Specification.docx` (generated in the cloud workspace and sent to chat; it is not in this folder).

### Turn 2 — "What do I do next?"
Advice recorded in `feeders/08-next-steps.md`: secure accounts, hire a developer (freelancer $8k-$20k, agency $25k-$60k+, or technical co-founder), run the schema in Supabase and sketch five core screens before hiring, scope to the 17 MVP items, seed 50-100 locations, expect 3-5 months plus a 20-30% cushion.

### Turn 3 — SQL migration
A single paste-ready Supabase migration (901 lines): `feeders/wheeln_migration.sql`. Contains enums, 11 tables, indexes, counter triggers, RLS policies on every table, 13 seeded badges, and two views. Table summaries are in `feeders/03-database-schema.md`.

### Turn 4 (this request)
Save all context to a markdown file plus feeder files in a folder on this computer -> this folder.

## 3. Key decisions and definitions
- **Table naming:** migration uses `users` and `posts` (the founder's requested names) rather than the spec's `profiles` and `checkins`.
- **Location types:** track, autocross, drag_strip, off_road_trail, off_road_park, car_show, overlanding, karting, moto_track, gravel_ride, rock_crawl, cars_and_coffee, other.
- **Locations are submitted unapproved** (`admin_approved = false`) and invisible until an admin approves.
- **Badges** are evaluated server-side by an Edge Function; `user_badges` is writable only with the service role.
- **Events/orders** are readable by the organizer's email; admin access is via service role.
- **Recommended MVP boundary:** the 17 items in the roadmap; organizer portal, AI recommendations, and Printful fulfillment are Phase 2.

## 4. Open items and things to confirm
- Auth-to-profile link: nothing yet creates a `users` row automatically at signup.
- No `is_admin` flag, so no admin RLS policies; admin tooling must use the service role for now.
- Submitters cannot see their own pending locations.
- Test RLS on soft-delete updates for posts and comments end to end.
- The early Expo project already in `C:\Users\12176\wheeln` uses a `screens/navigation` layout, while the plan uses Expo Router; choose one.
- The spec says AI recommendations run on the Claude API; confirm the cost cap before launch.
- Cost and pricing figures (Apple $99/yr, Google $25, Supabase $25/mo Pro, Stripe 2.9% + $0.30, and so on) are as given in the original spec and should be re-checked on each vendor's site before you budget.

## 5. Feeder file index
| File | Contents |
|---|---|
| feeders/01-product-overview.md | Product, features, stack, packages |
| feeders/02-prd-user-stories.md | PRD user stories, criteria, edge cases |
| feeders/03-database-schema.md | Table purposes, triggers, views, RLS, known gaps |
| feeders/04-project-structure.md | Planned Expo/Supabase/portal layout |
| feeders/05-third-party-services.md | Services and docs links |
| feeders/06-mvp-roadmap.md | MVP, Phase 2, Phase 3 |
| feeders/07-accounts-and-costs.md | Accounts, costs, env vars, setup checklists |
| feeders/08-next-steps.md | Next-step advice |
| feeders/wheeln_migration.sql | Full Supabase migration, run once in the SQL editor |
