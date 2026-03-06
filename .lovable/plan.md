## Plan: Preserve pending action via sessionStorage across onboarding

### Problem

When `activatePresenceAtPlace` throws `PROFILE_INCOMPLETE`, the user is sent to onboarding. After completing it, they return to `/location` but lose the full context (placeId, expressionText). The current navigation-state approach only carries a basic `pendingAction` that restores place selection — it doesn't restore the expression step or selfie step, forcing the user to redo multiple steps.

### Architecture

Use `sessionStorage` to persist the full action context. After onboarding, Location.tsx reads it and restores the user to the **expression step** with the place pre-selected and expression pre-filled, so they only need to take the selfie and proceed.

**Why not auto-activate?** The current flow requires a selfie before presence creation (enforced in `handleActivatePresence`). Skipping it would create presence records without selfies. Instead, we restore the user to the point just before the selfie.

### Changes

**1. Create `src/utils/pendingAction.ts**` (new file)

```typescript
export type PendingAction = {
  type: 'ACTIVATE_PRESENCE';
  placeId: string;
  expressionText?: string;
};

const KEY = 'katu_pending_action';

export function savePendingAction(action: PendingAction) {
  sessionStorage.setItem(KEY, JSON.stringify(action));
}

export function getPendingAction(): PendingAction | null {
  const raw = sessionStorage.getItem(KEY);
  if (!raw) return null;
  return JSON.parse(raw);
}

export function clearPendingAction() {
  sessionStorage.removeItem(KEY);
}
```

**2. `src/pages/Location.tsx**` — Save context on PROFILE_INCOMPLETE

In `handleActivatePresence` (line 334), when catching `PROFILE_INCOMPLETE`:

```typescript
if (err?.message === 'PROFILE_INCOMPLETE' || err?.code === 'PROFILE_INCOMPLETE') {
  savePendingAction({
    type: 'ACTIVATE_PRESENCE',
    placeId: selectedPlaceId!,
    expressionText: expressionText?.trim() || undefined,
  });

  setShowProfileGate(true);
  return;
}
```

**3.** `src/pages/Location.tsx` — Restore context on mount

Replace the existing `pendingAction` restoration effect (lines 167-181) with sessionStorage-based restoration:

```typescript
useEffect(() => {
  const pending = getPendingAction();
  if (!pending || pending.type !== 'ACTIVATE_PRESENCE') return;

  if (pending.placeId) {
    setSelectedPlaceId(pending.placeId);
    if (pending.expressionText) setExpressionText(pending.expressionText);
    setStep('expression');
  }

  clearPendingAction();
}, []);
```

**4. `src/pages/Location.tsx**` — Remove old navigation-state pendingAction logic

- Remove the existing `useEffect` that reads `location.state?.pendingAction` (lines 167-181)
- Remove the `pendingAction` prop from `ProfileGateModal` render (line 673) — no longer needed

**5. `src/components/profile/ProfileGateModal.tsx**` — Simplify

Remove `pendingAction` prop handling. The modal just navigates to `/onboarding` without state — sessionStorage already holds the context.

```typescript
onClick={() => {
  onClose();
  navigate('/onboarding');
}}
```

**6. `src/pages/Onboarding.tsx**` — Simplify

Remove the `pendingAction` reading from `location.state` (line 28) and the forwarding in `handleComplete` (line 139). Just navigate to `/location` on completion:

```typescript
navigate('/location', { replace: true });
```

### Flow after changes

```text
1. User selects place → types expression → takes selfie → activatePresenceAtPlace fires
2. PROFILE_INCOMPLETE thrown
3. savePendingAction({ type: 'ACTIVATE_PRESENCE', placeId, expressionText })
4. ProfileGateModal opens → user clicks "Completar perfil" → navigates to /onboarding
5. User completes onboarding → navigates to /location
6. Location mount reads sessionStorage → restores placeId + expressionText → sets step='expression'
7. User clicks "Continuar" → takes selfie → activatePresenceAtPlace succeeds
```

### Edge cases

- **Page refresh during onboarding**: sessionStorage persists within the tab session — action is restored
- **Manual onboarding access**: No sessionStorage entry — normal flow
- **Tab closed**: sessionStorage cleared — clean fallback to `/location`

### Files summary


| File                                          | Change                                                               |
| --------------------------------------------- | -------------------------------------------------------------------- |
| `src/utils/pendingAction.ts`                  | New — sessionStorage helpers                                         |
| `src/pages/Location.tsx`                      | Save on PROFILE_INCOMPLETE, restore on mount, remove nav-state logic |
| `src/components/profile/ProfileGateModal.tsx` | Remove pendingAction prop                                            |
| `src/pages/Onboarding.tsx`                    | Remove pendingAction forwarding                                      |
| `src/hooks/useProfileGate.ts`                 | Remove PendingAction type export (moved to pendingAction.ts)         |
