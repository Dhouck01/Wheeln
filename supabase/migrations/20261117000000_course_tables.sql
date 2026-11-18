-- ============================================================
--  WHEELN — Course tables (trails and courses inside a venue)
--
--  A "venue" is a row in `locations` (for example Windrock Park).
--  A "course" is a trail or course inside it (for example Sand Mountain).
--
--  New tables:
--    courses         one row per trail or course
--    post_courses    which trails a check-in rode, with stars and difficulty
--    course_reports  the "report" button (duplicate, wrong venue, ...)
--    course_merges   your log of merged duplicates, so a merge can be undone
--
--  Rules in short:
--    * Everyone sees approved courses. The person who added a course also
--      sees their own pending one. Nobody sees removed ones.
--    * App users can ADD a course (always starts as pending, counters at
--      zero, venue must be approved, at most 5 per rolling 24 hours, not
--      allowed when the account is suspended). They cannot edit or delete one.
--      Approve, fix typos and remove in the Supabase dashboard.
--    * A trail is attached to a check-in with both stars and difficulty
--      (1-5). Only the check-in's owner can attach, only at the same venue,
--      and only an approved trail or their own pending one.
--    * Course averages and ride counts are recalculated by the database.
--    * Also closes a hole: a newly submitted location always starts with
--      zero counters and unapproved.
--
--  Guards only restrict normal app users (roles "authenticated" and "anon").
--  The Supabase SQL editor and the service role are not affected, so you can
--  seed courses as approved with plain SQL.
--
--  Safe to re-run. Paste into the Supabase SQL editor and run once.
-- ============================================================


-- ============================================================
-- 1. ENUMS
-- ============================================================

DO $$ BEGIN
  CREATE TYPE course_status_enum AS ENUM ('pending', 'approved', 'removed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE course_report_reason_enum AS ENUM
    ('duplicate', 'wrong_venue', 'does_not_exist', 'other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ============================================================
-- 2. COURSES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.courses (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id         UUID NOT NULL
                        REFERENCES public.locations (id) ON DELETE CASCADE,
  name                TEXT NOT NULL CHECK (char_length(name) BETWEEN 2 AND 60),
  -- Only set when the course is a different kind than its venue
  -- (for example a drag strip inside a road course). NULL = same as venue.
  type                location_type_enum,
  status              course_status_enum NOT NULL DEFAULT 'pending',
  created_by_user_id  UUID REFERENCES public.users (id) ON DELETE SET NULL,
  avg_rating          NUMERIC(3,2) NOT NULL DEFAULT 0.00,
  avg_difficulty      NUMERIC(3,2) NOT NULL DEFAULT 0.00,
  total_checkins      INTEGER      NOT NULL DEFAULT 0,
  admin_notes         TEXT,
  created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- No two live courses at one venue may share a name (ignoring capitals)
CREATE UNIQUE INDEX IF NOT EXISTS idx_courses_unique_name
  ON public.courses (location_id, lower(name))
  WHERE status <> 'removed';

CREATE INDEX IF NOT EXISTS idx_courses_location_status
  ON public.courses (location_id, status);
CREATE INDEX IF NOT EXISTS idx_courses_created_by
  ON public.courses (created_by_user_id, created_at DESC);

DROP TRIGGER IF EXISTS trg_courses_updated_at ON public.courses;
CREATE TRIGGER trg_courses_updated_at
  BEFORE UPDATE ON public.courses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Tidy the name: trim the ends and squash repeated spaces
CREATE OR REPLACE FUNCTION public.normalize_course_name()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.name := regexp_replace(btrim(NEW.name), '\s+', ' ', 'g');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_courses_normalize_name ON public.courses;
CREATE TRIGGER trg_courses_normalize_name
  BEFORE INSERT OR UPDATE OF name ON public.courses
  FOR EACH ROW EXECUTE FUNCTION public.normalize_course_name();

-- How many courses has the signed-in person added in the last 24 hours?
-- SECURITY DEFINER so it also counts courses you have since removed.
CREATE OR REPLACE FUNCTION public.recent_course_adds_by_me()
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT count(*)::int
  FROM public.courses
  WHERE created_by_user_id = public.current_user_id()
    AND created_at > now() - interval '24 hours'
$$;

-- On insert by an app user: force safe starting values and enforce the limits
CREATE OR REPLACE FUNCTION public.guard_course_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_me UUID;
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    v_me := public.current_user_id();
    IF v_me IS NULL THEN
      RAISE EXCEPTION 'Sign in to add a trail or course';
    END IF;
    IF EXISTS (SELECT 1 FROM public.users WHERE id = v_me AND is_suspended) THEN
      RAISE EXCEPTION 'Your account cannot add trails or courses right now';
    END IF;
    IF public.recent_course_adds_by_me() >= 5 THEN
      RAISE EXCEPTION 'You can add up to 5 new trails or courses in 24 hours. Try again later.';
    END IF;
    NEW.created_by_user_id := v_me;
    NEW.status             := 'pending';
    NEW.avg_rating         := 0;
    NEW.avg_difficulty     := 0;
    NEW.total_checkins     := 0;
    NEW.admin_notes        := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_course_insert ON public.courses;
CREATE TRIGGER trg_guard_course_insert
  BEFORE INSERT ON public.courses
  FOR EACH ROW EXECUTE FUNCTION public.guard_course_insert();

ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "courses: read approved or own pending" ON public.courses;
DROP POLICY IF EXISTS "courses: insert at approved venue"     ON public.courses;

-- Approved courses are public. A person also sees their own pending course.
CREATE POLICY "courses: read approved or own pending"
  ON public.courses FOR SELECT
  USING (
    status = 'approved'
    OR (status = 'pending' AND created_by_user_id = public.current_user_id())
  );

-- Signed-in users can add a course, but only at an approved venue.
-- (No update or delete policy: only you, in the dashboard, change courses.)
CREATE POLICY "courses: insert at approved venue"
  ON public.courses FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.locations l
      WHERE l.id = courses.location_id AND l.admin_approved = true
    )
  );


-- ============================================================
-- 3. POST_COURSES (trails ridden during a check-in)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.post_courses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id           UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  course_id         UUID NOT NULL REFERENCES public.courses (id) ON DELETE CASCADE,
  star_rating       SMALLINT NOT NULL CHECK (star_rating BETWEEN 1 AND 5),
  difficulty_rating SMALLINT NOT NULL CHECK (difficulty_rating BETWEEN 1 AND 5),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (post_id, course_id)   -- a trail can be attached to a check-in once
);

CREATE INDEX IF NOT EXISTS idx_post_courses_course_id ON public.post_courses (course_id);

ALTER TABLE public.post_courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_courses: read with visible post" ON public.post_courses;
DROP POLICY IF EXISTS "post_courses: owner insert"           ON public.post_courses;

-- Visible whenever the check-in itself is visible (the posts rules apply here)
CREATE POLICY "post_courses: read with visible post"
  ON public.post_courses FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.posts p WHERE p.id = post_courses.post_id)
  );

-- Only the owner of the check-in can attach a trail, the trail must be at the
-- same venue as the check-in, and it must be one the person is allowed to see
-- (approved, or their own pending one: the courses rules apply here).
CREATE POLICY "post_courses: owner insert"
  ON public.post_courses FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.posts p
      JOIN public.courses c ON c.location_id = p.location_id
      WHERE p.id = post_courses.post_id
        AND p.user_id = public.current_user_id()
        AND c.id = post_courses.course_id
    )
  );
-- (No update or delete policy: ratings cannot be edited from the app.)


-- ============================================================
-- 4. COURSE STATS (average rating, average difficulty, ride count)
--    Recalculated from scratch each time, so the numbers cannot drift.
-- ============================================================

CREATE OR REPLACE FUNCTION public.recalc_course_stats(p_course_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.courses c
  SET
    total_checkins = s.n,
    avg_rating     = COALESCE(s.r, 0),
    avg_difficulty = COALESCE(s.d, 0)
  FROM (
    SELECT
      count(*)::int                              AS n,
      ROUND(AVG(pc.star_rating)::numeric, 2)       AS r,
      ROUND(AVG(pc.difficulty_rating)::numeric, 2) AS d
    FROM public.post_courses pc
    JOIN public.posts p ON p.id = pc.post_id
    WHERE pc.course_id = p_course_id
      AND p.is_deleted = false
  ) s
  WHERE c.id = p_course_id;
END;
$$;

-- Only the triggers and your SQL editor should run this, not the app
REVOKE ALL ON FUNCTION public.recalc_course_stats(UUID) FROM PUBLIC, anon, authenticated;

-- A trail is attached or removed -> recalculate that course
CREATE OR REPLACE FUNCTION public.trg_post_course_changed()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.recalc_course_stats(OLD.course_id);
    RETURN OLD;
  END IF;
  PERFORM public.recalc_course_stats(NEW.course_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_post_course_changed ON public.post_courses;
CREATE TRIGGER trg_after_post_course_changed
  AFTER INSERT OR DELETE ON public.post_courses
  FOR EACH ROW EXECUTE FUNCTION public.trg_post_course_changed();

-- A check-in is deleted (or restored) -> recalculate every trail on it
CREATE OR REPLACE FUNCTION public.trg_course_stats_post_deleted_flag()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN
    PERFORM public.recalc_course_stats(pc.course_id)
    FROM public.post_courses pc
    WHERE pc.post_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_post_deleted_flag_course_stats ON public.posts;
CREATE TRIGGER trg_after_post_deleted_flag_course_stats
  AFTER UPDATE OF is_deleted ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.trg_course_stats_post_deleted_flag();


-- ============================================================
-- 5. COURSE REPORTS (the report button)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.course_reports (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id             UUID NOT NULL REFERENCES public.courses (id) ON DELETE CASCADE,
  reported_by_user_id   UUID NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
  reason                course_report_reason_enum NOT NULL,
  note                  TEXT CHECK (char_length(note) <= 300),
  -- For "duplicate": which course is the original
  duplicate_of_course_id UUID REFERENCES public.courses (id) ON DELETE SET NULL,
  resolved_at           TIMESTAMPTZ,   -- you fill this in once handled
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (course_id, reported_by_user_id)   -- one report per person per course
);

CREATE INDEX IF NOT EXISTS idx_course_reports_open
  ON public.course_reports (created_at DESC) WHERE resolved_at IS NULL;

CREATE OR REPLACE FUNCTION public.guard_course_report_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.resolved_at := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_course_report_insert ON public.course_reports;
CREATE TRIGGER trg_guard_course_report_insert
  BEFORE INSERT ON public.course_reports
  FOR EACH ROW EXECUTE FUNCTION public.guard_course_report_insert();

ALTER TABLE public.course_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "course_reports: read own"   ON public.course_reports;
DROP POLICY IF EXISTS "course_reports: insert own" ON public.course_reports;

CREATE POLICY "course_reports: read own"
  ON public.course_reports FOR SELECT
  USING (reported_by_user_id = public.current_user_id());

CREATE POLICY "course_reports: insert own"
  ON public.course_reports FOR INSERT
  WITH CHECK (
    reported_by_user_id = public.current_user_id()
    AND EXISTS (SELECT 1 FROM public.courses c WHERE c.id = course_reports.course_id)
  );
-- You read every report in the Supabase dashboard (Table Editor).


-- ============================================================
-- 6. COURSE MERGES (your log, so a merge can be undone)
--    RLS is on with no policies: the app cannot read or write this table.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.course_merges (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  removed_course_id     UUID NOT NULL REFERENCES public.courses (id),
  kept_course_id        UUID NOT NULL REFERENCES public.courses (id),
  prior_status          course_status_enum NOT NULL,  -- status before the merge, for undo
  reason                TEXT NOT NULL,
  moved_post_course_ids UUID[] NOT NULL DEFAULT '{}', -- exactly which rows moved
  merged_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  undone_at             TIMESTAMPTZ
);

ALTER TABLE public.course_merges ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 7. MERGE AND UNDO (run these yourself in the SQL editor)
-- ============================================================

-- Merge a duplicate (p_removed) into the original (p_kept).
--   * both must be at the same venue; the original must be approved
--   * trail rows move to the original (a check-in that already has both keeps
--     its row on the original and the duplicate row stays on the hidden copy)
--   * the duplicate becomes 'removed' and its open reports are marked resolved
-- Returns the id of the merge log row (keep it if you may want to undo).
CREATE OR REPLACE FUNCTION public.admin_merge_courses(
  p_removed UUID, p_kept UUID, p_reason TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_removed  public.courses%ROWTYPE;
  v_kept     public.courses%ROWTYPE;
  v_moved    UUID[];
  v_merge_id UUID;
BEGIN
  IF p_reason IS NULL OR btrim(p_reason) = '' THEN
    RAISE EXCEPTION 'Give a reason for the merge';
  END IF;
  IF p_removed = p_kept THEN
    RAISE EXCEPTION 'Cannot merge a course into itself';
  END IF;

  SELECT * INTO v_removed FROM public.courses WHERE id = p_removed FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Duplicate course not found'; END IF;
  SELECT * INTO v_kept FROM public.courses WHERE id = p_kept FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Original course not found'; END IF;

  IF v_removed.location_id <> v_kept.location_id THEN
    RAISE EXCEPTION 'Both courses must be at the same venue';
  END IF;
  IF v_removed.status = 'removed' THEN
    RAISE EXCEPTION 'The duplicate is already removed';
  END IF;
  IF v_kept.status <> 'approved' THEN
    RAISE EXCEPTION 'The original must be an approved course';
  END IF;

  WITH moved AS (
    UPDATE public.post_courses pc
    SET course_id = p_kept
    WHERE pc.course_id = p_removed
      AND NOT EXISTS (
        SELECT 1 FROM public.post_courses x
        WHERE x.post_id = pc.post_id AND x.course_id = p_kept
      )
    RETURNING pc.id
  )
  SELECT COALESCE(array_agg(id), ARRAY[]::UUID[]) INTO v_moved FROM moved;

  INSERT INTO public.course_merges
    (removed_course_id, kept_course_id, prior_status, reason, moved_post_course_ids)
  VALUES
    (p_removed, p_kept, v_removed.status, p_reason, v_moved)
  RETURNING id INTO v_merge_id;

  UPDATE public.courses SET status = 'removed' WHERE id = p_removed;
  UPDATE public.course_reports SET resolved_at = now()
    WHERE course_id = p_removed AND resolved_at IS NULL;

  PERFORM public.recalc_course_stats(p_removed);
  PERFORM public.recalc_course_stats(p_kept);
  RETURN v_merge_id;
END;
$$;

-- Undo a merge: put the moved rows back and restore the duplicate's old status.
-- (Reports that were marked resolved by the merge stay resolved.)
CREATE OR REPLACE FUNCTION public.admin_undo_course_merge(p_merge_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_m public.course_merges%ROWTYPE;
BEGIN
  SELECT * INTO v_m FROM public.course_merges WHERE id = p_merge_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Merge not found'; END IF;
  IF v_m.undone_at IS NOT NULL THEN RAISE EXCEPTION 'This merge was already undone'; END IF;

  UPDATE public.post_courses
  SET course_id = v_m.removed_course_id
  WHERE id = ANY (v_m.moved_post_course_ids)
    AND course_id = v_m.kept_course_id;

  UPDATE public.courses SET status = v_m.prior_status WHERE id = v_m.removed_course_id;
  UPDATE public.course_merges SET undone_at = now() WHERE id = p_merge_id;

  PERFORM public.recalc_course_stats(v_m.removed_course_id);
  PERFORM public.recalc_course_stats(v_m.kept_course_id);
END;
$$;

-- Supabase lets the app call any function in "public" by default. Not these.
REVOKE ALL ON FUNCTION public.admin_merge_courses(UUID, UUID, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_undo_course_merge(UUID)         FROM PUBLIC, anon, authenticated;


-- ============================================================
-- 8. LOCATIONS: a newly submitted place cannot start with fake counters
-- ============================================================

CREATE OR REPLACE FUNCTION public.guard_location_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.avg_rating           := 0;
    NEW.avg_difficulty       := 0;
    NEW.total_checkins       := 0;
    NEW.admin_approved       := false;
    NEW.admin_notes          := NULL;
    NEW.submitted_by_user_id := public.current_user_id();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_location_insert ON public.locations;
CREATE TRIGGER trg_guard_location_insert
  BEFORE INSERT ON public.locations
  FOR EACH ROW EXECUTE FUNCTION public.guard_location_insert();
