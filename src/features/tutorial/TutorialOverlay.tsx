import { useState, useCallback, type ReactNode } from 'react';
import Joyride, { type CallBackProps, STATUS } from 'react-joyride';
import { tutorialSteps } from './tutorialSteps';
import { useProfile } from '@/hooks/useProfile';

interface TutorialOverlayProps {
  children: ReactNode;
}

export function TutorialOverlay({ children }: TutorialOverlayProps) {
  const { profile, loading, updateProfile } = useProfile();
  const [run, setRun] = useState(true);

  const handleCallback = useCallback(async (data: CallBackProps) => {
    const { status } = data;
    if (status === STATUS.FINISHED || status === STATUS.SKIPPED) {
      setRun(false);
      await updateProfile({ tutorial_enabled: false } as any);
    }
  }, [updateProfile]);

  if (loading || !profile || !(profile as any).tutorial_enabled) {
    return <>{children}</>;
  }

  return (
    <>
      <Joyride
        steps={tutorialSteps}
        run={run}
        continuous
        showSkipButton
        showProgress
        disableScrolling={false}
        callback={handleCallback}
        locale={{
          back: 'Voltar',
          close: 'Fechar',
          last: 'Entendi!',
          next: 'Próximo',
          skip: 'Pular tutorial',
        }}
        styles={{
          options: {
            primaryColor: 'hsl(var(--primary))',
            zIndex: 10000,
          },
          tooltip: {
            borderRadius: 12,
            fontSize: 14,
          },
          buttonNext: {
            borderRadius: 8,
            fontSize: 14,
            fontWeight: 600,
          },
          buttonBack: {
            borderRadius: 8,
            fontSize: 14,
          },
          buttonSkip: {
            fontSize: 13,
          },
        }}
      />
      {children}
    </>
  );
}
