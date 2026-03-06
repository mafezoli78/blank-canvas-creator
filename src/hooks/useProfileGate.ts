import { useState, useCallback } from 'react';
import { useProfile } from '@/hooks/useProfile';
import { isProfileComplete as checkProfileComplete } from '@/utils/profileCompletion';

export function useProfileGate() {
  const { profile, interests, loading } = useProfile();
  const [isOpen, setIsOpen] = useState(false);

  const isProfileComplete = !loading && checkProfileComplete(profile, interests);

  const requireProfile = useCallback((): boolean => {
    if (isProfileComplete) return true;
    setIsOpen(true);
    return false;
  }, [isProfileComplete]);

  const openModal = useCallback(() => setIsOpen(true), []);
  const closeModal = useCallback(() => {
    setIsOpen(false);
  }, []);

  return {
    isProfileComplete,
    requireProfile,
    isOpen,
    openModal,
    closeModal,
    loading,
  };
}
