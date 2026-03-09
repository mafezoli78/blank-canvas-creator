import { useEffect } from 'react';
import type { Presence } from './types';

interface UsePresenceLifecycleOptions {
  userId: string | undefined;
  hasFetchedOnce: boolean;
  currentPresence: Presence | null;
  onBackground: () => void;
  onForeground: () => void;
}

/**
 * Sub-hook: handles visibility, focus, and bfcache lifecycle events.
 * Sets suspended on hide, triggers revalidation on return.
 */
export function usePresenceLifecycle({
  userId,
  hasFetchedOnce,
  currentPresence,
  onBackground,
  onForeground,
}: UsePresenceLifecycleOptions) {
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'hidden') {
        if (currentPresence) {
          console.log('[usePresence] App going to background - marking as suspended');
          onBackground();
        }
      } else if (document.visibilityState === 'visible' && userId && hasFetchedOnce) {
        console.log('[usePresence] App returned to foreground - revalidating presence');
        onForeground();
      }
    };

    const handleFocus = () => {
      if (userId && hasFetchedOnce) {
        console.log('[usePresence] Window focus - revalidating presence');
        onForeground();
      }
    };

    const handlePageShow = (event: PageTransitionEvent) => {
      if (event.persisted && userId && hasFetchedOnce) {
        console.log('[usePresence] Page restored from bfcache - revalidating presence');
        onForeground();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', handleFocus);
    window.addEventListener('pageshow', handlePageShow);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('pageshow', handlePageShow);
    };
  }, [userId, hasFetchedOnce, currentPresence, onBackground, onForeground]);
}
