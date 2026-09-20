
-- 1. ENABLE REPLICA IDENTITY FULL
-- This ensures that for every update, the database sends the entire row content, 
-- not just the changed columns. Essential for frontend state consistency.
ALTER TABLE public.profiles REPLICA IDENTITY FULL;
ALTER TABLE public.clubs REPLICA IDENTITY FULL;
ALTER TABLE public.club_members REPLICA IDENTITY FULL;
ALTER TABLE public.matches REPLICA IDENTITY FULL;
ALTER TABLE public.feed_events REPLICA IDENTITY FULL;

-- 2. RESET PUBLICATION
-- We drop and recreate to ensure the publication includes ALL tables from scratch.
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE 
    public.profiles, 
    public.clubs, 
    public.club_members, 
    public.matches, 
    public.feed_events;

-- 3. ENSURE PERMISSIVE POLICIES (Required for Realtime broadcasts to reach clients)
-- If RLS is ON but policies are missing, Realtime payloads will be empty.
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Public Read All' AND tablename = 'matches') THEN
        CREATE POLICY "Public Read All" ON public.matches FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Public Read All' AND tablename = 'feed_events') THEN
        CREATE POLICY "Public Read All" ON public.feed_events FOR SELECT USING (true);
    END IF;
END $$;
