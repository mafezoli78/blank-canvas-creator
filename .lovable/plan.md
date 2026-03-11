

## Correções Cirúrgicas no TutorialFlow.tsx

### Files to create/modify

**1. Copy photos to `public/tutorial/`**
- Copy `user-uploads://Ana.jpg` → `public/tutorial/ana.jpg`
- Copy `user-uploads://Carlos.jpg` → `public/tutorial/carlos.jpg`
- Copy `user-uploads://Marina.jpg` → `public/tutorial/marina.jpg`

**2. Create `src/components/tutorial/tutorialCharacters.ts`**
- Export `TUTORIAL_CHARACTERS` array with `/tutorial/ana.jpg`, `/tutorial/carlos.jpg`, `/tutorial/marina.jpg` paths

**3. Edit `src/components/tutorial/TutorialFlow.tsx`**

All changes below, no other files touched:

| Area | Current | Fix |
|---|---|---|
| **Characters** | Inline `CHARACTERS` with broken base64 | Import `TUTORIAL_CHARACTERS` from `tutorialCharacters.ts`, replace all `CHARACTERS` references |
| **CharAvatar** | `rounded-full` (circular) | Change to `rounded-xl` (square with rounded corners) everywhere photos appear |
| **Text sizes** | Some `text-[10px]` in cards | Replace all `text-[10px]` with `text-xs` minimum |
| **Nav buttons (steps 1-6)** | Mixed labels ("Entendi", "Quase lá!", "Continuar") and inconsistent heights | Standardize: left = "Voltar" `h-11`, right = "Continuar" `h-11`, both `flex-1`. Remove `flex-[2]` |
| **Step 1 icons** | Emoji icons (`☕ 🌳 📚`) | Replace with `<Store>` lucide icon in `bg-muted` circle, monochrome |
| **Step 1 tooltip arrow** | Arrow points up-left (`-top-2 left-6`) | Arrow points up-right (`-top-2 right-6`) |
| **Step 1 tooltip button labels** | "Próximo" / "Entendi" | All 4 → "Ok" |
| **Step 1 List/Map toggle** | Bottom-left, with text labels | Move to header area (top-right), icons only (no "Lista"/"Mapa" text) |
| **Step 1 after tooltip 4** | Extra "Entendi" button appears in footer area | After tooltipStep=4: remove extra button, show only standard "Voltar"/"Continuar" footer |
| **Step 3 selfie card photo** | `rounded-lg` on img | Change to `rounded-xl`, ensure uses `TUTORIAL_CHARACTERS[1].photo` |
| **Step 5 (aceno) photos** | `rounded-lg` circular-ish | `rounded-xl` square photos, size `w-14 h-14` instead of `w-[36%]` layout. Photo left, info right, "Acenar" button full-width below info |
| **Step 6 swipe actions** | Side-by-side (`flex-1` horizontally) with colored backgrounds | Stack vertically (`flex-col`), no background color, transparent, ~80px wide. Remove `bg-muted` and `bg-destructive/10` |
| **Step 6 nav button** | "Quase lá!" | "Continuar" |

### Technical details

- The `FICTIONAL_PLACES` array stays in TutorialFlow but icons change from emoji strings to a `type` field used to render `<Store>` icon
- Step 1 header restructured: title left, List/Map icons right (just `<List>` and `<Map>` buttons, no text)
- Step 1 footer simplified: when `tooltipStep >= 4`, render only the standard two-button footer ("Voltar" / "Continuar"), no extra elements
- Step 5 person cards: change from `w-[36%]` image layout to a compact row with `w-14 h-14` square image + info column + full-width "Acenar" button below

