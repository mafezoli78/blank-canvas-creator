

## Wizard por categoria — InterestsStep.tsx

Complete rewrite of `src/components/onboarding/InterestsStep.tsx` to a one-category-at-a-time wizard.

### What changes

**Single file**: `src/components/onboarding/InterestsStep.tsx` — full replacement.

### Implementation

- Local state: `categoryIndex` (number, starts at 0)
- Show one category at a time from `categories[categoryIndex]`
- Progress bar at top: filled width = `(categoryIndex + 1) / categories.length * 100%`, label "X de Y"
- Tags rendered as `button` elements in `flex flex-wrap gap-2`, styled with `rounded-xl`, `bg-muted` default, `bg-accent` when selected
- Add a "Nenhuma delas" button after all category interests
- On tag click: deselect any previously selected tag in current category via `onToggleInterest`, select new tag via `onToggleInterest`, then after 200ms `setTimeout` advance to next category or call `onNext()` on last
- "Voltar" button: if `categoryIndex > 0` go back, else call `onBack()`
- Previous selections preserved when navigating back
- Remove all old constants (MIN/MAX), validation logic, and the "Continuar" button
- Props interface unchanged: `{ selectedInterests, onToggleInterest, onNext, onBack }`
- Loading state preserved (spinner while categories load)
- "Nenhuma delas" works by deselecting any current category selection without selecting anything new, then advancing

### Files

| File | Action |
|---|---|
| `src/components/onboarding/InterestsStep.tsx` | Full rewrite |

No other files modified.

