-- =============================================================================
-- STEP 1: Run the ALTER TABLE statements to add new columns to profiles.
-- These are safe to run multiple times (IF NOT EXISTS prevents errors).
-- =============================================================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS squad_number integer;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS preferred_position text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS secondary_position text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS emergency_contact text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_of_birth date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS medical_notes text;

-- =============================================================================
-- STEP 2: Replace the add_dummy_member RPC to accept the new fields.
-- Drop the old signature first to avoid conflicts.
-- =============================================================================

DROP FUNCTION IF EXISTS public.add_dummy_member(uuid, text, text, text);

CREATE OR REPLACE FUNCTION public.add_dummy_member(
  p_club_id uuid,
  p_name text,
  p_avatar text,
  p_role text,
  p_squad_number integer DEFAULT NULL,
  p_preferred_position text DEFAULT NULL,
  p_secondary_position text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_emergency_contact text DEFAULT NULL,
  p_date_of_birth date DEFAULT NULL,
  p_medical_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  dummy_id uuid;
  roles_arr text[];
BEGIN
  dummy_id := gen_random_uuid();
  roles_arr := ARRAY[p_role];

  -- 1. Insert profile first (so club_members.user_id FK to profiles.id is satisfied)
  INSERT INTO public.profiles (id, name, avatar, roles, squad_number, preferred_position, secondary_position, phone, emergency_contact, date_of_birth, medical_notes)
  VALUES (dummy_id, p_name, p_avatar, roles_arr, p_squad_number, p_preferred_position, p_secondary_position, p_phone, p_emergency_contact, p_date_of_birth, p_medical_notes);

  -- 2. Then insert membership
  INSERT INTO public.club_members (club_id, user_id, roles)
  VALUES (p_club_id, dummy_id, roles_arr);

  RETURN jsonb_build_object(
    'id', dummy_id,
    'name', p_name,
    'avatar', p_avatar,
    'roles', to_jsonb(roles_arr),
    'squad_number', p_squad_number,
    'preferred_position', p_preferred_position,
    'secondary_position', p_secondary_position,
    'phone', p_phone,
    'emergency_contact', p_emergency_contact,
    'date_of_birth', p_date_of_birth,
    'medical_notes', p_medical_notes
  );
END;
$$;

-- Allow anon/authenticated to call
GRANT EXECUTE ON FUNCTION public.add_dummy_member(uuid, text, text, text, integer, text, text, text, text, date, text) TO anon;
GRANT EXECUTE ON FUNCTION public.add_dummy_member(uuid, text, text, text, integer, text, text, text, text, date, text) TO authenticated;
