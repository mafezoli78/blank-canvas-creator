

## Problem

Two `useEffect` hooks in `Location.tsx` race on mount:
1. **Permission check** (line 132) — sets `step` to `'permission'` or `'detecting'`, then `'select'`
2. **Pending action restore** (line 168) — sets `step` to `'expression'`

The permission effect often wins or overwrites the restored step, sending the user back to the place list.

Additionally, `Onboarding.tsx` always navigates to `/location` without awareness of pending actions — ideally it should signal that a restore is expected.

## Fix Plan

### 1. Location.tsx — Prioritize pending action over permission flow

Add a ref/flag (`hasPendingAction`) set synchronously before effects run. The permission effect should skip its step-setting logic when a pending action exists:

```
// On mount, check pending action synchronously
const pendingRef = useRef(getPendingAction());

// Permission useEffect: skip step override if pending action exists
useEffect(() => {
  ...
  if (pendingRef.current) return; // don't override step
  // existing permission logic
}, [...]);

// Pending action useEffect: restore state, then trigger GPS silently
useEffect(() => {
  const pending = pendingRef.current;
  if (!pending || pending.type !== 'ACTIVATE_PRESENCE') return;
  pendingRef.current = null;
  clearPendingAction();
  
  setSelectedPlaceId(pending.placeId);
  if (pending.expressionText) setExpressionText(pending.expressionText);
  setStep('expression');
  
  // Still need coords for activation — request GPS silently
  handleRequestLocation(); // will get coords without overriding step
}, []);
```

Modify `handleRequestLocation` so it doesn't call `setStep('select')` when a pending action is being restored (use the ref to guard).

### 2. Onboarding.tsx — Navigate with pending action awareness

In `handleComplete`, check for a pending action. If one exists, navigate to `/location` (already happens). No change needed here since the pending action is already in sessionStorage.

### 3. Ensure GPS coords load without resetting step

The `handleRequestLocation` callback currently sets `setStep('select')` on success (line 206). Guard this:

```
// In the geolocation success callback:
if (!pendingRef.current) {
  setStep('select');
}
```

This ensures coordinates load but the step stays on `'expression'` for the restored flow.

### Files Changed
- `src/pages/Location.tsx` — Add `pendingRef`, guard permission and GPS step transitions

