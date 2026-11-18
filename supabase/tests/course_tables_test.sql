-- ============================================================
--  WHEELN — Test for 20261117000000_course_tables.sql
--
--  How to use: paste this whole file into the Supabase SQL editor and run it.
--  It ends with a red "error" on purpose. The error message is the report:
--  the first line gives the totals and every line below should start with
--  PASS. The error also makes the database undo everything the test did, so
--  no real data is changed.
--
--  Needs: two users (it uses your two oldest) and two approved places in
--  `locations` (your seeded places).
-- ============================================================

DO $$
DECLARE
  v_auth1 uuid;  v_u1 uuid;
  v_auth2 uuid;  v_u2 uuid;
  v_l1 uuid;     v_l2 uuid;
  v_lx uuid := gen_random_uuid();    -- an UNAPPROVED place
  v_lg uuid := gen_random_uuid();    -- place submitted by the app (guard test)
  v_ca uuid := gen_random_uuid();    -- trail A (the main test trail)
  v_cb uuid := gen_random_uuid();
  v_cc uuid := gen_random_uuid();
  v_cd uuid := gen_random_uuid();
  v_ce uuid := gen_random_uuid();
  v_cf uuid := gen_random_uuid();    -- the one that should be refused
  v_cother uuid := gen_random_uuid(); -- approved trail at the OTHER place
  v_cdup uuid := gen_random_uuid();   -- duplicate used for the merge test
  v_p1 uuid := gen_random_uuid();    -- check-in by user 1 at place 1
  v_p2 uuid := gen_random_uuid();    -- check-in by user 2 at place 1
  v_p3 uuid := gen_random_uuid();    -- second check-in by user 1 at place 1
  steps   text[];
  i       integer;
  v_label text;
  v_sql   text;
  v_exp   text;
  v_bool  boolean;
  v_rows  integer;
  v_pass  integer := 0;
  v_bad   integer := 0;
  res     text := '';
BEGIN
  -- ---------- setup, as the admin ----------
  SELECT auth_id, id INTO v_auth1, v_u1
    FROM public.users WHERE auth_id IS NOT NULL ORDER BY created_at LIMIT 1;
  SELECT auth_id, id INTO v_auth2, v_u2
    FROM public.users WHERE auth_id IS NOT NULL AND id <> v_u1 ORDER BY created_at LIMIT 1;
  SELECT id INTO v_l1 FROM public.locations WHERE admin_approved ORDER BY created_at LIMIT 1;
  SELECT id INTO v_l2 FROM public.locations WHERE admin_approved AND id <> v_l1 ORDER BY created_at LIMIT 1;

  IF v_u2 IS NULL THEN
    RAISE EXCEPTION 'This test needs two users. Sign up a second account first.';
  END IF;
  IF v_l2 IS NULL THEN
    RAISE EXCEPTION 'This test needs two approved places in the locations table.';
  END IF;

  INSERT INTO public.locations (id, name, type, latitude, longitude, admin_approved)
    VALUES (v_lx, 'Zz Unapproved Test Place', 'other', 36, -84, false);
  INSERT INTO public.courses (id, location_id, name, status) VALUES
    (v_cother, v_l2, 'Zz Other Venue Trail', 'approved'),
    (v_cdup,   v_l1, 'Zz Dup Trail',         'approved');
  INSERT INTO public.posts (id, user_id, location_id, photo_url, star_rating, difficulty_rating) VALUES
    (v_p1, v_u1, v_l1, 'https://example.invalid/x.jpg', 3, 3),
    (v_p2, v_u2, v_l1, 'https://example.invalid/x.jpg', 3, 3),
    (v_p3, v_u1, v_l1, 'https://example.invalid/x.jpg', 3, 3);

  -- ---------- the steps: label, sql, what to expect ----------
  -- expect ''      -> must succeed
  -- expect 'ZERO'  -> must succeed but change 0 rows (blocked quietly)
  -- expect 'TRUE'  -> sql is a SELECT that must return true
  -- anything else  -> must fail, and the error must contain that text
  -- label 'ROLE'   -> switch who we are: u1, u2 or admin
  steps := ARRAY[
    'ROLE', 'u1', '',

    'add a trail (fake status and counters are reset)',
      format($q$INSERT INTO public.courses (id, location_id, name, status, total_checkins, avg_rating, created_by_user_id)
                VALUES (%L, %L, '  Zz   Test Trail A ', 'approved', 99, 4.5, %L)$q$, v_ca, v_l1, v_u2), '',
    'new trail starts pending, zero counters, my name, tidy name',
      format($q$SELECT status = 'pending' AND total_checkins = 0 AND avg_rating = 0
                   AND created_by_user_id = %L AND name = 'Zz Test Trail A'
                FROM public.courses WHERE id = %L$q$, v_u1, v_ca), 'TRUE',
    'same name in other capitals is refused',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'zz test trail a')$q$, v_cf, v_l1),
      'duplicate key',
    'trail at an unapproved place is refused',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Anything')$q$, v_cf, v_lx),
      'row-level security',
    'add trail B',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Test Trail B')$q$, v_cb, v_l1), '',
    'add trail C',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Test Trail C')$q$, v_cc, v_l1), '',
    'add trail D',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Test Trail D')$q$, v_cd, v_l1), '',
    'add trail E (the 5th in 24 hours)',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Test Trail E')$q$, v_ce, v_l1), '',
    'the 6th add in 24 hours is refused',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Test Trail F')$q$, v_cf, v_l1),
      'up to 5',
    'changing a trail status from the app changes nothing',
      format($q$UPDATE public.courses SET status = 'approved' WHERE id = %L$q$, v_ca), 'ZERO',
    'deleting a trail from the app changes nothing',
      format($q$DELETE FROM public.courses WHERE id = %L$q$, v_ca), 'ZERO',
    'I can see my own 5 pending trails',
      format($q$SELECT count(*) = 5 FROM public.courses WHERE id IN (%L, %L, %L, %L, %L)$q$, v_ca, v_cb, v_cc, v_cd, v_ce), 'TRUE',

    'ROLE', 'u2', '',
    'another person cannot see my pending trails',
      format($q$SELECT count(*) = 0 FROM public.courses WHERE id IN (%L, %L, %L, %L, %L)$q$, v_ca, v_cb, v_cc, v_cd, v_ce), 'TRUE',

    'ROLE', 'admin', '',
    'admin approves trail A',
      format($q$UPDATE public.courses SET status = 'approved' WHERE id = %L$q$, v_ca), '',
    'admin removes trail E',
      format($q$UPDATE public.courses SET status = 'removed' WHERE id = %L$q$, v_ce), '',

    'ROLE', 'u2', '',
    'once approved, another person sees trail A (and only A)',
      format($q$SELECT count(*) = 1 FROM public.courses WHERE id IN (%L, %L, %L, %L, %L)$q$, v_ca, v_cb, v_cc, v_cd, v_ce), 'TRUE',

    'ROLE', 'u1', '',
    'a removed trail still counts toward the 24-hour limit',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Test Trail F')$q$, v_cf, v_l1),
      'up to 5',
    'attach approved trail A to my check-in with ratings',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 4, 3)$q$, v_p1, v_ca), '',
    'attach my own pending trail B to my check-in',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 2, 2)$q$, v_p1, v_cb), '',
    'attaching the same trail twice is refused',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 5, 5)$q$, v_p1, v_ca),
      'duplicate key',
    'a trail from a different place is refused',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 5, 5)$q$, v_p1, v_cother),
      'row-level security',
    'stars and difficulty are required',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, NULL, 3)$q$, v_p1, v_cc),
      'null value',
    'editing a trail rating from the app changes nothing',
      format($q$UPDATE public.post_courses SET star_rating = 1 WHERE post_id = %L$q$, v_p1), 'ZERO',
    'deleting a trail rating from the app changes nothing',
      format($q$DELETE FROM public.post_courses WHERE post_id = %L$q$, v_p1), 'ZERO',

    'ROLE', 'u2', '',
    'cannot attach a trail to someone else''s check-in',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 5, 5)$q$, v_p1, v_ca),
      'row-level security',
    'cannot attach someone else''s pending trail to my own check-in',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 3, 3)$q$, v_p2, v_cb),
      'row-level security',
    'attach approved trail A to my own check-in',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 2, 1)$q$, v_p2, v_ca), '',

    'ROLE', 'admin', '',
    'trail A averages: 2 rides, rating 3.00, difficulty 2.00',
      format($q$SELECT total_checkins = 2 AND avg_rating = 3.00 AND avg_difficulty = 2.00
                FROM public.courses WHERE id = %L$q$, v_ca), 'TRUE',
    'trail B averages: 1 ride, rating 2.00, difficulty 2.00',
      format($q$SELECT total_checkins = 1 AND avg_rating = 2.00 AND avg_difficulty = 2.00
                FROM public.courses WHERE id = %L$q$, v_cb), 'TRUE',
    'deleting a check-in (soft delete)',
      format($q$UPDATE public.posts SET is_deleted = true WHERE id = %L$q$, v_p2), '',
    'trail A averages drop the deleted check-in: 1 ride, 4.00, 3.00',
      format($q$SELECT total_checkins = 1 AND avg_rating = 4.00 AND avg_difficulty = 3.00
                FROM public.courses WHERE id = %L$q$, v_ca), 'TRUE',

    'ROLE', 'u1', '',
    'report a trail',
      format($q$INSERT INTO public.course_reports (course_id, reported_by_user_id, reason, note) VALUES (%L, %L, 'duplicate', 'test')$q$, v_ca, v_u1), '',
    'reporting the same trail twice is refused',
      format($q$INSERT INTO public.course_reports (course_id, reported_by_user_id, reason) VALUES (%L, %L, 'other')$q$, v_ca, v_u1),
      'duplicate key',
    'cannot file a report as someone else',
      format($q$INSERT INTO public.course_reports (course_id, reported_by_user_id, reason) VALUES (%L, %L, 'other')$q$, v_cdup, v_u2),
      'row-level security',

    'ROLE', 'u2', '',
    'report with a fake "resolved" time',
      format($q$INSERT INTO public.course_reports (course_id, reported_by_user_id, reason, resolved_at) VALUES (%L, %L, 'other', now())$q$, v_ca, v_u2), '',
    'the fake resolved time is cleared, and I only see my own report',
      format($q$SELECT (SELECT resolved_at IS NULL FROM public.course_reports WHERE course_id = %L AND reported_by_user_id = %L)
                   AND (SELECT count(*) = 1 FROM public.course_reports WHERE course_id = %L)$q$, v_ca, v_u2, v_ca), 'TRUE',

    'ROLE', 'u1', '',
    'the app cannot run the merge function',
      format($q$SELECT public.admin_merge_courses(%L, %L, 'x')$q$, v_cdup, v_ca), 'permission denied',
    'the app cannot run the recalculation function',
      format($q$SELECT public.recalc_course_stats(%L)$q$, v_ca), 'permission denied',
    'the app cannot read the merge log',
      $q$SELECT count(*) = 0 FROM public.course_merges$q$, 'TRUE',

    'ROLE', 'admin', '',
    'attach the duplicate trail to a check-in',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 5, 5)$q$, v_p3, v_cdup), '',
    'merge the duplicate into trail A',
      format($q$SELECT public.admin_merge_courses(%L, %L, 'test merge')$q$, v_cdup, v_ca), '',
    'after the merge: duplicate hidden, its ride moved to A, A has 2 rides',
      format($q$SELECT (SELECT status = 'removed' FROM public.courses WHERE id = %L)
                   AND (SELECT total_checkins = 2 FROM public.courses WHERE id = %L)
                   AND EXISTS (SELECT 1 FROM public.post_courses WHERE post_id = %L AND course_id = %L)$q$, v_cdup, v_ca, v_p3, v_ca), 'TRUE',
    'undo the merge',
      format($q$SELECT public.admin_undo_course_merge((SELECT id FROM public.course_merges WHERE removed_course_id = %L))$q$, v_cdup), '',
    'after the undo: duplicate approved again, ride back on it, A has 1 ride',
      format($q$SELECT (SELECT status = 'approved' FROM public.courses WHERE id = %L)
                   AND (SELECT total_checkins = 1 FROM public.courses WHERE id = %L)
                   AND EXISTS (SELECT 1 FROM public.post_courses WHERE post_id = %L AND course_id = %L)$q$, v_cdup, v_ca, v_p3, v_cdup), 'TRUE',

    'ROLE', 'u1', '',
    'submit a new place with fake counters and approved = true',
      format($q$INSERT INTO public.locations (id, name, type, latitude, longitude, total_checkins, avg_rating, admin_approved, submitted_by_user_id)
                VALUES (%L, 'Zz Guard Test Place', 'other', 36, -84, 99, 4.5, true, %L)$q$, v_lg, v_u2), '',
    'ROLE', 'admin', '',
    'the new place was reset: zero counters, not approved, my name on it',
      format($q$SELECT total_checkins = 0 AND avg_rating = 0 AND admin_approved = false AND submitted_by_user_id = %L
                FROM public.locations WHERE id = %L$q$, v_u1, v_lg), 'TRUE',

    'suspend user 1',
      format($q$UPDATE public.users SET is_suspended = true WHERE id = %L$q$, v_u1), '',
    'ROLE', 'u1', '',
    'a suspended person cannot add a trail',
      format($q$INSERT INTO public.courses (id, location_id, name) VALUES (%L, %L, 'Zz Suspended Try')$q$, v_cf, v_l1),
      'cannot add'
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
      ELSIF v_sql = 'u2' THEN
        PERFORM set_config('request.jwt.claims',
          json_build_object('sub', v_auth2, 'role', 'authenticated')::text, true);
        SET LOCAL ROLE authenticated;
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
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        IF v_exp = '' THEN
          v_pass := v_pass + 1;  res := res || E'\nPASS (allowed): ' || v_label;
        ELSIF v_exp = 'ZERO' THEN
          IF v_rows = 0 THEN
            v_pass := v_pass + 1;  res := res || E'\nPASS (nothing changed): ' || v_label;
          ELSE
            v_bad := v_bad + 1;    res := res || E'\nFAIL (changed ' || v_rows || ' rows): ' || v_label;
          END IF;
        ELSE
          v_bad := v_bad + 1;      res := res || E'\nFAIL (was allowed): ' || v_label;
        END IF;
      END IF;
    EXCEPTION WHEN others THEN
      IF v_exp NOT IN ('', 'ZERO', 'TRUE') AND SQLERRM LIKE '%' || v_exp || '%' THEN
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
