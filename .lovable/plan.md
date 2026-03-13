

## Implement Report Button — ChatWindow and PersonCard

### Files to create

1. **`src/hooks/useReport.ts`** — Hook with `MOTIVOS` constant and `sendReport` function that inserts into the `reports` table via Supabase. Includes toast feedback on success/error.

2. **`src/components/shared/ReportModal.tsx`** — Reusable dialog with motivo selection (radio-style buttons), cancel/confirm actions. Props: `open`, `onClose`, `reportedUserId`, `reportedUserName`, `contexto`, `conversationId?`.

### Files to modify

3. **`src/components/chat/ChatWindow.tsx`**
   - Add imports: `MoreVertical`, `Flag`, `DropdownMenu` components, `ReportModal`
   - Add `showReportModal` state
   - In header (line 89-94): wrap existing "Encerrar" button and new `⋮` dropdown in a `div` with `flex items-center gap-1`
   - The dropdown has a single "Denunciar" item with destructive styling
   - Render `ReportModal` at the end with `contexto="chat"` and `conversationId`

4. **`src/components/home/PersonCard.tsx`**
   - Add imports: `MoreVertical`, `Flag`, `DropdownMenu` components, `ReportModal`
   - Add `showReportModal` state
   - In content area (line 276-280): wrap name row in a flex container with `justify-between`, add `⋮` dropdown button on the right
   - Render `ReportModal` after the photo dialog with `contexto="home"`

### No database changes needed
The `reports` table already exists with appropriate RLS policies.

