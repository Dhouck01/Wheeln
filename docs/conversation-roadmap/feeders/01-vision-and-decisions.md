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
