-- Planned substitution / fair game-time rotations (4 quarters).
-- Run once in the Supabase SQL Editor.

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS sub_plan jsonb;

NOTIFY pgrst, 'reload schema';
