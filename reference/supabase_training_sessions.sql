-- Run once in the Supabase SQL editor for the TeamPulse project
-- (the one in modConfig: cadbpejpmbjgwftqwwud).
-- Training log: date, attendance, trainer of the week, behaviour.

CREATE TABLE IF NOT EXISTS public.training_sessions (
    id uuid PRIMARY KEY,
    club_id uuid NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    session_date date NOT NULL,
    trainer_of_week_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    present_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
    absent_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
    well_behaved_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
    poorly_behaved_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS training_sessions_club_date_idx
    ON public.training_sessions (club_id, session_date DESC);

ALTER TABLE public.training_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read All" ON public.training_sessions;
CREATE POLICY "Public Read All" ON public.training_sessions
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public Write All" ON public.training_sessions;
CREATE POLICY "Public Write All" ON public.training_sessions
    FOR ALL USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.training_sessions TO anon, authenticated, service_role;
