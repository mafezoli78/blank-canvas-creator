import { useState, useCallback } from 'react';
import {
  PresenceLogicalState,
  PresenceEndReason,
  PresenceState,
  isHumanEndReason,
} from '@/types/presence';
import type { Presence } from './types';

/**
 * Sub-hook: derives logical state from presence + end reason semantics.
 * 
 * RULE: 'ended' ONLY via explicit human-initiated reason
 * RULE: Technical failures = always 'suspended'
 * RULE: No presence + no reason = 'ended' (clean state, allows navigation)
 */
export function usePresenceState(currentPresence: Presence | null) {
  const [lastEndReason, setLastEndReason] = useState<PresenceEndReason | null>(null);
  const [isRevalidating, setIsRevalidating] = useState(false);
  const [lastValidatedAt, setLastValidatedAt] = useState<string | null>(null);
  const [isSuspended, setIsSuspended] = useState(false);
  const [isEnteringPlace, setIsEnteringPlace] = useState(false);

  const deriveLogicalState = useCallback((): PresenceLogicalState => {
    if (currentPresence && currentPresence.ativo) return 'active';
    if (isSuspended) return 'suspended';

    if (lastEndReason && lastEndReason.isHumanInitiated && isHumanEndReason(lastEndReason.type)) {
      return 'ended';
    }

    if (lastEndReason && !lastEndReason.isHumanInitiated) {
      return 'suspended';
    }

    if (!currentPresence && !lastEndReason) {
      return 'ended';
    }

    console.error('[usePresenceState] 🚨 Impossible state reached:', {
      hasPresence: !!currentPresence,
      isSuspended,
      lastEndReason,
    });
    return 'ended';
  }, [currentPresence, isSuspended, lastEndReason]);

  const presenceState: PresenceState = {
    logicalState: deriveLogicalState(),
    endReason: lastEndReason,
    isRevalidating,
    lastValidatedAt,
    isEnteringPlace,
  };

  return {
    presenceState,
    lastEndReason,
    setLastEndReason,
    isRevalidating,
    setIsRevalidating,
    lastValidatedAt,
    setLastValidatedAt,
    isSuspended,
    setIsSuspended,
    isEnteringPlace,
    setIsEnteringPlace,
  };
}
