-- Run in Supabase SQL Editor to support team formats & lineups.

ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS formation text;
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS lineup jsonb DEFAULT '{}'::jsonb;
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS team_size integer;

ALTER TABLE public.clubs ADD COLUMN IF NOT EXISTS preferred_team_size integer;
ALTER TABLE public.clubs ADD COLUMN IF NOT EXISTS preferred_formation text;
