-- Match competition type for fixtures (league / friendly / cup).
-- Run once in the Supabase SQL Editor (project cadbpejpmbjgwftqwwud).

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS competition text DEFAULT 'FRIENDLY';

-- Optional: constrain allowed values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'matches_competition_check'
  ) THEN
    ALTER TABLE public.matches
      ADD CONSTRAINT matches_competition_check
      CHECK (competition IS NULL OR competition IN ('LEAGUE', 'FRIENDLY', 'CUP'));
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
