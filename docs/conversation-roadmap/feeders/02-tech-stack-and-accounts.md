# 02 — Tech Stack and Accounts

| Layer | Tool | Why |
|---|---|---|
| Mobile app | React Native (Expo) | One codebase for iOS and Android |
| Backend / DB | Supabase | Free tier, auth, storage, row-level security |
| Auth | Supabase Auth | Email, Google, Apple sign-in |
| Image storage | Supabase Storage | Same backend |
| Payments | Stripe | Organizer packages |
| Subscriptions | RevenueCat | $1/mo ad-free across iOS and Android |
| Ads | Google AdMob | Banner and interstitial for free users |
| Transactional email | Resend | QR code and badge delivery (SendGrid alternative) |
| Merch fulfillment | Printful API | Print-on-demand and shipping |
| QR codes | qrcode library | Free, open source |
| Organizer portal | Next.js on Vercel | Free hosting tier |
| App store builds | Expo EAS Build | iOS and Android builds and submission |

## Accounts to create
| Service | Cost |
|---|---|
| Supabase | Free tier |
| Expo / EAS | Free tier (build limits) |
| Apple Developer Program | $99/yr |
| Google Play Console | $25 one time |
| Stripe | Per-transaction fee |
| RevenueCat | Free up to a revenue threshold |
| Google AdMob | Free |
| Printful | Per-order cost |
| Resend | Free tier |
| Vercel | Free tier |

Upfront cost estimate in the plan: about $124 (Apple + Google). Infra about $0-$30/mo at launch. **Re-check all prices on each vendor's site before budgeting.**

## Env vars (Expo app, `.env`)
EXPO_PUBLIC_SUPABASE_URL, EXPO_PUBLIC_SUPABASE_ANON_KEY, EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY, EXPO_PUBLIC_REVENUECAT_API_KEY, EXPO_PUBLIC_ADMOB_APP_ID
