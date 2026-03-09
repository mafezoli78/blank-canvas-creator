-- FIX #2: profiles SELECT - restrict to authenticated users only
-- Drop existing overly permissive policy
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;

-- Create new policy: authenticated users can view all profiles
CREATE POLICY "Authenticated users can view profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- FIX #3: user_interests SELECT - restrict to authenticated users only  
DROP POLICY IF EXISTS "Users can view all interests" ON public.user_interests;

-- Create new policy: authenticated users can view all interests
CREATE POLICY "Authenticated users can view interests"
  ON public.user_interests
  FOR SELECT
  TO authenticated
  USING (true);

-- FIX #4: waves UPDATE - fix self-comparison bug with proper immutability trigger
-- First, drop the broken policy
DROP POLICY IF EXISTS "Users can update waves they received (restricted)" ON public.waves;

-- Create simple UPDATE policy (trigger will enforce immutability)
CREATE POLICY "Recipients can update wave status"
  ON public.waves
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = para_user_id)
  WITH CHECK (auth.uid() = para_user_id);

-- Create trigger to enforce field immutability on UPDATE
CREATE OR REPLACE FUNCTION public.enforce_wave_immutability()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path = public
AS $$
BEGIN
  -- Block changes to immutable fields
  IF NEW.de_user_id IS DISTINCT FROM OLD.de_user_id THEN
    RAISE EXCEPTION 'WAVE_IMMUTABLE_FIELD: de_user_id cannot be changed';
  END IF;
  
  IF NEW.para_user_id IS DISTINCT FROM OLD.para_user_id THEN
    RAISE EXCEPTION 'WAVE_IMMUTABLE_FIELD: para_user_id cannot be changed';
  END IF;
  
  IF NEW.place_id IS DISTINCT FROM OLD.place_id THEN
    RAISE EXCEPTION 'WAVE_IMMUTABLE_FIELD: place_id cannot be changed';
  END IF;
  
  IF NEW.criado_em IS DISTINCT FROM OLD.criado_em THEN
    RAISE EXCEPTION 'WAVE_IMMUTABLE_FIELD: criado_em cannot be changed';
  END IF;
  
  IF NEW.location_id IS DISTINCT FROM OLD.location_id THEN
    RAISE EXCEPTION 'WAVE_IMMUTABLE_FIELD: location_id cannot be changed';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS enforce_wave_immutability_trigger ON public.waves;

CREATE TRIGGER enforce_wave_immutability_trigger
  BEFORE UPDATE ON public.waves
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_wave_immutability();