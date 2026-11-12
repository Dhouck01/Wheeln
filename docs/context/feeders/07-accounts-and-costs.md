# Wheeln — Accounts to Create and Costs

| Service | Cost | Notes |
|---|---|---|
| Apple Developer Program | $99/year | Needed for App Store, push, Sign in with Apple; approval can take 1-2 days |
| Google Play Console | $25 one-time | Approval can take up to a week |
| Supabase | Free, then $25/mo Pro | Free tier: 500MB DB, 1GB storage |
| Expo / EAS | Free tier (30 builds/mo) | Paid tiers available |
| Stripe | 2.9% + $0.30 per transaction | Organizer portal |
| RevenueCat | Free up to $2.5k MRR | One project, iOS + Android apps |
| Google AdMob | Free (revenue share) | 4 ad units: banner/interstitial x iOS/Android |
| Google Maps Platform | ~$200/mo free credit | Needed for Android maps |
| Anthropic API | Pay per token | Set usage limits |
| Printful | Free account; per-item production cost | Bake costs into Pro/Elite pricing |
| Resend | Free to 3,000 emails/mo | Verify wheeln domain |
| Vercel | Free Hobby; $20/mo Pro | |
| GitHub | Free | |
| Domain (wheeln.app or .com) | ~$15-20/year | |
| Cloudflare | Free | DNS |
| Figma | Free; Pro $15/mo per editor | |

## Environment variables
EXPO_PUBLIC_SUPABASE_URL, EXPO_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (edge functions only), EXPO_PUBLIC_GOOGLE_MAPS_API_KEY, REVENUECAT_IOS_API_KEY, REVENUECAT_ANDROID_API_KEY, ADMOB_IOS_APP_ID, ADMOB_ANDROID_APP_ID, ADMOB_BANNER_IOS, ADMOB_BANNER_ANDROID, ADMOB_INTERSTITIAL_IOS, ADMOB_INTERSTITIAL_ANDROID, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, ANTHROPIC_API_KEY, PRINTFUL_API_KEY, RESEND_API_KEY.
Only the EXPO_PUBLIC_* values belong in the app; everything else stays server-side (Edge Functions / portal).

## Setup checklists
- **Supabase:** enable email + Google + Apple auth; storage buckets avatars, checkin-photos, location-photos, event-assets; RLS on all tables; webhook URLs for RevenueCat and Stripe; PostGIS optional.
- **Stripe:** products Starter $100, Pro $250, Elite $500; webhook to the Supabase function; allow wheeln domain.
- **RevenueCat:** iOS + Android apps (com.wheeln.app); entitlement `ad_free`; monthly product; webhook to revenuecat-webhook function.
- **AdMob:** app per platform; 4 ad units; IDs into constants and app.json.
- **EAS:** eas build:configure; bundle ID com.wheeln.app; development/preview/production profiles; secrets in EAS, never in git.

## Estimated fixed monthly cost at launch (~500 users)
About $15-50/month (Supabase $0-25, Anthropic ~$5-15, Apple $8.25 amortized, domain ~$1.25). Stripe and Printful costs are variable and covered by package revenue.
