
-- 4.1: Rate limit waves (max 20 per hour) — added to send_wave RPC
CREATE OR REPLACE FUNCTION public.send_wave(p_from_user_id uuid, p_to_user_id uuid, p_place_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_wave_id uuid;
  v_expires_at timestamptz;
  v_wave_count integer;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtext(LEAST(p_from_user_id::text, p_to_user_id::text) || p_place_id::text)
  );

  IF p_from_user_id = p_to_user_id THEN
    RAISE EXCEPTION 'WAVE_SELF';
  END IF;

  -- 4.1: Rate limit — max 20 waves per hour
  SELECT COUNT(*) INTO v_wave_count
  FROM public.waves
  WHERE de_user_id = p_from_user_id
    AND criado_em > now() - interval '1 hour';

  IF v_wave_count >= 20 THEN
    RAISE EXCEPTION 'WAVE_RATE_LIMIT';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.user_blocks
    WHERE (user_id = p_from_user_id AND blocked_user_id = p_to_user_id)
       OR (user_id = p_to_user_id AND blocked_user_id = p_from_user_id)
  ) THEN
    RAISE EXCEPTION 'WAVE_BLOCKED';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.user_mutes
    WHERE user_id = p_from_user_id
      AND muted_user_id = p_to_user_id
      AND expira_em > now()
  ) THEN
    RAISE EXCEPTION 'WAVE_MUTED';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.conversations
    WHERE place_id = p_place_id
      AND ativo = true
      AND ((user1_id = p_from_user_id AND user2_id = p_to_user_id)
        OR (user1_id = p_to_user_id AND user2_id = p_from_user_id))
  ) THEN
    RAISE EXCEPTION 'WAVE_ACTIVE_CHAT';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.conversations
    WHERE place_id = p_place_id
      AND ativo = false
      AND reinteracao_permitida_em > now()
      AND ((user1_id = p_from_user_id AND user2_id = p_to_user_id)
        OR (user1_id = p_to_user_id AND user2_id = p_from_user_id))
  ) THEN
    RAISE EXCEPTION 'WAVE_COOLDOWN';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.waves
    WHERE de_user_id = p_from_user_id
      AND para_user_id = p_to_user_id
      AND place_id = p_place_id
      AND status = 'pending'
      AND (expires_at IS NULL OR expires_at > now())
  ) THEN
    RAISE EXCEPTION 'WAVE_DUPLICATE';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.waves
    WHERE de_user_id = p_from_user_id
      AND para_user_id = p_to_user_id
      AND place_id = p_place_id
      AND status = 'expired'
      AND ignore_cooldown_until IS NOT NULL
      AND ignore_cooldown_until > now()
  ) THEN
    RAISE EXCEPTION 'WAVE_IGNORE_COOLDOWN';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.presence
    WHERE user_id = p_from_user_id
      AND place_id = p_place_id
      AND ativo = true
  ) THEN
    RAISE EXCEPTION 'WAVE_NO_PRESENCE_SENDER';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.presence
    WHERE user_id = p_to_user_id
      AND place_id = p_place_id
      AND ativo = true
  ) THEN
    RAISE EXCEPTION 'WAVE_NO_PRESENCE_RECIPIENT';
  END IF;

  v_expires_at := now() + interval '1 hour';

  INSERT INTO public.waves (
    de_user_id, para_user_id, place_id, location_id, status, expires_at
  ) VALUES (
    p_from_user_id, p_to_user_id, p_place_id, p_place_id, 'pending', v_expires_at
  )
  RETURNING id INTO v_wave_id;

  RAISE LOG '[send_wave] Wave created: % from % to % at place %', 
    v_wave_id, p_from_user_id, p_to_user_id, p_place_id;

  RETURN v_wave_id;
END;
$function$;

-- 4.2: Sanitization trigger for messages (trim + max 2000 chars)
CREATE OR REPLACE FUNCTION public.sanitize_message_content()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  NEW.conteudo := LEFT(TRIM(NEW.conteudo), 2000);
  IF NEW.conteudo = '' THEN
    RAISE EXCEPTION 'MESSAGE_EMPTY' USING HINT = 'Mensagem não pode ser vazia';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sanitize_message
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.sanitize_message_content();

-- 4.3: Age validation trigger for profiles (minimum 18 years)
CREATE OR REPLACE FUNCTION public.enforce_minimum_age()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.data_nascimento IS NOT NULL AND age(NEW.data_nascimento) < interval '18 years' THEN
    RAISE EXCEPTION 'MINIMUM_AGE' USING HINT = 'Usuário deve ter no mínimo 18 anos';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enforce_minimum_age
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_minimum_age();

-- 4.4: Unique index for pending waves (prevents duplicates at DB level)
CREATE UNIQUE INDEX IF NOT EXISTS waves_unique_pending
ON public.waves (de_user_id, para_user_id, place_id)
WHERE status = 'pending';
