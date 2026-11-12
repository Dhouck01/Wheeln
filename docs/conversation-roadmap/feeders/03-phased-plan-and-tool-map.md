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
