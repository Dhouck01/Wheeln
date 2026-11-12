# 07 — Prompts for Steps 8-10

## STEP 8a — organizer portal (Claude Code)
```
Build a standalone web portal (Next.js, deployable to Vercel) called "Wheeln for Organizers" at /organizer-portal.

Pages:
1. Landing page explaining the 3 packages:
   - Starter ($100): custom event badge + unique QR code emailed to you
   - Pro ($250): badge + QR code + 25 branded items via Printful (shirt + stickers)
   - Elite ($500): everything in Pro + premium badge animation + featured placement in app
2. Order form: event name, date, location, organizer email, logo upload, package selection, Stripe checkout
3. On successful Stripe payment: save order to Supabase organizer_orders; generate QR code encoding a unique event ID; generate badge image from template + logo (Canvas API or sharp); email organizer via Resend with QR code, badge preview and instructions
4. Password-protected admin dashboard: list orders, fulfillment status, trigger Printful order for Pro/Elite via Printful API

Use Stripe test mode. Include .env.example. Make it deployable with: vercel deploy
```
(Package prices above for Pro and Elite are proposals; only the $100 starter badge came from the founder.)

## STEP 8b — verify and run (Claude Cowork)
```
I have a Next.js organizer portal project for my app Wheeln. I need you to:
1. Open the project folder
2. Create a .env.local file from .env.example and prompt me to fill in each key
3. Run npm install and confirm all dependencies are installed
4. Run the dev server and take a screenshot of the landing page
5. Walk me through creating my Stripe account, getting test API keys, and pasting them in
6. Test a $100 package purchase with Stripe test card 4242 4242 4242 4242 and confirm the order appears in the Supabase organizer_orders table
```
NOTE: Cowork should not enter card or account credentials for you; you may need to do the Stripe sign-in and key entry yourself.

## STEP 9 — ads and subscription (Claude Code)
```
Integrate monetization into the Wheeln Expo app.

1. Google AdMob:
   - Use react-native-google-mobile-ads (expo-ads-admob is deprecated)
   - /src/lib/admob.ts: initialize with App ID from env
   - /src/components/AdBanner.tsx: banner only if user does NOT have an active subscription
   - Add AdBanner to the bottom of FeedScreen
   - Interstitial after every 5th check-in for free users

2. RevenueCat subscription ($1/month):
   - /src/lib/revenuecat.ts: initialize with API key
   - Give me instructions to create the "wheeln_premium" product in App Store Connect and Google Play Console and link it in RevenueCat
   - /src/hooks/useSubscription.ts: isPremium, subscribe(), restorePurchases()
   - authStore carries an isPremium flag synced from RevenueCat
   - /src/screens/SettingsScreen.tsx: subscription status, "Go Ad-Free $1/mo" button, restore purchases button

3. Anywhere ads render, check isPremium first and render nothing if true.

Include setup instructions for both the AdMob console and RevenueCat dashboard.
```

## STEP 10 — store builds and submission (Claude Cowork)
```
I have a React Native Expo app called Wheeln ready to submit to the App Store and Google Play Store. Help me through every step:

1. Set up Expo EAS Build: install EAS CLI, run eas build:configure, create eas.json with development, preview and production profiles
2. Apple App Store: create the app in App Store Connect; bundle ID com.wheeln.app; signing via EAS; eas build --platform ios --profile production; list required screenshot sizes; write listing description, keywords and category; eas submit --platform ios
3. Google Play: create the app in Play Console; package com.wheeln.app; eas build --platform android --profile production; walk through listing requirements; eas submit --platform android
4. TestFlight beta first: submit iOS build, invite 10 testers (I will supply emails), monitor crash reports

Tell me every account I need and every fee (Apple Developer $99/yr, Google Play $25 one time).
```
