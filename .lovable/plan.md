

## Analysis

### Bucket Status
The `checkin-selfies` bucket is **already private** with correct RLS policies:
- **SELECT**: authenticated users only
- **INSERT/DELETE**: scoped to user's own folder via `auth.uid()`

No database changes needed for item 1.

### Face Detection Implementation

Add real-time face detection to `CheckinSelfie.tsx` using `face-api.js` with the `TinyFaceDetector` model (~190KB). The capture button stays disabled until a face is detected, with a graceful fallback if models fail to load.

---

## Plan

### 1. Install `face-api.js`
Add the npm dependency.

### 2. Download TinyFaceDetector model files to `public/models/`
Two files from the [face-api.js weights directory](https://github.com/justadudewhohacks/face-api.js/tree/master/weights):
- `tiny_face_detector_model-weights_manifest.json`
- `tiny_face_detector_model-shard1`

These will be fetched and written into `public/models/`.

### 3. Modify `src/components/location/CheckinSelfie.tsx`

**New state and refs:**
- `faceDetected` (boolean) — whether a face is currently visible
- `modelsLoaded` (boolean) — whether TinyFaceDetector loaded successfully
- `detectionIntervalRef` — interval handle for cleanup

**New effects:**
- **Load models once on mount** — call `faceapi.nets.tinyFaceDetector.loadFromUri('/models')`. On failure, set both `modelsLoaded` and `faceDetected` to true (graceful fallback — don't block the user).
- **Run detection loop when `step === 'capture'` and models are loaded** — every 400ms, run `faceapi.detectSingleFace()` with `TinyFaceDetectorOptions({ inputSize: 160, scoreThreshold: 0.5 })`. Update `faceDetected` accordingly. Clean up interval on step change or unmount.

**JSX changes (capture step only):**
- Add an overlay indicator at the bottom of the video: green pill "Rosto detectado" or neutral "Posicione seu rosto"
- Capture button: `disabled={!faceDetected || !modelsLoaded}`, label changes to reflect state ("Carregando..." / "Posicione seu rosto" / "Capturar")

**No changes to:** `handleCapture`, `handleRetake`, `handleUsePhoto`, `handleCancel`, preview step, fallback-upload step, props/interface, or `cameraService.ts`.

---

## Files to create/modify

| File | Action |
|---|---|
| `package.json` | Add `face-api.js` dependency |
| `public/models/tiny_face_detector_model-weights_manifest.json` | Create (download from GitHub) |
| `public/models/tiny_face_detector_model-shard1` | Create (download from GitHub) |
| `src/components/location/CheckinSelfie.tsx` | Add face detection logic + UI indicators |

No database migration needed — bucket is already properly configured.

