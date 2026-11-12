# Wheeln — Product Overview

**Wheeln** is a social check-in community app for motorsport and off-road enthusiasts (iOS + Android).
Founder: solo, non-technical. Identifiers: App name `Wheeln`, iOS Bundle ID `com.wheeln.app`, Android package `com.wheeln.app`.

## Core features
- Accounts and profiles
- Admin-curated database of tracks, trails, drag strips, off-road parks, car shows; users can submit new locations for admin approval
- Check-ins: photo, message, experience rating (1-5 stars), difficulty rating (1-5)
- Social feed: friends or random community members (toggle)
- Likes and comments
- Badge system: check-in milestones and frequency
- Rankings: top-rated places, most challenging places
- 3 AI-powered location recommendations per user, based on check-in history
- Friends system (filters the feed)

## Launch communities
1. On-road track days and autocross
2. Off-road trails and parks
3. Drag racing

## Future community phases
Overlanding and SxS; drag-and-drive events; karting; motorcycle track days; gravel and adventure riding; rock crawling; car shows and Cars & Coffee.

## Organizer sales portal (web)
Event organizers buy packages on a web portal:
| Package | Price | Includes |
|---|---|---|
| Starter | $100 | Custom event badge + unique QR code emailed to organizer |
| Pro | $250 | Starter + 25 branded merchandise items (shirts, stickers) fulfilled via Printful |
| Elite | $500 | Pro + premium badge animation + featured placement in app feed |

Attendees scan the QR code at the event, get a special check-in, and the event badge shows permanently on their profile. Badges are auto-generated from a template using event name and uploaded logo.

## Monetization
- Free users: banner + interstitial ads via Google AdMob
- $1/month subscription via RevenueCat removes all ads
- Organizer packages via Stripe

## Tech stack
React Native + Expo (EAS Build) · Supabase (database, auth, storage) · Stripe · RevenueCat · Google AdMob · Printful API · Resend (transactional email) · Vercel (organizer portal hosting)
Also specified in the spec: Anthropic Claude API for recommendations, Expo Notifications, React Native Maps + Google Maps Platform, Zustand, qrcode, Sharp.
