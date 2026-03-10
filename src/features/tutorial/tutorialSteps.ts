import type { Step } from 'react-joyride';

export const tutorialSteps: Step[] = [
  {
    target: '#presence-timer',
    content: 'Sua presença dura até 2 horas. Você pode renovar ou sair a qualquer momento.',
    disableBeacon: true,
  },
  {
    target: '#people-feed',
    content: 'Essas são as pessoas que estão neste mesmo lugar agora.',
    disableBeacon: true,
  },
  {
    target: '#user-card',
    content: 'Veja informações da pessoa e interesses em comum para iniciar conversas.',
    disableBeacon: true,
  },
  {
    target: '#wave-button',
    content: 'Envie um aceno. Se a outra pessoa aceitar, o chat começa automaticamente.',
    disableBeacon: true,
  },
  {
    target: '#card-slider',
    content: 'Arraste o cartão para a esquerda para silenciar ou bloquear alguém.',
    disableBeacon: true,
  },
];
