-- =============================================================================
-- Match photos for the end-of-season booklet / PDF.
-- Run once in the Supabase SQL Editor (project: cadbpejpmbjgwftqwwud).
-- =============================================================================

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS photo_urls text[] DEFAULT '{}';

-- Public bucket for match gallery images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'match-photos',
  'match-photos',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Anyone can view (public URLs used in the app / future PDF)
DROP POLICY IF EXISTS "Public read match photos" ON storage.objects;
CREATE POLICY "Public read match photos"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'match-photos');

-- Signed-in users can upload
DROP POLICY IF EXISTS "Authenticated upload match photos" ON storage.objects;
CREATE POLICY "Authenticated upload match photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'match-photos');

-- Signed-in users can replace/delete (admins remove photos in the app)
DROP POLICY IF EXISTS "Authenticated update match photos" ON storage.objects;
CREATE POLICY "Authenticated update match photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'match-photos');

DROP POLICY IF EXISTS "Authenticated delete match photos" ON storage.objects;
CREATE POLICY "Authenticated delete match photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'match-photos');

NOTIFY pgrst, 'reload schema';
