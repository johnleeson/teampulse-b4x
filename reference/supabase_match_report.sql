-- Match report text for season booklet compilation.
-- Stored on matches.ai_summary (used as the editable club match report).

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS ai_summary text;
