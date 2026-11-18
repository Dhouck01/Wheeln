-- ============================================================
--  WHEELN — Test for 20261118000000_badge_ladders.sql
--
--  How to use: paste this whole file into the Supabase SQL editor and run it.
--  It ends with a red "error" on purpose. The error message is the report:
--  the first line gives the totals and every line below should start with
--  PASS. The error also makes the database undo everything the test did, so
--  no real data is changed.
--
--  It makes its own two test accounts and five test venues, so your real
--  check-ins do not affect the numbers. It needs nothing from you.
-- ============================================================

DO $$
DECLARE
  v_tu1 uuid := gen_random_uuid();   v_auth1 uuid := gen_random_uuid();
  v_tu2 uuid := gen_random_uuid();
  v_road   uuid := gen_random_uuid();  -- track, TN
  v_road2  uuid := gen_random_uuid();  -- autocross, KY
  v_off    uuid := gen_random_uuid();  -- off-road trail, TN
  v_drag   uuid := gen_random_uuid();  -- drag strip, OH
  v_other  uuid := gen_random_uuid();  -- car show, TN (all-places ladders only)
  v_cpend  uuid := gen_random_uuid();  -- a pending trail at the off-road venue
  v_p1 uuid := gen_random_uuid();  v_p2 uuid := gen_random_uuid();
  v_p3 uuid := gen_random_uuid();  v_p4 uuid := gen_random_uuid();
  v_p5 uuid := gen_random_uuid();  v_p6 uuid := gen_random_uuid();
  v_p7 uuid := gen_random_uuid();  v_p8 uuid := gen_random_uuid();
  v_p14 uuid := gen_random_uuid();
  v_has text := $q$SELECT EXISTS (SELECT 1 FROM public.user_badges ub
                    JOIN public.badge_definitions bd ON bd.id = ub.badge_id
                    WHERE ub.user_id = %L AND bd.slug = %L)$q$;
  v_not text := $q$SELECT NOT EXISTS (SELECT 1 FROM public.user_badges ub
                    JOIN public.badge_definitions bd ON bd.id = ub.badge_id
                    WHERE ub.user_id = %L AND bd.slug = %L)$q$;
  v_post text := $q$INSERT INTO public.posts (id, user_id, location_id, photo_url, star_rating, difficulty_rating, created_at)
                    VALUES (%L, %L, %L, 'https://example.invalid/x.jpg', 3, 3, %L)$q$;
  v_count text := $q$SELECT u.badge_count = (SELECT count(*) FROM public.user_badges WHERE user_id = u.id)
                     FROM public.users u WHERE u.id = %L$q$;
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
  INSERT INTO public.users (id, auth_id, email, username, display_name) VALUES
    (v_tu1, v_auth1,          'zz-badge-1@example.invalid', 'zz_badge_1', 'Zz Badge 1'),
    (v_tu2, gen_random_uuid(), 'zz-badge-2@example.invalid', 'zz_badge_2', 'Zz Badge 2');

  INSERT INTO public.locations (id, name, type, state, latitude, longitude, admin_approved) VALUES
    (v_road,  'Zz Test Track',      'track',          'TN', 36, -84, true),
    (v_road2, 'Zz Test Autocross',  'autocross',      'KY', 37, -85, true),
    (v_off,   'Zz Test Trail Park', 'off_road_trail', 'TN', 36, -84, true),
    (v_drag,  'Zz Test Drag Strip', 'drag_strip',     'OH', 40, -83, true),
    (v_other, 'Zz Test Car Show',   'car_show',       'TN', 36, -84, true);

  INSERT INTO public.courses (id, location_id, name, status)
    VALUES (v_cpend, v_off, 'Zz Pending Trail', 'pending');

  -- ---------- the steps: label, sql, what to expect ----------
  -- expect ''      -> must succeed
  -- expect 'TRUE'  -> sql is a SELECT that must return true
  -- anything else  -> must fail, and the error must contain that text
  -- label 'ROLE'   -> switch who we are: u1 (test user 1 as the app) or admin
  steps := ARRAY[
    'ROLE', 'admin', '',

    -- ----- the seed -----
    'there are 12 ladders',
      $q$SELECT count(*) = 12 FROM public.badge_ladders$q$, 'TRUE',
    'there are 160 ladder badges',
      $q$SELECT count(*) = 160 FROM public.badge_definitions WHERE ladder_id IS NOT NULL$q$, 'TRUE',
    'four ladders have 20 steps',
      $q$SELECT count(*) = 4 FROM (SELECT ladder_id FROM public.badge_definitions
         WHERE ladder_id IS NOT NULL GROUP BY ladder_id HAVING count(*) = 20) s$q$, 'TRUE',
    'every ladder has steps 1..N with no gaps',
      $q$SELECT bool_and(mn = 1 AND mx = cnt) FROM (SELECT min(tier) mn, max(tier) mx, count(*) cnt
         FROM public.badge_definitions WHERE ladder_id IS NOT NULL GROUP BY ladder_id) s$q$, 'TRUE',
    'the number needed rises at every step',
      $q$SELECT NOT EXISTS (SELECT 1 FROM public.badge_definitions a
         JOIN public.badge_definitions b ON b.ladder_id = a.ladder_id AND b.tier = a.tier + 1
         WHERE b.threshold_value <= a.threshold_value)$q$, 'TRUE',
    'the 12 old starter badges are gone and Early Adopter is kept',
      $q$SELECT NOT EXISTS (SELECT 1 FROM public.badge_definitions WHERE slug IN
           ('first_wheel','road_warrior','track_regular','century_driver','explorer','globe_trotter',
            'track_rat','dirt_slinger','quarter_mile_club','weekend_warrior','five_star_rater','critic'))
         AND EXISTS (SELECT 1 FROM public.badge_definitions WHERE slug = 'early_adopter')$q$, 'TRUE',
    'special titles are in place (Asphalt level 5 is Green Flag)',
      $q$SELECT name = 'Green Flag' FROM public.badge_definitions WHERE slug = 'road_visits_5'$q$, 'TRUE',
    'plain badges are named by ladder and level',
      $q$SELECT name = 'Dirt Level 3' FROM public.badge_definitions WHERE slug = 'offroad_visits_3'$q$, 'TRUE',

    -- ----- one visit per venue per Eastern day -----
    'first check-in at a road venue',
      format(v_post, v_p1, v_tu1, v_road, '2026-03-10 15:00:00+00'), '',
    'earns Asphalt level 1', format(v_has, v_tu1, 'road_visits_1'), 'TRUE',
    'earns Odometer level 1', format(v_has, v_tu1, 'all_visits_1'), 'TRUE',
    'second check-in, same venue, same day',
      format(v_post, v_p2, v_tu1, v_road, '2026-03-10 20:00:00+00'), '',
    'still one visit: no Asphalt level 2', format(v_not, v_tu1, 'road_visits_2'), 'TRUE',
    'late evening Eastern time (already the next day in UTC), same venue',
      format(v_post, v_p3, v_tu1, v_road, '2026-03-11 02:00:00+00'), '',
    'still the same Eastern day: no Asphalt level 2', format(v_not, v_tu1, 'road_visits_2'), 'TRUE',
    'a check-in on the next Eastern day',
      format(v_post, v_p4, v_tu1, v_road, '2026-03-11 12:00:00+00'), '',
    'second visit: Asphalt level 2', format(v_has, v_tu1, 'road_visits_2'), 'TRUE',
    'second visit: Odometer level 2', format(v_has, v_tu1, 'all_visits_2'), 'TRUE',

    -- ----- place types go to the right ladders -----
    'check-in at a car show',
      format(v_post, v_p5, v_tu1, v_other, '2026-03-12 12:00:00+00'), '',
    'car show counts for all places (3 visits) but not road (2)',
      format($q$SELECT public.badge_metric_value(%L, 'visits', NULL) = 3
                  AND public.badge_metric_value(%L, 'visits',
                      ARRAY['track','autocross','karting','moto_track']::location_type_enum[]) = 2$q$, v_tu1, v_tu1), 'TRUE',
    'Odometer level 3 earned, Asphalt level 3 not yet',
      format(v_has, v_tu1, 'all_visits_3'), 'TRUE',
    'no Asphalt level 3 yet', format(v_not, v_tu1, 'road_visits_3'), 'TRUE',
    'check-in at a drag strip',
      format(v_post, v_p6, v_tu1, v_drag, '2026-03-13 12:00:00+00'), '',
    'earns Quarter Mile level 1', format(v_has, v_tu1, 'drag_visits_1'), 'TRUE',
    'drag strip does not earn Dirt level 1', format(v_not, v_tu1, 'offroad_visits_1'), 'TRUE',
    'check-in at a second road venue (autocross)',
      format(v_post, v_p7, v_tu1, v_road2, '2026-03-14 12:00:00+00'), '',
    'third road visit: Asphalt level 3', format(v_has, v_tu1, 'road_visits_3'), 'TRUE',
    'two road venues: Circuit Hopper level 1', format(v_has, v_tu1, 'road_venues_1'), 'TRUE',
    'three states (TN, OH, KY): Road Trip level 2', format(v_has, v_tu1, 'states_2'), 'TRUE',
    'three states is not yet Road Trip level 3', format(v_not, v_tu1, 'states_3'), 'TRUE',
    'four venues: Explorer level 2', format(v_has, v_tu1, 'all_venues_2'), 'TRUE',
    'four venues is not yet Explorer level 3', format(v_not, v_tu1, 'all_venues_3'), 'TRUE',
    'check-in at an off-road venue',
      format(v_post, v_p8, v_tu1, v_off, '2026-03-15 12:00:00+00'), '',
    'earns Dirt level 1', format(v_has, v_tu1, 'offroad_visits_1'), 'TRUE',

    -- ----- Course Collector counts only approved courses -----
    'attach a pending trail to the off-road check-in',
      format($q$INSERT INTO public.post_courses (post_id, course_id, star_rating, difficulty_rating) VALUES (%L, %L, 3, 3)$q$, v_p8, v_cpend), '',
    'a pending trail earns nothing', format(v_not, v_tu1, 'courses_1'), 'TRUE',
    'admin approves the trail',
      format($q$UPDATE public.courses SET status = 'approved' WHERE id = %L$q$, v_cpend), '',
    'approving it awards Course Collector level 1', format(v_has, v_tu1, 'courses_1'), 'TRUE',

    -- ----- likes: your own do not count -----
    'five more check-ins (for the like test)',
      format($q$INSERT INTO public.posts (user_id, location_id, photo_url, message, star_rating, difficulty_rating, created_at)
                SELECT %L, %L, 'https://example.invalid/x.jpg', 'zz-like-test', 3, 3, '2026-03-10 15:00:00+00'
                FROM generate_series(1, 5)$q$, v_tu1, v_road), '',
    'the owner likes one of their own posts',
      format($q$INSERT INTO public.likes (user_id, post_id)
                SELECT %L, id FROM public.posts WHERE message = 'zz-like-test' AND user_id = %L LIMIT 1$q$, v_tu1, v_tu1), '',
    'another rider likes four of them',
      format($q$INSERT INTO public.likes (user_id, post_id)
                SELECT %L, id FROM public.posts WHERE message = 'zz-like-test' AND user_id = %L LIMIT 4$q$, v_tu2, v_tu1), '',
    '4 likes from others plus 1 own like: no Crowd Favorite yet', format(v_not, v_tu1, 'likes_1'), 'TRUE',
    'the fifth like from another rider',
      format($q$INSERT INTO public.likes (user_id, post_id)
                SELECT %L, id FROM public.posts WHERE message = 'zz-like-test' AND user_id = %L
                  AND id NOT IN (SELECT post_id FROM public.likes WHERE user_id = %L) LIMIT 1$q$, v_tu2, v_tu1, v_tu2), '',
    '5 likes from others: Crowd Favorite level 1', format(v_has, v_tu1, 'likes_1'), 'TRUE',

    -- ----- friends -----
    'a pending friend request',
      format($q$INSERT INTO public.friends (requester_id, addressee_id, status) VALUES (%L, %L, 'pending')$q$, v_tu1, v_tu2), '',
    'pending earns nothing', format(v_not, v_tu1, 'friends_1'), 'TRUE',
    'the request is accepted',
      format($q$UPDATE public.friends SET status = 'accepted' WHERE requester_id = %L AND addressee_id = %L$q$, v_tu1, v_tu2), '',
    'requester earns Crew level 1', format(v_has, v_tu1, 'friends_1'), 'TRUE',
    'the other person earns Crew level 1 too', format(v_has, v_tu2, 'friends_1'), 'TRUE',
    'the badge counter on the profile matches', format(v_count, v_tu1), 'TRUE',

    -- ----- badges are permanent; recompute works -----
    'delete all of the test user''s check-ins',
      format($q$UPDATE public.posts SET is_deleted = true WHERE user_id = %L$q$, v_tu1), '',
    'deleting check-ins never removes a badge', format(v_has, v_tu1, 'road_visits_1'), 'TRUE',
    'recount after the deletion',
      format($q$SELECT public.admin_recompute_badges(%L)$q$, v_tu1), '',
    'recount removes badges that are no longer earned', format(v_not, v_tu1, 'road_visits_1'), 'TRUE',
    'recount keeps friend badges', format(v_has, v_tu1, 'friends_1'), 'TRUE',
    'the badge counter still matches', format(v_count, v_tu1), 'TRUE',
    'restore the check-ins',
      format($q$UPDATE public.posts SET is_deleted = false WHERE user_id = %L$q$, v_tu1), '',
    'recount again',
      format($q$SELECT public.admin_recompute_badges(%L)$q$, v_tu1), '',
    'recount awards Asphalt level 3 again', format(v_has, v_tu1, 'road_visits_3'), 'TRUE',
    'recount awards Course Collector again', format(v_has, v_tu1, 'courses_1'), 'TRUE',
    'recount awards Crowd Favorite again', format(v_has, v_tu1, 'likes_1'), 'TRUE',
    'the badge counter still matches after recount', format(v_count, v_tu1), 'TRUE',

    -- ----- what the app is and is not allowed to do -----
    'ROLE', 'u1', '',
    'the app cannot write badges directly',
      format($q$INSERT INTO public.user_badges (user_id, badge_id)
                SELECT %L, id FROM public.badge_definitions LIMIT 1$q$, v_tu1), 'row-level security',
    'the app cannot run the award function',
      format($q$SELECT public.award_ladder_badges(%L, 'visits', NULL)$q$, v_tu1), 'permission denied',
    'the app cannot run the recount tool',
      format($q$SELECT public.admin_recompute_badges(%L)$q$, v_tu1), 'permission denied',
    'the app cannot run the counting function',
      format($q$SELECT public.badge_metric_value(%L, 'visits', NULL)$q$, v_tu1), 'permission denied',
    'the app can read the ladders',
      $q$SELECT count(*) = 12 FROM public.badge_ladders$q$, 'TRUE',
    'the app can read all 160 ladder badges',
      $q$SELECT count(*) = 160 FROM public.badge_definitions WHERE ladder_id IS NOT NULL$q$, 'TRUE',
    'my_badge_progress shows 3 road visits and 1 friend',
      $q$SELECT (SELECT metric_value FROM public.my_badge_progress() WHERE ladder_slug = 'road_visits') = 3
           AND (SELECT metric_value FROM public.my_badge_progress() WHERE ladder_slug = 'friends') = 1$q$, 'TRUE',

    -- ----- a badge problem must never block a check-in -----
    'ROLE', 'admin', '',
    'break the award code on purpose (rename a column)',
      $q$ALTER TABLE public.badge_definitions RENAME COLUMN threshold_value TO tv_tmp$q$, '',
    'a check-in still saves while awarding is broken',
      format(v_post, v_p14, v_tu1, v_road, '2026-03-20 12:00:00+00'), '',
    'and the check-in is really there',
      format($q$SELECT EXISTS (SELECT 1 FROM public.posts WHERE id = %L)$q$, v_p14), 'TRUE',
    'put the column back',
      $q$ALTER TABLE public.badge_definitions RENAME COLUMN tv_tmp TO threshold_value$q$, ''
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
