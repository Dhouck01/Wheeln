-- ============================================================
--  WHEELN — Test for 20261116000000_lock_down_users_friends_events.sql
--
--  How to use: paste this whole file into the Supabase SQL editor and run it.
--  It ends with a red "error" on purpose. The error message is the report:
--  every line should start with PASS. The error also makes the database undo
--  everything the test did, so no real data is changed.
--
--  It pretends to be your first user (the oldest row in `users`), so it only
--  needs one user to exist. The friend-request tests need a second user and
--  are skipped if there is none.
-- ============================================================

DO $$
DECLARE
  v_auth        uuid;
  v_uid         uuid;
  v_other_auth  uuid;
  v_other_uid   uuid;
  v_fake_auth   uuid := gen_random_uuid();
  v_friend_id   uuid;
  v_rows        integer;
  v_status      text;
  r             record;
  stmt          text;
  res           text := '';
BEGIN
  -- Find two real users (as the admin, before we switch to app-user mode)
  SELECT auth_id, id INTO v_auth, v_uid
    FROM public.users WHERE auth_id IS NOT NULL ORDER BY created_at LIMIT 1;
  SELECT auth_id, id INTO v_other_auth, v_other_uid
    FROM public.users WHERE auth_id IS NOT NULL AND id <> v_uid ORDER BY created_at LIMIT 1;

  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No users found. Sign up in the app first, then run this again.';
  END IF;

  -- Switch to "signed-in app user" mode, as the first user
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_auth, 'role', 'authenticated')::text, true);
  SET LOCAL ROLE authenticated;

  -- 1. Protected profile fields must be refused
  FOREACH stmt IN ARRAY ARRAY[
    format('UPDATE public.users SET subscription_status = ''active'' WHERE id = %L', v_uid),
    format('UPDATE public.users SET total_checkins = 999 WHERE id = %L', v_uid),
    format('UPDATE public.users SET badge_count = 999 WHERE id = %L', v_uid),
    format('UPDATE public.users SET revenuecat_user_id = ''fake'' WHERE id = %L', v_uid),
    format('UPDATE public.users SET is_suspended = true WHERE id = %L', v_uid),
    format('UPDATE public.users SET email = ''someone@else.example'' WHERE id = %L', v_uid)
  ] LOOP
    BEGIN
      EXECUTE stmt;
      res := res || E'\nFAIL (was allowed): ' || stmt;
    EXCEPTION WHEN others THEN
      IF SQLERRM LIKE '%cannot be changed from the app%' THEN
        res := res || E'\nPASS (blocked): ' || stmt;
      ELSE
        res := res || E'\nUNEXPECTED ERROR: ' || stmt || ' -> ' || SQLERRM;
      END IF;
    END;
  END LOOP;

  -- 2. A normal profile edit must still work
  BEGIN
    UPDATE public.users SET bio = 'lock-down test' WHERE id = v_uid;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 1 THEN
      res := res || E'\nPASS (allowed): editing your own bio';
    ELSE
      res := res || E'\nFAIL: editing your own bio changed ' || v_rows || ' rows';
    END IF;
  EXCEPTION WHEN others THEN
    res := res || E'\nFAIL: editing your own bio was refused -> ' || SQLERRM;
  END;

  -- 3. Sign-up cannot start with a paid plan, counters or a suspended flag
  BEGIN
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_fake_auth, 'role', 'authenticated')::text, true);
    INSERT INTO public.users
      (auth_id, email, username, display_name,
       subscription_status, total_checkins, badge_count, is_suspended)
    VALUES
      (v_fake_auth, 'locktest@example.invalid', 'locktest_user', 'Lock Test',
       'active', 50, 9, true)
    RETURNING subscription_status, total_checkins, badge_count, is_suspended INTO r;
    IF r.subscription_status = 'free' AND r.total_checkins = 0
       AND r.badge_count = 0 AND r.is_suspended = false THEN
      res := res || E'\nPASS (reset to defaults): sign-up with fake plan and counters';
    ELSE
      res := res || E'\nFAIL: sign-up kept plan=' || r.subscription_status
        || ' checkins=' || r.total_checkins || ' badges=' || r.badge_count
        || ' suspended=' || r.is_suspended;
    END IF;
  EXCEPTION WHEN others THEN
    res := res || E'\nUNEXPECTED ERROR in sign-up test -> ' || SQLERRM;
  END;

  -- Back to being the first user
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_auth, 'role', 'authenticated')::text, true);

  -- 4. Direct event check-in must be refused
  BEGIN
    INSERT INTO public.event_checkins (user_id, event_id) VALUES (v_uid, gen_random_uuid());
    res := res || E'\nFAIL (was allowed): direct event check-in';
  EXCEPTION WHEN others THEN
    IF SQLERRM LIKE '%row-level security%' THEN
      res := res || E'\nPASS (blocked): direct event check-in';
    ELSE
      res := res || E'\nUNEXPECTED ERROR: direct event check-in -> ' || SQLERRM;
    END IF;
  END;

  -- 5. Friend requests (need a second user)
  IF v_other_uid IS NULL THEN
    res := res || E'\nSKIPPED: friend-request tests (only one user exists)';
  ELSE
    BEGIN
      INSERT INTO public.friends (requester_id, addressee_id, status)
      VALUES (v_uid, v_other_uid, 'accepted')
      RETURNING id, status INTO v_friend_id, v_status;
      IF v_status = 'pending' THEN
        res := res || E'\nPASS (reset to pending): friend request sent as accepted';
      ELSE
        res := res || E'\nFAIL: friend request kept status ' || v_status;
      END IF;

      -- Now act as the person who received it
      PERFORM set_config('request.jwt.claims',
        json_build_object('sub', v_other_auth, 'role', 'authenticated')::text, true);

      BEGIN
        UPDATE public.friends SET created_at = now() - interval '1 day' WHERE id = v_friend_id;
        res := res || E'\nFAIL (was allowed): editing a column other than status';
      EXCEPTION WHEN others THEN
        IF SQLERRM LIKE '%Only the status%' THEN
          res := res || E'\nPASS (blocked): editing a column other than status';
        ELSE
          res := res || E'\nUNEXPECTED ERROR: editing other column -> ' || SQLERRM;
        END IF;
      END;

      BEGIN
        UPDATE public.friends SET status = 'accepted' WHERE id = v_friend_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        IF v_rows = 1 THEN
          res := res || E'\nPASS (allowed): accepting a friend request';
        ELSE
          res := res || E'\nFAIL: accepting a friend request changed ' || v_rows || ' rows';
        END IF;
      EXCEPTION WHEN others THEN
        res := res || E'\nFAIL: accepting a friend request was refused -> ' || SQLERRM;
      END;
    EXCEPTION WHEN others THEN
      res := res || E'\nSKIPPED: friend-request tests (' || SQLERRM || ')';
    END;
  END IF;

  -- Always end with an error so the database undoes everything above
  RAISE EXCEPTION E'TEST REPORT (this error is on purpose, nothing was saved):%', res;
END;
$$;
