-- ============================================================
--  WHEELN — Lock down posts and comments
--
--  Problem: the "owner update" rules let a signed-in user edit ANY column
--  of their own post or comment (for example set like_count to 9999, or
--  rewrite a comment after it was posted), and the insert rules let a user
--  start a row with fake counters.
--
--  Fix: two small guard triggers per table. They only restrict normal app
--  users (roles "authenticated" and "anon"). The Supabase SQL editor, the
--  service role, and our own counter triggers (which are SECURITY DEFINER)
--  are not affected.
--
--  Safe to re-run. Paste into the Supabase SQL editor and run once.
-- ============================================================


-- ──────────────────────────────────────────
-- POSTS: on insert, counters and event fields start at their defaults
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_post_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.like_count       := 0;
    NEW.comment_count    := 0;
    NEW.is_deleted       := false;
    NEW.is_event_checkin := false;  -- event check-ins come from a server function
    NEW.event_id         := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_post_insert ON public.posts;
CREATE TRIGGER trg_guard_post_insert
  BEFORE INSERT ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.guard_post_insert();


-- ──────────────────────────────────────────
-- POSTS: on update, an owner may only change the message or delete (soft)
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_post_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF NEW.id               IS DISTINCT FROM OLD.id
    OR NEW.user_id          IS DISTINCT FROM OLD.user_id
    OR NEW.location_id      IS DISTINCT FROM OLD.location_id
    OR NEW.photo_url        IS DISTINCT FROM OLD.photo_url
    OR NEW.star_rating      IS DISTINCT FROM OLD.star_rating
    OR NEW.difficulty_rating IS DISTINCT FROM OLD.difficulty_rating
    OR NEW.is_event_checkin IS DISTINCT FROM OLD.is_event_checkin
    OR NEW.event_id         IS DISTINCT FROM OLD.event_id
    OR NEW.like_count       IS DISTINCT FROM OLD.like_count
    OR NEW.comment_count    IS DISTINCT FROM OLD.comment_count
    OR NEW.checkin_lat      IS DISTINCT FROM OLD.checkin_lat
    OR NEW.checkin_lng      IS DISTINCT FROM OLD.checkin_lng
    OR NEW.created_at       IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'Only the message of a post can be edited';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_post_update ON public.posts;
CREATE TRIGGER trg_guard_post_update
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.guard_post_update();


-- ──────────────────────────────────────────
-- COMMENTS: on insert, a new comment cannot start out deleted
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_comment_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.is_deleted := false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_comment_insert ON public.comments;
CREATE TRIGGER trg_guard_comment_insert
  BEFORE INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.guard_comment_insert();


-- ──────────────────────────────────────────
-- COMMENTS: on update, an owner may only delete (soft), not rewrite
-- ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_comment_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    IF NEW.id         IS DISTINCT FROM OLD.id
    OR NEW.user_id    IS DISTINCT FROM OLD.user_id
    OR NEW.post_id    IS DISTINCT FROM OLD.post_id
    OR NEW.message    IS DISTINCT FROM OLD.message
    OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'A comment can only be deleted, not edited';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_comment_update ON public.comments;
CREATE TRIGGER trg_guard_comment_update
  BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.guard_comment_update();
