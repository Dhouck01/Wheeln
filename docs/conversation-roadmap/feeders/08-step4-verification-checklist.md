# 08 — How to Confirm Step 4 (Auth) Works

1. **App loads:** run `npx expo start` in the Claude Code session (it has its own built-in terminal; no separate terminal app needed — ask Claude Code: "Run npx expo start and show me the output, including the QR code"). Scan the QR code with the phone camera (iOS) or Expo Go (Android), or press `i` / `a` for a simulator/emulator. Expect the dark AuthScreen: orange Wheeln logo, tagline, Sign In / Sign Up toggle.
2. **Sign up:** enter a real email, username, password; tap Create Account; expect to land on the tab screens.
3. **Supabase > Authentication > Users:** the new email should be listed.
4. **Supabase > Table Editor > users:** a matching row (same id, email, username). If Auth has the user but `users` is empty, the profile insert in `signUp()` failed.
5. **Sign out and back in** with the same credentials.
6. **Email confirmation:** if sign-in fails with "Email not confirmed", confirm via inbox or temporarily turn off "Confirm email" under Supabase > Authentication > Providers > Email during development.

Caveat: Expo Go cannot run native modules such as Stripe, RevenueCat and AdMob; those need an EAS development build (Steps 9-10).
