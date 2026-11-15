-- ============================================================
--  WHEELN — Storage bucket and rules for check-in photos
--
--  Creates a public bucket named "post-photos".
--    * Anyone can VIEW a photo (it is shown in the feed).
--    * A signed-in user can UPLOAD only into a folder named with their own
--      login id (auth.uid()), e.g.  <login id>/1731700000000.jpg
--    * Nobody can change or delete photos from the app (no update/delete rule).
--    * Only image files up to 5 MB are accepted.
--
--  Safe to re-run. Paste into the Supabase SQL editor and run once.
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-photos',
  'post-photos',
  true,
  5242880,  -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "post-photos: public read"  ON storage.objects;
DROP POLICY IF EXISTS "post-photos: owner upload" ON storage.objects;

CREATE POLICY "post-photos: public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'post-photos');

CREATE POLICY "post-photos: owner upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'post-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
