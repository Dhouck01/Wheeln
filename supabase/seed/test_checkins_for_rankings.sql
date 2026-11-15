-- ============================================================
--  WHEELN — TEST check-ins so the Rankings screen has data
--  Run AFTER locations_seed.sql, and after you have signed up in the app.
--  Paste into the Supabase SQL editor. Run it ONCE (re-running adds more).
--
--  Adds 3 posts each (the Rankings minimum) for 6 places, owned by the
--  oldest user in the users table (you). All messages start with
--  "[RANK-TEST]". The database triggers fill in each place's average
--  rating, average difficulty and check-in count automatically.
--
--  Expected result:
--    Top Rated:        Laguna Seca, Road America, Bandimere ...
--    Most Challenging: Rubicon Trail, Hell's Revenge, Laguna Seca ...
--    Most Popular:     Laguna Seca (5), Rubicon Trail (4), others (3)
--
--  To remove them all later, run the cleanup line at the bottom.
-- ============================================================

INSERT INTO public.posts (user_id, location_id, photo_url, message, star_rating, difficulty_rating)
SELECT
  (SELECT id FROM public.users ORDER BY created_at ASC LIMIT 1),
  (SELECT id FROM public.locations WHERE slug = t.slug),
  'https://picsum.photos/seed/' || t.seed || '/800/800',
  '[RANK-TEST] ' || t.message,
  t.stars,
  t.difficulty
FROM (VALUES
  -- Laguna Seca: 5 check-ins, best rated, medium-hard
  ('laguna-seca',        'ls1', 'Corkscrew every lap.',        5, 4),
  ('laguna-seca',        'ls2', 'Perfect weather.',            5, 4),
  ('laguna-seca',        'ls3', 'Brakes took a beating.',      5, 3),
  ('laguna-seca',        'ls4', 'Best track day of the year.', 4, 4),
  ('laguna-seca',        'ls5', 'Back again.',                 5, 4),

  -- Road America: 3 check-ins, highly rated, medium
  ('road-america',       'ra1', 'Fast and flowing.',           5, 3),
  ('road-america',       'ra2', 'Carousel is fun.',            4, 3),
  ('road-america',       'ra3', 'Great paddock.',              4, 3),

  -- Bandimere: 3 check-ins, good, easy
  ('bandimere-speedway', 'bs1', 'Thin air, fast times.',       4, 2),
  ('bandimere-speedway', 'bs2', 'Sunset passes.',              4, 2),
  ('bandimere-speedway', 'bs3', 'Smooth surface.',             4, 1),

  -- Rubicon Trail: 4 check-ins, hardest
  ('rubicon-trail',      'rt1', 'Rocks everywhere.',           5, 5),
  ('rubicon-trail',      'rt2', 'Broke a shackle.',            4, 5),
  ('rubicon-trail',      'rt3', 'Little Sluice was wild.',     4, 5),
  ('rubicon-trail',      'rt4', 'Worth every mile.',           5, 5),

  -- Hell's Revenge: 3 check-ins, hard
  ('hells-revenge',      'hr1', 'Slickrock grip is unreal.',   4, 4),
  ('hells-revenge',      'hr2', 'Hell''s Gate!',               4, 4),
  ('hells-revenge',      'hr3', 'Steep climbs.',               3, 4),

  -- Texas Motorplex: 3 check-ins, middling, easy
  ('texas-motorplex',    'tm1', 'Hot day, hot track.',         3, 2),
  ('texas-motorplex',    'tm2', 'Long lines.',                 3, 2),
  ('texas-motorplex',    'tm3', 'Good pass.',                  4, 2)
) AS t(slug, seed, message, stars, difficulty)
WHERE EXISTS (SELECT 1 FROM public.users)
  AND EXISTS (SELECT 1 FROM public.locations WHERE slug = t.slug);

-- Cleanup (soft-delete; counters on locations and users fix themselves):
-- UPDATE public.posts SET is_deleted = true WHERE message LIKE '[RANK-TEST]%';
