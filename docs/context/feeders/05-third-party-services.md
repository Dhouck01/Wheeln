# Wheeln — Third-Party APIs & Services

| Service | Role in Wheeln | Docs |
|---|---|---|
| Supabase | Postgres database, auth (email + OAuth), storage, Edge Functions | https://supabase.com/docs |
| Expo / EAS | RN framework, EAS Build, EAS Update, store submissions | https://docs.expo.dev |
| Expo Router | File-based navigation; deep links for QR check-ins (wheeln://) | https://expo.github.io/router/docs |
| RevenueCat | $1/month ad-free subscription; webhooks to Supabase | https://docs.revenuecat.com |
| Google AdMob | Banner + interstitial ads for free users | https://developers.google.com/admob |
| Stripe | Organizer package payments (Checkout + webhooks) | https://stripe.com/docs |
| Printful | Merch fulfillment for Pro/Elite | https://developers.printful.com |
| Resend | Transactional email (QR code + badge to organizers) | https://resend.com/docs |
| Anthropic Claude API | AI location recommendations via Edge Function | https://docs.anthropic.com |
| Vercel | Hosts the organizer portal (Next.js) | https://vercel.com/docs |
| Expo Notifications | Push: likes, comments, badges, friend requests | https://docs.expo.dev/push-notifications/overview |
| React Native Maps | Map view for browse and check-in | https://github.com/react-native-maps/react-native-maps |
| Google Maps Platform | Android map tiles and geocoding | https://developers.google.com/maps |
| Zustand | Global state | https://docs.pmnd.rs/zustand |
| qrcode (npm) | QR PNG generation in Edge Function | https://www.npmjs.com/package/qrcode |
| Sharp (npm) | Compositing event badges from template + logo | https://sharp.pixelplumbing.com |
