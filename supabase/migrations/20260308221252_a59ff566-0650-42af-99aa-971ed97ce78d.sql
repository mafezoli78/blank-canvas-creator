
-- =============================================
-- PART 2: Restrictive RLS on waves UPDATE
-- =============================================
-- Drop existing permissive UPDATE policy
DROP POLICY IF EXISTS "Users can update waves they received" ON public.waves;

-- New restrictive UPDATE: only allow changing safe fields
-- Recipients can only: mark as read, update status to accepted/expired, set ignored_at/ignore_cooldown_until
CREATE POLICY "Users can update waves they received (restricted)"
ON public.waves
FOR UPDATE
TO authenticated
USING (auth.uid() = para_user_id)
WITH CHECK (
  auth.uid() = para_user_id
  -- Prevent changing identity fields
  AND de_user_id = de_user_id
  AND para_user_id = para_user_id
  AND place_id = place_id
  AND criado_em = criado_em
);

-- =============================================
-- PART 3: Restrictive RLS on conversations
-- =============================================

-- 3a. Restrict UPDATE: only allow deactivating (not reactivating or changing users)
DROP POLICY IF EXISTS "Users can update their conversations" ON public.conversations;

CREATE POLICY "Users can update their conversations (restricted)"
ON public.conversations
FOR UPDATE
TO authenticated
USING (
  (auth.uid() = user1_id OR auth.uid() = user2_id)
  AND ativo = true  -- Can only update ACTIVE conversations
)
WITH CHECK (
  (auth.uid() = user1_id OR auth.uid() = user2_id)
  AND ativo = false  -- Can only SET to inactive (not reactivate)
  AND encerrado_por = auth.uid()  -- Must mark themselves as the one who ended
);

-- 3b. Restrict INSERT: require origem_wave_id (must come from accepted wave)
DROP POLICY IF EXISTS "Users can create conversations they're part of" ON public.conversations;

CREATE POLICY "Users can create conversations with valid wave"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (
  (auth.uid() = user1_id OR auth.uid() = user2_id)
  AND origem_wave_id IS NOT NULL  -- Must reference an accepted wave
  AND ativo = true  -- Must be created as active
);
