# 09 — Progress and Open Items (as of 2026-11-12)

## Where the founder is
- Steps 1 and 2 done: spec produced; Supabase project created; SQL migration ran ("Success. No rows returned").
- Step 3 and 4 prompts delivered. The project folder `C:\Users\12176\wheeln` currently contains: App.tsx, app.json, babel.config.js, package.json, tsconfig.json, .env, and `src/` with hooks/useAuth.ts, lib/supabase.ts, navigation/AppNavigator.tsx, navigation/TabNavigator.tsx, screens/AuthScreen.tsx, store/authStore.ts. (Not yet present: components, constants, types, other screens/hooks.)
- Not yet confirmed: that sign-up/sign-in works end to end (see file 08).
- NEXT: confirm auth works, then run Step 5.

## Related files already in this project
`docs/context/` (a separate earlier save) holds WHEELN_CONTEXT.md, eight feeder files and `wheeln_migration.sql` from the Step 1/2 spec-and-SQL work. It was left untouched. This `docs/conversation-roadmap/` folder covers the roadmap, prompts and decisions from the planning chat.

## Open items / risks to address
1. Step 3 asks for `expo-barcode-scanner` (deprecated); QR scanning is handled by `expo-camera`. Ask Claude Code to use expo-camera instead.
2. Step 9: use `react-native-google-mobile-ads`, not `expo-ads-admob`.
3. Expo Go cannot run Stripe, RevenueCat or AdMob; plan an EAS development build before Step 9.
4. `user_badges` is service-role-write only, so badge awards need an Edge Function or trigger (affects Step 6).
5. Confirm a `users` row is created at sign-up (insert in `signUp()`), or add a Supabase trigger on auth.users.
6. Pro ($250) and Elite ($500) pricing is a proposal; confirm margins after Printful costs.
7. "AI recommendations" can start as a simple query (Step 7) before adding any model call.
8. Add Apple/Google sign-in only if wanted; Apple requires Sign in with Apple when other social logins are offered on iOS.
9. Budget under $10K assumes the founder builds with AI tools; the $124 account fees plus per-transaction fees are the known hard costs. Verify current vendor pricing.
10. Check wheeln.com, social handles and trademark.
