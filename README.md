# Endless Ocean

Just a rewrite of an endless ocean system I made around 2 years ago. Mainly just wanted to clean it up and improve performance.

## Improvements Over My Original

### Wave Simulation
- **Proper waves** using correct Gerstner Waves formula
- **Pre-baked wave constants** (`k`, `omega`, `dX`, `dZ`) computed once at init instead of every frame
- **SinCos lookup table** used in place of raw `math.sin`/`math.cos` calls during wave evaluation 

### Bone Culling & LOD
- **Two-stage culling** — `_scanRange` cheaply narrows the full bone list to a close-range subset before the more expensive visibility pass runs on it
- **Frustum culling** via `WorldToViewportPoint` skips bones not visible to the camera
- **Extended frustum margin** — bones just outside the screen edge are kept active to help prevent pop-in when panning
- **LOD levels** — bones update every frame, every 3rd, or every 8th frame depending on distance and graphics quality setting
- **Graphics quality scaling** — render range shrinks at lower quality settings

### Camera-Aware Rescanning
- **Forced rescan on camera rotation** — turning past ~4° immediately re-evaluates visibility instead of waiting for the next timer tick, eliminating the bone teleport/skip artifact
- **Forced rescan on camera movement** — same bypass triggers after moving 3+ studs

### Configuration
- All tuning values centralised in a single typed `Configuration` table
- Scan rates, LOD ranges, grid dimensions, and wave data are all hot-swappable without touching simulation code