-- ============================================================
--  WHEELN — Test for 20261119000000_create_checkin_function.sql
--
--  How to use: paste this whole file into the Supabase SQL editor and run it.
--  It ends with a red "error" on purpose. The error message is the report:
--  the first line gives the totals and every line below should start with
--  PASS. The error also makes the database undo everything the test did, so
--  no real data is changed.
--
--  It makes its own test accounts, venues and trails. It needs nothing from you.
-- ============================================================

DO $$
DECLARE
  v_tu1 uuid := gen_random_uuid();  v_auth1 uuid := gen_random_uuid();
  v_tu2 uuid := gen_random_uuid();
  v_l1  uuid := gen_random_uuid();   -- track, TN
  v_l2  uuid := gen_random_uuid();   -- a different venue
  v_ca       uuid := gen_random_uuid();  -- approved trail at venue 1
  v_cpend    uuid := gen_random_uuid();  -- test user 1's own pending trail at venue 1
  v_ctheirs  uuid := gen_random_uuid();  -- test user 2's pending trail at venue 1
  v_cother   uuid := gen_random_uuid();  -- approved trail at venue 2
  v_call text := $q$SELECT public.create_checkin(%L::uuid, %L::text, %L::text, %L::integer, %L::integer, %L::jsonb)$q$;
  v_t_two  text;
  v_t_other text;
  v_t_theirs text;
  v_t_bad0 text;
  v_t_dup  text;
  v_t_11   text;
  v_t_noid text;
  steps   text[];
  i       integer;
  v_label text;
  v_sql   text;
  v_exp   text;
  v_bool  boolean;
  v_pass  integer := 0;
  v_bad   integer := 0;
  res     text := '';
BEGIN
  -- ---------- setup, as the admin ----------
  INSERT INTO public.users (id, auth_id, email, username, display_name) VALUES
    (v_tu1, v_auth1,           'zz-b4a-1@example.invalid', 'zz_b4a_1', 'Zz B4a 1'),
    (v_tu2, gen_random_uuid(), 'zz-b4a-2@example.invalid', 'zz_b4a_2', 'Zz B4a 2');
  INSERT INTO public.locations (id, name, type, state, latitude, longitude, admin_approved) VALUES
    (v_l1, 'Zz B4a Track',   'track', 'TN', 36, -84, true),
    (v_l2, 'Zz B4a Track 2', 'track', 'KY', 37, -85, true);
  INSERT INTO public.courses (id, location_id, name, status, created_by_user_id) VALUES
    (v_ca,      v_l1, 'Zz B4a Trail A',      'approved', NULL),
    (v_cpend,   v_l1, 'Zz B4a My Pending',   'pending',  v_tu1),
    (v_ctheirs, v_l1, 'Zz B4a Their Pending','pending',  v_tu2),
    (v_cother,  v_l2, 'Zz B4a Other Venue',  'approved', NULL);

  v_t_two := jsonb_build_array(
      jsonb_build_object('course_id', v_ca,    'star_rating', 5, 'difficulty_rating', 4),
      jsonb_build_object('course_id', v_cpend, 'star_rating', 3, 'difficulty_rating', 2))::text;
  v_t_other := jsonb_build_array(
      jsonb_build_object('course_id', v_ca,     'star_rating', 4, 'difficulty_rating', 3),
      jsonb_build_object('course_id', v_cother, 'star_rating', 4, 'difficulty_rating', 3))::text;
  v_t_theirs := jsonb_build_array(
      jsonb_build_object('course_id', v_ctheirs, 'star_rating', 4, 'difficulty_rating', 3))::text;
  v_t_bad0 := jsonb_build_array(
      jsonb_build_object('course_id', v_ca, 'star_rating', 0, 'difficulty_rating', 3))::text;
  v_t_dup := jsonb_build_array(
      jsonb_build_object('course_id', v_ca, 'star_rating', 4, 'difficulty_rating', 3),
      jsonb_build_object('course_id', v_ca, 'star_rating', 5, 'difficulty_rating', 5))::text;
  SELECT jsonb_agg(jsonb_build_object('course_id', v_ca, 'star_rating', 4, 'difficulty_rating', 3))::text
    INTO v_t_11 FROM generate_series(1, 11);
  v_t_noid := jsonb_build_array(
      jsonb_build_object('star_rating', 4, 'difficulty_rating', 3))::text;

  -- ---------- the steps: label, sql, what to expect ----------
  -- expect ''      -> must succeed
  -- expect 'TRUE'  -> sql is a SELECT that must return true
  -- anything else  -> must fail, and the error must contain that text
  -- label 'ROLE'   -> switch who we are: u1 (test user 1 as the app), anon, or admin
  steps := ARRAY[
    'ROLE', 'u1', '',

    'a check-in with no trails saves',
      format(v_call, v_l1, 'https://example.invalid/a.jpg', 'zz-b4a-1', 4, 3, '[]'), '',
    'it is stored under me, at that venue, with those ratings',
      format($q$SELECT count(*) = 1 FROM public.posts
                WHERE message = 'zz-b4a-1' AND user_id = %L AND location_id = %L
                  AND star_rating = 4 AND difficulty_rating = 3$q$, v_tu1, v_l1), 'TRUE',
    'a check-in with two trails saves (one approved, one my own pending)',
      format(v_call, v_l1, 'https://example.invalid/b.jpg', 'zz-b4a-2', 5, 4, v_t_two), '',
    'both trails were saved with their own ratings',
      format($q$SELECT (SELECT count(*) FROM public.post_courses pc JOIN public.posts p ON p.id = pc.post_id
                        WHERE p.message = 'zz-b4a-2') = 2
                  AND EXISTS (SELECT 1 FROM public.post_courses pc JOIN public.posts p ON p.id = pc.post_id
                        WHERE p.message = 'zz-b4a-2' AND pc.course_id = %L AND pc.star_rating = 5 AND pc.difficulty_rating = 4)
                  AND EXISTS (SELECT 1 FROM public.post_courses pc JOIN public.posts p ON p.id = pc.post_id
                        WHERE p.message = 'zz-b4a-2' AND pc.course_id = %L AND pc.star_rating = 3 AND pc.difficulty_rating = 2)$q$,
             v_ca, v_cpend), 'TRUE',
    'the trail averages updated (1 ride, 5.00 stars, 4.00 difficulty)',
      format($q$SELECT total_checkins = 1 AND avg_rating = 5.00 AND avg_difficulty = 4.00
                FROM public.courses WHERE id = %L$q$, v_ca), 'TRUE',
    'a blank message is stored as empty',
      format(v_call, v_l1, 'https://example.invalid/blank.jpg', '   ', 3, 3, '[]'), '',
    'the blank message is really empty (NULL)',
      $q$SELECT message IS NULL FROM public.posts WHERE photo_url = 'https://example.invalid/blank.jpg'$q$, 'TRUE',

    -- ----- badges are linked to the check-in that earned them -----
    'the first check-in earned Asphalt level 1, linked to that post',
      format($q$SELECT EXISTS (SELECT 1 FROM public.user_badges ub
                  JOIN public.badge_definitions bd ON bd.id = ub.badge_id
                  JOIN public.posts p ON p.id = ub.post_id
                  WHERE ub.user_id = %L AND bd.slug = 'road_visits_1' AND p.message = 'zz-b4a-1')$q$, v_tu1), 'TRUE',
    'the trail check-in earned Course Collector level 1, linked to that post',
      format($q$SELECT EXISTS (SELECT 1 FROM public.user_badges ub
                  JOIN public.badge_definitions bd ON bd.id = ub.badge_id
                  JOIN public.posts p ON p.id = ub.post_id
                  WHERE ub.user_id = %L AND bd.slug = 'courses_1' AND p.message = 'zz-b4a-2')$q$, v_tu1), 'TRUE',

    -- ----- problems undo the whole check-in -----
    'a trail from a different venue is refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-a', 4, 3, v_t_other), 'row-level security',
    'someone else''s pending trail is refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-b', 4, 3, v_t_theirs), 'row-level security',
    'overall stars of 6 are refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-c', 6, 3, '[]'), 'Overall',
    'a trail rating of 0 is refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-d', 4, 3, v_t_bad0), 'Each trail needs stars',
    'eleven trails are refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-e', 4, 3, v_t_11), 'up to 10',
    'the same trail twice is refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-f', 4, 3, v_t_dup), 'duplicate key',
    'no venue is refused',
      format(v_call, NULL, 'https://example.invalid/f.jpg', 'zz-b4a-fail-g', 4, 3, '[]'), 'Pick a place',
    'no photo is refused',
      format(v_call, v_l1, '', 'zz-b4a-fail-h', 4, 3, '[]'), 'Add a photo',
    'trails that are not a list are refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-i', 4, 3, '{}'), 'must be a list',
    'a trail with no id is refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-fail-j', 4, 3, v_t_noid), 'trail id',
    'a message over 500 characters is refused',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', repeat('x', 501), 4, 3, '[]'), 'check constraint',
    'none of the refused check-ins left a post behind',
      $q$SELECT count(*) = 0 FROM public.posts
         WHERE message LIKE 'zz-b4a-fail-%' OR message LIKE 'xxxxxxxxxx%'$q$, 'TRUE',
    'and no stray trail rows were left on the approved trail (still 1 ride)',
      format($q$SELECT total_checkins = 1 FROM public.courses WHERE id = %L$q$, v_ca), 'TRUE',

    -- ----- who may call it -----
    'ROLE', 'anon', '',
    'a signed-out caller cannot run it',
      format(v_call, v_l1, 'https://example.invalid/f.jpg', 'zz-b4a-anon', 4, 3, '[]'), 'permission denied'
  ];

  -- ---------- run the steps ----------
  FOR i IN 0 .. (array_length(steps, 1) / 3 - 1) LOOP
    v_label := steps[i * 3 + 1];
    v_sql   := steps[i * 3 + 2];
    v_exp   := steps[i * 3 + 3];

    IF v_label = 'ROLE' THEN
      RESET ROLE;
      IF v_sql = 'u1' THEN
        PERFORM set_config('request.jwt.claims',
          json_build_object('sub', v_auth1, 'role', 'authenticated')::text, true);
        SET LOCAL ROLE authenticated;
      ELSIF v_sql = 'anon' THEN
        PERFORM set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
        SET LOCAL ROLE anon;
      END IF;
      CONTINUE;
    END IF;

    BEGIN
      IF v_exp = 'TRUE' THEN
        EXECUTE v_sql INTO v_bool;
        IF v_bool IS TRUE THEN
          v_pass := v_pass + 1;  res := res || E'\nPASS: ' || v_label;
        ELSE
          v_bad := v_bad + 1;    res := res || E'\nFAIL (check was not true): ' || v_label;
        END IF;
      ELSE
        EXECUTE v_sql;
        IF v_exp = '' THEN
          v_pass := v_pass + 1;  res := res || E'\nPASS (allowed): ' || v_label;
        ELSE
          v_bad := v_bad + 1;    res := res || E'\nFAIL (was allowed): ' || v_label;
        END IF;
      END IF;
    EXCEPTION WHEN others THEN
      IF v_exp NOT IN ('', 'TRUE') AND SQLERRM LIKE '%' || v_exp || '%' THEN
        v_pass := v_pass + 1;  res := res || E'\nPASS (blocked): ' || v_label;
      ELSE
        v_bad := v_bad + 1;    res := res || E'\nUNEXPECTED ERROR: ' || v_label || ' -> ' || SQLERRM;
      END IF;
    END;
  END LOOP;

  -- Always end with an error so the database undoes everything above
  RAISE EXCEPTION E'TEST REPORT (this error is on purpose, nothing was saved). % passed, % need a look.%',
    v_pass, v_bad, res;
END;
$$;
