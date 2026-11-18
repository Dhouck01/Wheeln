-- ============================================================
--  WHEELN — create_checkin(): save a check-in and its trails together
--
--  The app calls this one function (supabase.rpc('create_checkin', ...)).
--  It saves the post and every trail in a single transaction, so a problem
--  anywhere undoes the whole check-in and nothing is left half-saved.
--
--  It runs AS THE SIGNED-IN PERSON (SECURITY INVOKER), so every existing rule
--  still applies: the post guards, "same venue only", and "approved trail or
--  your own pending one". It works out who you are itself, so the app cannot
--  claim to be someone else. Badges are awarded by the existing triggers and
--  are linked to the new post (user_badges.post_id), which is how the app
--  finds out what a check-in just earned.
--
--  Arguments:
--    p_location_id        the venue (must be an approved place)
--    p_photo_url          the uploaded photo's public URL
--    p_message            optional text (blank becomes empty)
--    p_star_rating        overall stars for the venue, 1-5
--    p_difficulty_rating  overall difficulty for the venue, 1-5
--    p_trails             optional list, at most 10, like
--                         [{"course_id": "...", "star_rating": 4, "difficulty_rating": 3}]
--  Returns the new post's id.
--
--  Safe to re-run. Paste into the Supabase SQL editor and run once.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_checkin(
  p_location_id       UUID,
  p_photo_url         TEXT,
  p_message           TEXT,
  p_star_rating       INTEGER,
  p_difficulty_rating INTEGER,
  p_trails            JSONB DEFAULT '[]'::jsonb
) RETURNS UUID
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_me      UUID;
  v_post    UUID;
  v_trail   JSONB;
  v_stars   INTEGER;
  v_diff    INTEGER;
BEGIN
  v_me := public.current_user_id();
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Sign in to check in';
  END IF;
  IF p_location_id IS NULL THEN
    RAISE EXCEPTION 'Pick a place first';
  END IF;
  IF p_photo_url IS NULL OR btrim(p_photo_url) = '' THEN
    RAISE EXCEPTION 'Add a photo first';
  END IF;
  IF p_star_rating IS NULL OR p_star_rating NOT BETWEEN 1 AND 5
     OR p_difficulty_rating IS NULL OR p_difficulty_rating NOT BETWEEN 1 AND 5 THEN
    RAISE EXCEPTION 'Overall stars and difficulty must be 1 to 5';
  END IF;

  IF p_trails IS NULL THEN
    p_trails := '[]'::jsonb;
  END IF;
  IF jsonb_typeof(p_trails) <> 'array' THEN
    RAISE EXCEPTION 'Trails must be a list';
  END IF;
  IF jsonb_array_length(p_trails) > 10 THEN
    RAISE EXCEPTION 'You can add up to 10 trails to one check-in';
  END IF;

  INSERT INTO public.posts
    (user_id, location_id, photo_url, message, star_rating, difficulty_rating)
  VALUES
    (v_me, p_location_id, p_photo_url, NULLIF(btrim(p_message), ''),
     p_star_rating, p_difficulty_rating)
  RETURNING id INTO v_post;

  FOR v_trail IN SELECT value FROM jsonb_array_elements(p_trails) LOOP
    IF (v_trail ->> 'course_id') IS NULL THEN
      RAISE EXCEPTION 'Each trail needs a trail id';
    END IF;
    v_stars := (v_trail ->> 'star_rating')::integer;
    v_diff  := (v_trail ->> 'difficulty_rating')::integer;
    IF v_stars IS NULL OR v_stars NOT BETWEEN 1 AND 5
       OR v_diff IS NULL OR v_diff NOT BETWEEN 1 AND 5 THEN
      RAISE EXCEPTION 'Each trail needs stars and difficulty from 1 to 5';
    END IF;

    INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating)
    VALUES (v_post, (v_trail ->> 'course_id')::uuid, v_stars, v_diff);
  END LOOP;

  RETURN v_post;
END;
$$;

REVOKE ALL ON FUNCTION public.create_checkin(UUID, TEXT, TEXT, INTEGER, INTEGER, JSONB)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_checkin(UUID, TEXT, TEXT, INTEGER, INTEGER, JSONB)
  TO authenticated;
