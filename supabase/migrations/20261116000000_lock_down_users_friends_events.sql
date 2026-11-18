-- ============================================================
--  WHEELN — Lock down users, friends and event check-ins
--
--  Problems this fixes:
--   1. The "update own profile" rule on `users` lets a signed-in person edit
--      ANY column of their own row. They could set subscription_status to
--      'active' (free ad-free), or fake total_checkins / badge_count.
--      The insert rule has the same hole at sign-up.
--   2. The friends insert rule lets a person create a request that is already
--      'accepted', skipping the other person's approval. The update rule lets
--      the person who received a request rewrite any column, not just status.
--   3. The event_checkins insert rule lets anyone claim they attended any
--      event. Event check-ins will come from a server function instead.
--
--  How: small guard triggers (same approach as the posts and comments
--  lock-down). They only restrict normal app users (roles "authenticated" and
--  "anon"). The Supabase SQL editor, the service role, and our own counter
--  triggers (which are SECURITY DEFINER) are not affected.
--
--  Safe to re-run. Paste into the Supabase SQL editor and run once.
-- ============================================================


-- ──────────────────────────────────────────
-- USERS: on insert (sign-up), protected fields start at their defaults
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_user_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.subscription_status := 'free';
    NEW.revenuecat_user_id  := NULL;
    NEW.total_checkins      := 0;
    NEW.badge_count         := 0;
    NEW.is_suspended        := false;
    NEW.username_changed_at := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_user_insert ON public.users;
CREATE TRIGGER trg_guard_user_insert
  BEFORE INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.guard_user_insert();


-- ──────────────────────────────────────────
-- USERS: on update, an app user cannot touch subscription, counters or identity
-- (display name, username, bio, avatar, vehicle types, region and the privacy
-- switch stay editable)
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_user_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF NEW.id                  IS DISTINCT FROM OLD.id
    OR NEW.auth_id             IS DISTINCT FROM OLD.auth_id
    OR NEW.email               IS DISTINCT FROM OLD.email
    OR NEW.subscription_status IS DISTINCT FROM OLD.subscription_status
    OR NEW.revenuecat_user_id  IS DISTINCT FROM OLD.revenuecat_user_id
    OR NEW.total_checkins      IS DISTINCT FROM OLD.total_checkins
    OR NEW.badge_count         IS DISTINCT FROM OLD.badge_count
    OR NEW.is_suspended        IS DISTINCT FROM OLD.is_suspended
    OR NEW.username_changed_at IS DISTINCT FROM OLD.username_changed_at
    OR NEW.created_at          IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'That part of your profile cannot be changed from the app';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_user_update ON public.users;
CREATE TRIGGER trg_guard_user_update
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.guard_user_update();


-- ──────────────────────────────────────────
-- FRIENDS: a new request always starts as 'pending'
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_friend_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.status := 'pending';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_friend_insert ON public.friends;
CREATE TRIGGER trg_guard_friend_insert
  BEFORE INSERT ON public.friends
  FOR EACH ROW EXECUTE FUNCTION public.guard_friend_insert();


-- ──────────────────────────────────────────
-- FRIENDS: on update, the person who got the request can only change the status
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_friend_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF NEW.id           IS DISTINCT FROM OLD.id
    OR NEW.requester_id IS DISTINCT FROM OLD.requester_id
    OR NEW.addressee_id IS DISTINCT FROM OLD.addressee_id
    OR NEW.created_at   IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'Only the status of a friend request can be changed';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_friend_update ON public.friends;
CREATE TRIGGER trg_guard_friend_update
  BEFORE UPDATE ON public.friends
  FOR EACH ROW EXECUTE FUNCTION public.guard_friend_update();


-- ──────────────────────────────────────────
-- EVENT CHECK-INS: no direct inserts from the app.
-- With no insert rule, the app is refused. A server function (service role)
-- will record QR-code check-ins later.
-- ──────────────────────────────────────────
DROP POLICY IF EXISTS "event_checkins: auth insert" ON public.event_checkins;
