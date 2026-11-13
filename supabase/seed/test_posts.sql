-- ============================================================
--  WHEELN — TEST posts so the feed has something to show
--  Run AFTER locations_seed.sql, and after you have signed up in the app.
--  Paste into the Supabase SQL editor.
--
--  Creates 4 posts owned by the oldest user in the users table (you),
--  all starting with "[TEST]" and using placeholder photos from picsum.photos.
--  Re-running adds 4 more, so run it once.
--
--  To delete them all later, run the cleanup line at the bottom.
-- ============================================================

INSERT INTO public.posts (user_id, location_id, photo_url, message, star_rating, difficulty_rating)
SELECT
  (SELECT id FROM public.users ORDER BY created_at ASC LIMIT 1),
  (SELECT id FROM public.locations WHERE slug = t.slug),
  t.photo_url,
  t.message,
  t.stars,
  t.difficulty
FROM (VALUES
  ('laguna-seca',     'https://picsum.photos/seed/wheeln1/800/800', '[TEST] The Corkscrew never gets old.',          5, 4),
  ('bandimere-speedway','https://picsum.photos/seed/wheeln2/800/800','[TEST] Thin air, fast times. 11.9 pass!',       4, 2),
  ('rubicon-trail',   'https://picsum.photos/seed/wheeln3/800/800', '[TEST] Day two on the Rubicon. Rocks everywhere.',5, 5),
  ('road-america',    'https://picsum.photos/seed/wheeln4/800/800', '[TEST] Great weekend at Road America.',          4, 3)
) AS t(slug, photo_url, message, stars, difficulty)
WHERE EXISTS (SELECT 1 FROM public.users)
  AND EXISTS (SELECT 1 FROM public.locations WHERE slug = t.slug);

-- Cleanup (run only when you want the test posts gone; counters on locations
-- and users are fixed up automatically for soft deletes):
-- UPDATE public.posts SET is_deleted = true WHERE message LIKE '[TEST]%';
