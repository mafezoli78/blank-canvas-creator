
-- =============================================
-- PART 1: RPC accept_wave (atomic)
-- =============================================
CREATE OR REPLACE FUNCTION public.accept_wave(
  p_wave_id uuid,
  p_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_wave RECORD;
  v_conversation_id uuid;
  v_place_id uuid;
  v_other_user_id uuid;
BEGIN
  -- 1. Fetch wave
  SELECT * INTO v_wave
  FROM public.waves
  WHERE id = p_wave_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_NOT_FOUND';
  END IF;

  -- 2. Validate ownership
  IF v_wave.para_user_id != p_user_id THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_NOT_RECIPIENT';
  END IF;

  -- 3. Cannot accept own wave
  IF v_wave.de_user_id = p_user_id THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_SELF';
  END IF;

  v_other_user_id := v_wave.de_user_id;
  v_place_id := COALESCE(v_wave.place_id, v_wave.location_id);

  IF v_place_id IS NULL THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_NO_PLACE';
  END IF;

  -- 0. Advisory lock on user pair to prevent race conditions
  PERFORM pg_advisory_xact_lock(
    hashtext(LEAST(p_user_id::text, v_other_user_id::text) || v_place_id::text)
  );

  -- 4. Validate status is pending
  IF v_wave.status != 'pending' THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_NOT_PENDING';
  END IF;

  -- 5. Validate not expired
  IF v_wave.expires_at IS NOT NULL AND v_wave.expires_at <= now() THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_EXPIRED';
  END IF;

  -- 6. Validate no block (bilateral)
  IF EXISTS (
    SELECT 1 FROM public.user_blocks
    WHERE (user_id = p_user_id AND blocked_user_id = v_other_user_id)
       OR (user_id = v_other_user_id AND blocked_user_id = p_user_id)
  ) THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_BLOCKED';
  END IF;

  -- 7. Validate no active mute (either direction)
  IF EXISTS (
    SELECT 1 FROM public.user_mutes
    WHERE ((user_id = p_user_id AND muted_user_id = v_other_user_id)
       OR (user_id = v_other_user_id AND muted_user_id = p_user_id))
      AND expira_em > now()
  ) THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_MUTED';
  END IF;

  -- 8. Validate no active conversation already
  IF EXISTS (
    SELECT 1 FROM public.conversations
    WHERE place_id = v_place_id
      AND ativo = true
      AND ((user1_id = p_user_id AND user2_id = v_other_user_id)
        OR (user1_id = v_other_user_id AND user2_id = p_user_id))
  ) THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_ACTIVE_CHAT';
  END IF;

  -- 9. Validate no cooldown
  IF EXISTS (
    SELECT 1 FROM public.conversations
    WHERE place_id = v_place_id
      AND ativo = false
      AND reinteracao_permitida_em > now()
      AND ((user1_id = p_user_id AND user2_id = v_other_user_id)
        OR (user1_id = v_other_user_id AND user2_id = p_user_id))
  ) THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_COOLDOWN';
  END IF;

  -- 10. Validate sender presence active
  IF NOT EXISTS (
    SELECT 1 FROM public.presence
    WHERE user_id = v_other_user_id
      AND place_id = v_place_id
      AND ativo = true
  ) THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_NO_PRESENCE_SENDER';
  END IF;

  -- 11. Validate recipient presence active
  IF NOT EXISTS (
    SELECT 1 FROM public.presence
    WHERE user_id = p_user_id
      AND place_id = v_place_id
      AND ativo = true
  ) THEN
    RAISE EXCEPTION 'ACCEPT_WAVE_NO_PRESENCE_RECIPIENT';
  END IF;

  -- 12. Update wave status to accepted
  UPDATE public.waves
  SET status = 'accepted',
      accepted_by = p_user_id,
      visualizado = true
  WHERE id = p_wave_id
    AND status = 'pending';

  IF NOT FOUND THEN
    -- Race condition: another process accepted it first
    RAISE EXCEPTION 'ACCEPT_WAVE_ALREADY_ACCEPTED';
  END IF;

  -- 13. Create conversation
  INSERT INTO public.conversations (
    user1_id,
    user2_id,
    place_id,
    origem_wave_id,
    ativo,
    criado_em
  ) VALUES (
    v_other_user_id,
    p_user_id,
    v_place_id,
    p_wave_id,
    true,
    now()
  )
  RETURNING id INTO v_conversation_id;

  RAISE LOG '[accept_wave] Conversation % created from wave % (user1=%, user2=%, place=%)',
    v_conversation_id, p_wave_id, v_other_user_id, p_user_id, v_place_id;

  RETURN v_conversation_id;
END;
$$;

-- =============================================
-- PART 4: UNIQUE INDEX on waves pending
-- =============================================
CREATE UNIQUE INDEX IF NOT EXISTS idx_waves_pending_unique
ON public.waves (de_user_id, para_user_id, place_id)
WHERE status = 'pending';
