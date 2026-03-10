

## Bug Found: Ambiguous Column Reference in `get_users_at_place_feed`

### Root Cause

The RPC function `get_users_at_place_feed` defines `user_id uuid` as a **return column name**. Inside the function body, queries like:

```sql
WHERE user_id = p_user_id
```

are ambiguous — PostgreSQL cannot tell if `user_id` refers to the PL/pgSQL return variable or the `presence.user_id` table column. This causes the RPC to **fail silently** (the frontend catches the error and sets `people = []`).

The error is:
```
ERROR: 42702: column reference "user_id" is ambiguous
```

### Fix

A single migration to recreate the function with **fully qualified column references** (`p.user_id`, `pr.id`, `ui.user_id`) everywhere to eliminate ambiguity. The return column names stay the same for frontend compatibility.

Key changes inside the function:
- `WHERE user_id = p_user_id` → `WHERE p2.user_id = p_user_id` (using table alias)
- All internal subqueries already use aliases (`ui.user_id`, `pr.id`), so only the presence query for `v_my_presence_inicio` needs fixing

### Files Changed
- 1 migration file to `CREATE OR REPLACE FUNCTION` with the fix

No frontend changes needed — the hook and component code is correct.

