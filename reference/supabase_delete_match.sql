-- Allow authenticated club admins/owners to delete matches and their feed events.
-- Run in the Supabase SQL Editor if match delete fails with an RLS error.

-- Matches: members with ADMIN role (or club owner) can delete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Admins can delete matches' AND tablename = 'matches'
  ) THEN
    CREATE POLICY "Admins can delete matches"
      ON public.matches
      FOR DELETE
      USING (
        EXISTS (
          SELECT 1
          FROM public.club_members cm
          WHERE cm.club_id = matches.club_id
            AND cm.user_id = auth.uid()
            AND (
              'ADMIN' = ANY (cm.roles)
              OR EXISTS (
                SELECT 1 FROM public.clubs c
                WHERE c.id = matches.club_id AND c.owner_id = auth.uid()
              )
            )
        )
        OR EXISTS (
          SELECT 1 FROM public.clubs c
          WHERE c.id = matches.club_id AND c.owner_id = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Admins can delete match events' AND tablename = 'feed_events'
  ) THEN
    CREATE POLICY "Admins can delete match events"
      ON public.feed_events
      FOR DELETE
      USING (
        EXISTS (
          SELECT 1
          FROM public.matches m
          JOIN public.clubs c ON c.id = m.club_id
          LEFT JOIN public.club_members cm
            ON cm.club_id = m.club_id AND cm.user_id = auth.uid()
          WHERE m.id = feed_events.match_id
            AND (
              c.owner_id = auth.uid()
              OR (cm.user_id IS NOT NULL AND 'ADMIN' = ANY (cm.roles))
            )
        )
      );
  END IF;
END $$;
