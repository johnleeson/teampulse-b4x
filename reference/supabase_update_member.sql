-- =============================================================================
-- ONLY run this in the SAME Supabase project the app uses.
-- App project ref: cadbpejpmbjgwftqwwud
-- (Dashboard URL looks like: https://supabase.com/dashboard/project/cadbpejpmbjgwftqwwud)
--
-- If you see: relation "public.profiles" does not exist
-- you are in the WRONG project. Switch projects and try again.
--
-- You usually do NOT need this script: the app updates public.profiles
-- directly, and that already works on the TeamPulse project.
-- =============================================================================

-- Quick check (should return public.profiles, not null):
-- SELECT to_regclass('public.profiles');

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS squad_number integer;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_position text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS secondary_position text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS emergency_contact text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_of_birth date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS medical_notes text;

DROP POLICY IF EXISTS "Authenticated can update profiles" ON public.profiles;
CREATE POLICY "Authenticated can update profiles"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated can insert profiles" ON public.profiles;
CREATE POLICY "Authenticated can insert profiles"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

NOTIFY pgrst, 'reload schema';
