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
