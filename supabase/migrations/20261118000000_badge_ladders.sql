-- ============================================================
--  WHEELN — Badge ladders and automatic badge awarding
--
--  What this does:
--   1. Adds `badge_ladders` (12 ladders) and ladder + step columns on
--      `badge_definitions`.
--   2. Replaces the 12 old starter badges (not Early Adopter) with 160 ladder
--      badges generated from the lists below.
--   3. Awards badges automatically from the database when something happens:
--      a check-in, a trail attached, a like, a friend accepted, or a course
--      approved. A badge problem can never block a check-in.
--   4. Backfills badges for check-ins that already exist.
--   5. Adds `my_badge_progress()` (your number on each ladder) and an admin
--      tool `admin_recompute_badges()`.
--
--  Rules:
--   * Volume ladders count ONE visit per venue per calendar day (US Eastern).
--   * Road = track, autocross, karting, moto_track. Off-road = off_road_trail,
--     off_road_park, rock_crawl, overlanding, gravel_ride. Drag = drag_strip.
--     car_show, cars_and_coffee and other count only toward all-places ladders.
--   * Course Collector counts only APPROVED courses.
--   * Likes do not count your own likes on your own posts.
--   * Badges are permanent: deleting a check-in later never removes a badge.
--
--  Safe to re-run. It stops (changing nothing) if anyone has already earned
--  one of the old starter badges.
--
--  Handing out Early Adopter (manual badge, whenever you decide the window):
--    INSERT INTO public.user_badges (user_id, badge_id)
--    SELECT u.id, (SELECT id FROM public.badge_definitions WHERE slug = 'early_adopter')
--    FROM public.users u
--    WHERE u.created_at < '<cutoff date>'
--    ON CONFLICT (user_id, badge_id) DO NOTHING;
--
--  Recount one person after you clean up test data:
--    SELECT public.admin_recompute_badges('<user id>');
--  (leave the brackets empty to recount everyone)
-- ============================================================


-- ============================================================
-- 1. LADDER TABLE AND COLUMNS
-- ============================================================

DO $$ BEGIN
  CREATE TYPE ladder_metric_enum AS ENUM
    ('visits', 'venues', 'courses', 'states', 'likes_received', 'friends');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.badge_ladders (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug           TEXT NOT NULL UNIQUE,
  name           TEXT NOT NULL,
  metric         ladder_metric_enum NOT NULL,
  -- Which place types count. NULL = all places.
  location_types location_type_enum[],
  sort_order     INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.badge_ladders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "badge_ladders: public read" ON public.badge_ladders;
CREATE POLICY "badge_ladders: public read"
  ON public.badge_ladders FOR SELECT USING (true);

-- Ladder badges use the ladder's metric instead of the old threshold_type
ALTER TABLE public.badge_definitions ALTER COLUMN threshold_type DROP NOT NULL;
ALTER TABLE public.badge_definitions
  ADD COLUMN IF NOT EXISTS ladder_id UUID REFERENCES public.badge_ladders (id),
  ADD COLUMN IF NOT EXISTS tier      SMALLINT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_badge_definitions_ladder_tier
  ON public.badge_definitions (ladder_id, tier) WHERE ladder_id IS NOT NULL;


-- ============================================================
-- 2. REPLACE THE OLD STARTER BADGES (Early Adopter stays)
-- ============================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.user_badges ub
    JOIN public.badge_definitions bd ON bd.id = ub.badge_id
    WHERE bd.slug IN ('first_wheel','road_warrior','track_regular','century_driver',
                      'explorer','globe_trotter','track_rat','dirt_slinger',
                      'quarter_mile_club','weekend_warrior','five_star_rater','critic')
  ) THEN
    RAISE EXCEPTION 'Someone has already earned an old starter badge. Stopping so nothing is deleted.';
  END IF;
END $$;

DELETE FROM public.badge_definitions
WHERE slug IN ('first_wheel','road_warrior','track_regular','century_driver',
               'explorer','globe_trotter','track_rat','dirt_slinger',
               'quarter_mile_club','weekend_warrior','five_star_rater','critic');


-- ============================================================
-- 3. SEED THE 12 LADDERS AND THEIR 160 BADGES
-- ============================================================

DO $$
DECLARE
  r        RECORD;
  v_id     UUID;
  t        INTEGER;
  n        INTEGER;
  v_plural TEXT;
  v_name   TEXT;
  v_desc   TEXT;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('road_visits', 'Asphalt', 'visits',
        ARRAY['track','autocross','karting','moto_track']::location_type_enum[], 1,
        ARRAY[1,2,3,5,7,10,13,17,21,25,30,37,45,55,70,85,100,125,150,200],
        '{"5":"Green Flag","10":"Hot Lap","15":"Apex Hunter","20":"Checkered Flag"}'::jsonb,
        'road venues', 'category'),
      ('offroad_visits', 'Dirt', 'visits',
        ARRAY['off_road_trail','off_road_park','rock_crawl','overlanding','gravel_ride']::location_type_enum[], 2,
        ARRAY[1,2,3,5,7,10,13,17,21,25,30,37,45,55,70,85,100,125,150,200],
        '{"5":"Trailhead","10":"Mud Runner","15":"Rock Hopper","20":"Trail Boss"}'::jsonb,
        'off-road venues', 'category'),
      ('drag_visits', 'Quarter Mile', 'visits',
        ARRAY['drag_strip']::location_type_enum[], 3,
        ARRAY[1,2,3,5,7,10,13,17,21,25,30,37,45,55,70,85,100,125,150,200],
        '{"5":"Staging","10":"Burnout","15":"Redline","20":"Strip King"}'::jsonb,
        'drag strips', 'category'),
      ('all_visits', 'Odometer', 'visits',
        NULL::location_type_enum[], 4,
        ARRAY[1,2,3,5,8,12,18,25,35,50,65,80,100,150,200,300,400,500,750,1000],
        '{"5":"Rookie","10":"Regular","15":"Veteran","20":"Legend"}'::jsonb,
        'places', 'milestone'),
      ('road_venues', 'Circuit Hopper', 'venues',
        ARRAY['track','autocross','karting','moto_track']::location_type_enum[], 5,
        ARRAY[2,3,5,7,10,15,20,30,40,50],
        '{"5":"Pit Pass","10":"Grand Tour"}'::jsonb,
        'road venues', 'category'),
      ('offroad_venues', 'Trail Seeker', 'venues',
        ARRAY['off_road_trail','off_road_park','rock_crawl','overlanding','gravel_ride']::location_type_enum[], 6,
        ARRAY[2,3,5,7,10,15,20,30,40,50],
        '{"5":"Pathfinder","10":"Wayfarer"}'::jsonb,
        'off-road venues', 'category'),
      ('drag_venues', 'Strip Hopper', 'venues',
        ARRAY['drag_strip']::location_type_enum[], 7,
        ARRAY[2,3,5,7,10,15,20,30,40,50],
        '{"5":"Bracket Racer","10":"Hall of Strips"}'::jsonb,
        'drag strips', 'category'),
      ('all_venues', 'Explorer', 'venues',
        NULL::location_type_enum[], 8,
        ARRAY[2,3,5,7,10,15,20,30,40,50],
        '{"5":"Scout","10":"Globetrotter"}'::jsonb,
        'places', 'milestone'),
      ('courses', 'Course Collector', 'courses',
        NULL::location_type_enum[], 9,
        ARRAY[1,3,5,10,15,25,40,60,80,100],
        '{"5":"Trail Sampler","10":"Completionist"}'::jsonb,
        '', 'category'),
      ('states', 'Road Trip', 'states',
        NULL::location_type_enum[], 10,
        ARRAY[2,3,5,8,12,16,20,30,40,50],
        '{"5":"Border Hopper","10":"Coast to Coast"}'::jsonb,
        '', 'milestone'),
      ('likes', 'Crowd Favorite', 'likes_received',
        NULL::location_type_enum[], 11,
        ARRAY[5,10,25,50,100,250,500,1000,2500,5000],
        '{"5":"Fan Favorite","10":"Headliner"}'::jsonb,
        '', 'activity'),
      ('friends', 'Crew', 'friends',
        NULL::location_type_enum[], 12,
        ARRAY[1,3,5,10,15,25,50,100,150,250],
        '{"5":"Pit Crew","10":"Full Grid"}'::jsonb,
        '', 'activity')
    ) AS v(slug, name, metric, types, sort_order, thresholds, titles, noun, category)
  LOOP
    INSERT INTO public.badge_ladders (slug, name, metric, location_types, sort_order)
    VALUES (r.slug, r.name, r.metric::ladder_metric_enum, r.types, r.sort_order)
    ON CONFLICT (slug) DO UPDATE
      SET name = EXCLUDED.name,
          metric = EXCLUDED.metric,
          location_types = EXCLUDED.location_types,
          sort_order = EXCLUDED.sort_order
    RETURNING id INTO v_id;

    FOR t IN 1 .. array_length(r.thresholds, 1) LOOP
      n := r.thresholds[t];
      v_plural := CASE WHEN n = 1 THEN '' ELSE 's' END;
      v_name := COALESCE(r.titles ->> t::text, r.name || ' Level ' || t);
      v_desc := CASE r.metric
        WHEN 'visits'         THEN format('%s visit%s to %s (one counted per place per day).', n, v_plural, r.noun)
        WHEN 'venues'         THEN format('Check in at %s different %s.', n, r.noun)
        WHEN 'courses'        THEN format('Ride %s different approved trail%s or course%s.', n, v_plural, v_plural)
        WHEN 'states'         THEN format('Check in in %s different states.', n)
        WHEN 'likes_received' THEN format('Receive %s like%s from other riders.', n, v_plural)
        WHEN 'friends'        THEN format('Make %s friend%s.', n, v_plural)
      END;

      INSERT INTO public.badge_definitions
        (slug, name, description, category, threshold_type, threshold_value,
         location_type, ladder_id, tier)
      VALUES
        (r.slug || '_' || t, v_name, v_desc, r.category::badge_category_enum, NULL, n,
         NULL, v_id, t)
      ON CONFLICT (slug) DO UPDATE
        SET name = EXCLUDED.name,
            description = EXCLUDED.description,
            category = EXCLUDED.category,
            threshold_value = EXCLUDED.threshold_value,
            ladder_id = EXCLUDED.ladder_id,
            tier = EXCLUDED.tier;
    END LOOP;
  END LOOP;
END $$;


-- ============================================================
-- 4. COUNTING AND AWARDING
-- ============================================================

-- Your number for one metric (optionally limited to some place types)
CREATE OR REPLACE FUNCTION public.badge_metric_value(
  p_user UUID, p_metric ladder_metric_enum, p_types location_type_enum[]
) RETURNS INTEGER LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v INTEGER;
BEGIN
  IF p_metric = 'visits' THEN
    -- One visit per venue per Eastern-time calendar day
    SELECT count(*)::int INTO v FROM (
      SELECT DISTINCT p.location_id,
             (p.created_at AT TIME ZONE 'America/New_York')::date AS visit_day
      FROM public.posts p
      JOIN public.locations l ON l.id = p.location_id
      WHERE p.user_id = p_user
        AND p.is_deleted = false
        AND (p_types IS NULL OR l.type = ANY (p_types))
    ) s;
  ELSIF p_metric = 'venues' THEN
    SELECT count(DISTINCT p.location_id)::int INTO v
    FROM public.posts p
    JOIN public.locations l ON l.id = p.location_id
    WHERE p.user_id = p_user
      AND p.is_deleted = false
      AND (p_types IS NULL OR l.type = ANY (p_types));
  ELSIF p_metric = 'courses' THEN
    SELECT count(DISTINCT pc.course_id)::int INTO v
    FROM public.post_courses pc
    JOIN public.posts p   ON p.id = pc.post_id
    JOIN public.courses c ON c.id = pc.course_id
    WHERE p.user_id = p_user
      AND p.is_deleted = false
      AND c.status = 'approved';
  ELSIF p_metric = 'states' THEN
    SELECT count(DISTINCT l.country || '-' || l.state)::int INTO v
    FROM public.posts p
    JOIN public.locations l ON l.id = p.location_id
    WHERE p.user_id = p_user
      AND p.is_deleted = false
      AND l.state IS NOT NULL AND btrim(l.state) <> '';
  ELSIF p_metric = 'likes_received' THEN
    SELECT count(*)::int INTO v
    FROM public.likes k
    JOIN public.posts p ON p.id = k.post_id
    WHERE p.user_id = p_user
      AND p.is_deleted = false
      AND k.user_id <> p_user;          -- your own likes do not count
  ELSIF p_metric = 'friends' THEN
    SELECT count(*)::int INTO v
    FROM public.friends f
    WHERE f.status = 'accepted'
      AND (f.requester_id = p_user OR f.addressee_id = p_user);
  END IF;
  RETURN COALESCE(v, 0);
END;
$$;

-- Give a person every badge their number has reached on the ladders of one
-- metric. Returns how many new badges were awarded. Never takes badges away.
CREATE OR REPLACE FUNCTION public.award_ladder_badges(
  p_user UUID, p_metric ladder_metric_enum, p_post UUID DEFAULT NULL
) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r      RECORD;
  v      INTEGER;
  k      INTEGER;
  v_total INTEGER := 0;
BEGIN
  FOR r IN SELECT id, location_types FROM public.badge_ladders WHERE metric = p_metric LOOP
    v := public.badge_metric_value(p_user, p_metric, r.location_types);
    INSERT INTO public.user_badges (user_id, badge_id, post_id)
    SELECT p_user, bd.id, p_post
    FROM public.badge_definitions bd
    WHERE bd.ladder_id = r.id AND bd.is_active AND bd.threshold_value <= v
    ON CONFLICT (user_id, badge_id) DO NOTHING;
    GET DIAGNOSTICS k = ROW_COUNT;
    v_total := v_total + k;
  END LOOP;
  RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION public.award_all_badges(p_user UUID, p_post UUID DEFAULT NULL)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  m       ladder_metric_enum;
  v_total INTEGER := 0;
BEGIN
  FOREACH m IN ARRAY enum_range(NULL::ladder_metric_enum) LOOP
    v_total := v_total + public.award_ladder_badges(p_user, m, p_post);
  END LOOP;
  RETURN v_total;
END;
$$;

-- Your own number on each ladder (for the progress bars). Only you can ask.
CREATE OR REPLACE FUNCTION public.my_badge_progress()
RETURNS TABLE (ladder_slug TEXT, metric_value INTEGER)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT bl.slug,
         public.badge_metric_value(public.current_user_id(), bl.metric, bl.location_types)
  FROM public.badge_ladders bl
  ORDER BY bl.sort_order
$$;

-- Admin tool: wipe a person's LADDER badges (manual ones like Early Adopter
-- stay) and recount from their real data. No argument = everyone.
-- Returns how many badges were awarded.
CREATE OR REPLACE FUNCTION public.admin_recompute_badges(p_user UUID DEFAULT NULL)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  u       RECORD;
  v_total INTEGER := 0;
BEGIN
  FOR u IN SELECT id FROM public.users WHERE p_user IS NULL OR id = p_user LOOP
    DELETE FROM public.user_badges ub
    USING public.badge_definitions bd
    WHERE ub.badge_id = bd.id AND bd.ladder_id IS NOT NULL AND ub.user_id = u.id;

    UPDATE public.users
    SET badge_count = (SELECT count(*) FROM public.user_badges WHERE user_id = u.id)
    WHERE id = u.id;

    v_total := v_total + public.award_all_badges(u.id, NULL);
  END LOOP;
  RETURN v_total;
END;
$$;

-- The app may not run any of these except my_badge_progress()
REVOKE ALL ON FUNCTION public.badge_metric_value(UUID, ladder_metric_enum, location_type_enum[])
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.award_ladder_badges(UUID, ladder_metric_enum, UUID)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.award_all_badges(UUID, UUID)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_recompute_badges(UUID)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.my_badge_progress() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_badge_progress() TO authenticated;


-- ============================================================
-- 5. TRIGGERS (each one catches its own errors: a badge problem
--    only logs a warning and never blocks the check-in, like or friend)
-- ============================================================

-- A check-in is saved
CREATE OR REPLACE FUNCTION public.trg_award_after_post_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  BEGIN
    PERFORM public.award_ladder_badges(NEW.user_id, 'visits', NEW.id);
    PERFORM public.award_ladder_badges(NEW.user_id, 'venues', NEW.id);
    PERFORM public.award_ladder_badges(NEW.user_id, 'states', NEW.id);
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Badge award failed for post %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_award_badges_after_post_insert ON public.posts;
CREATE TRIGGER trg_award_badges_after_post_insert
  AFTER INSERT ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_after_post_insert();

-- A trail is attached to a check-in (or moved to another trail by a merge)
CREATE OR REPLACE FUNCTION public.trg_award_after_post_course()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user UUID;
BEGIN
  BEGIN
    SELECT user_id INTO v_user FROM public.posts WHERE id = NEW.post_id;
    IF v_user IS NOT NULL THEN
      PERFORM public.award_ladder_badges(v_user, 'courses', NEW.post_id);
    END IF;
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Badge award failed for trail on post %: %', NEW.post_id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_award_badges_after_post_course ON public.post_courses;
CREATE TRIGGER trg_award_badges_after_post_course
  AFTER INSERT OR UPDATE OF course_id ON public.post_courses
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_after_post_course();

-- Someone likes a post
CREATE OR REPLACE FUNCTION public.trg_award_after_like()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_owner UUID;
BEGIN
  BEGIN
    SELECT user_id INTO v_owner FROM public.posts WHERE id = NEW.post_id;
    IF v_owner IS NOT NULL AND v_owner <> NEW.user_id THEN
      PERFORM public.award_ladder_badges(v_owner, 'likes_received', NULL);
    END IF;
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Badge award failed for like on post %: %', NEW.post_id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_award_badges_after_like ON public.likes;
CREATE TRIGGER trg_award_badges_after_like
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_after_like();

-- A friend request becomes accepted
CREATE OR REPLACE FUNCTION public.trg_award_after_friend()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_became_accepted BOOLEAN := false;
BEGIN
  BEGIN
    IF NEW.status = 'accepted' THEN
      IF TG_OP = 'INSERT' THEN
        v_became_accepted := true;
      ELSE
        v_became_accepted := OLD.status IS DISTINCT FROM 'accepted';
      END IF;
    END IF;
    IF v_became_accepted THEN
      PERFORM public.award_ladder_badges(NEW.requester_id, 'friends', NULL);
      PERFORM public.award_ladder_badges(NEW.addressee_id, 'friends', NULL);
    END IF;
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Badge award failed for friend request %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_award_badges_after_friend ON public.friends;
CREATE TRIGGER trg_award_badges_after_friend
  AFTER INSERT OR UPDATE OF status ON public.friends
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_after_friend();

-- You approve a course -> everyone who rode it gets credit for it
CREATE OR REPLACE FUNCTION public.trg_award_after_course_approved()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  u RECORD;
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    FOR u IN
      SELECT DISTINCT p.user_id
      FROM public.post_courses pc
      JOIN public.posts p ON p.id = pc.post_id
      WHERE pc.course_id = NEW.id AND p.is_deleted = false
    LOOP
      BEGIN
        PERFORM public.award_ladder_badges(u.user_id, 'courses', NULL);
      EXCEPTION WHEN others THEN
        RAISE WARNING 'Badge award failed for course %: %', NEW.id, SQLERRM;
      END;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_award_badges_after_course_approved ON public.courses;
CREATE TRIGGER trg_award_badges_after_course_approved
  AFTER UPDATE OF status ON public.courses
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_after_course_approved();


-- ============================================================
-- 6. BACKFILL: award badges for check-ins that already exist
--    (the number it returns is how many badges were awarded)
-- ============================================================

SELECT public.admin_recompute_badges() AS badges_awarded;
