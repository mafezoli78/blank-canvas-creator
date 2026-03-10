## Analysis: Already Implemented

After reviewing the codebase, **all 4 phases you described are already implemented**. Here's the current state:

### Phase 1 — send_wave RPC ✅ DONE

The RPC `public.send_wave(p_from_user_id, p_to_user_id, p_place_id)` already exists with validations for: blocks, mutes, cooldown, duplicate waves, ignore cooldown, active chat, presence (both sender and recipient), rate limit (20/hour), and advisory locks. The frontend (`src/hooks/useWaves.ts` line ~140) already calls `supabase.rpc('send_wave', {...})`.

IMPORTANTE

Antes de criar qualquer RPC nova, verificar se funções equivalentes já existem no banco de dados (ex: send_wave, accept_wave ou variações).

Se já existirem:

- NÃO criar nova função

- apenas adaptar a função existente para incluir as validações necessárias

- manter compatibilidade com o frontend atual

### Phase 2 — accept_wave atomic ✅ DONE

The RPC `public.accept_wave(p_wave_id, p_user_id)` exists with `FOR UPDATE` row lock, TOCTOU protection via advisory lock, all validations (expiry, blocks, mutes, cooldown, presence), and atomic conversation creation with duplicate handling. Frontend already calls `supabase.rpc('accept_wave', {...})`.

### Phase 3 — Expiration & cooldown in DB ✅ DONE

Both RPCs validate `expires_at` and `ignore_cooldown_until` server-side. The `enforce_wave_immutability` trigger prevents tampering with immutable fields. The `enforce_renewal_limit` trigger caps presence at 2 hours.

### Phase 4 — Automatic presence expiration ✅ DONE

The edge function `cleanup-expired-presences` calls the DB function `cleanup_expired_presences()`, which finds stale presences and runs `end_presence_cascade` on each. The only missing piece is the **pg_cron schedule** to invoke this automatically — currently it must be called externally.

### Only Remaining Gap: pg_cron Schedule

The cleanup edge function exists but has no automated trigger. We could schedule it via pg_cron + pg_net to call the edge function every 5 minutes.

### Indexes

Some indexes may be missing. Worth adding for performance but not a security issue.

### Recommendation

No code changes needed. If you want, I can:

1. Set up the pg_cron job to auto-invoke the cleanup edge function
2. Add performance indexes on waves and presence tables