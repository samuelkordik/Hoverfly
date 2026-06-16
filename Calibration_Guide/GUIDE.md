# Hoverfly Calibration & Tuning Guide (structured)

Machine-parseable procedure for calibrating the Hoverfly (Ender 3 Pro · SKR Mini E3 V2.0 ·
Sprite Extruder Pro direct drive · CRTouch · TMC2209). Human-friendly version:
[`index.html`](index.html). Interactive driver: [`CLAUDE.md`](CLAUDE.md).

Each step has a stable `id` and the fields: **Goal**, **STL**, **Setup**, **Commands**, **Observe**,
**Pass criteria**, **If fail**. Do the steps **in order** — later steps assume earlier ones passed.

## Firmware baseline (ground truth)

- Steps/mm `{80, 80, 400, 423}` (E already calibrated for Sprite). `EDITABLE_STEPS_PER_UNIT` on.
- Hotend PID `KP 21.73 / KI 1.54 / KD 76.55`. Bed = bang-bang (`PIDTEMPBED` off).
- `LIN_ADVANCE` on, `ADVANCE_K 0.0` (untuned). Input shaping off. `BABYSTEP_ZPROBE_OFFSET` off.
- ABL bilinear, 4×4 grid, `PROBING_MARGIN 50`, `NOZZLE_TO_PROBE_OFFSET {-30,-40,-3.49}`.
- Bed 210×210 (firmware), Zmax 250. Save anything with `M500`.

Filament for all temp/flow numbers below: **Elegoo PLA** (≈190–220 °C hotend, 50–60 °C bed).

---

## Step 1: bed-tramming
- **Goal:** Mechanically level (tram) the bed so all four corners are within ~0.1 mm before relying
  on the CRTouch mesh. ABL compensates for small variation; it should not paper over a badly skewed bed.
- **STL:** none (use the LCD / live moves).
- **Setup:** Heat bed to print temp (60 °C) so it sits at its working shape. Nozzle clean.
- **Commands:**
  ```gcode
  M140 S60      ; heat bed
  G28           ; home
  M211 S0       ; (optional) disable soft endstops while tramming corners
  G1 Z0.2 F600  ; move nozzle near bed, then jog to each corner
  ```
  Use the paper-drag test at each corner knob; adjust knobs until drag is equal everywhere.
- **Observe:** Paper drag (slight resistance) feels identical at all four corners + center.
- **Pass criteria:** Corner-to-corner nozzle height varies by < 0.1 mm (paper drag consistent).
- **If fail:** Re-level corners; if one corner can't reach, check bed springs/silicone spacers and
  gantry squareness (both Z leadscrews at equal height — power off, hand-turn to match).

## Step 2: pid-hotend
- **Goal:** Confirm/refresh hotend PID so temperature holds ±0.5 °C at print temp.
- **STL:** none.
- **Setup:** The stored `KP/KI/KD` (21.73/1.54/76.55) are generic stock Ender-3 values, **not** autotuned
  for the Sprite Pro's heavier heater block — a fresh `M303` is worthwhile. Part-cooling fan behavior
  matters — autotune at the fan state you print with. For PLA the part fan runs, so tune with a
  representative fan speed.
- **Commands:**
  ```gcode
  M303 E0 S205 C8 U1   ; autotune hotend at 205C, 8 cycles, apply result
  M500                 ; save
  M503                 ; verify stored KP/KI/KD
  ```
- **Observe:** During a hold at 205 °C the temperature is stable, not sawtoothing > ±1 °C.
- **Pass criteria:** Steady-state within ±0.5–1 °C; no thermal-runaway trip.
- **If fail:** Re-run with more cycles (`C10`); check the hotend fan and that the thermistor/heater
  cartridge are seated. Existing values (21.73/1.54/76.55) are a fine fallback.

## Step 3: esteps-flow
- **Goal:** Verify extruder E-steps (already 423) and then dial slicer **flow / extrusion multiplier**.
- **STL:** [`STL/single_wall_flow_25mm.stl`](STL/single_wall_flow_25mm.stl)
- **Setup (E-steps check):** Heat to 205 °C. Mark 120 mm of filament above the extruder.
- **Commands (E-steps):**
  ```gcode
  M83            ; relative extrusion
  G1 E100 F60    ; extrude 100mm slowly
  ; measure remaining: 120 - (distance left) should equal 100mm extruded
  M92 E<new>     ; only if off: new = 423 * 100 / actual_extruded
  M500
  ```
- **Setup (flow):** Slice `single_wall_flow_25mm.stl` with **1 perimeter, 0 top/bottom layers,
  0% infill** (or Spiral/Vase mode), 0.2 mm layer. Print in Elegoo PLA.
- **Observe (flow):** Measure wall thickness with calipers at several spots (target = your line width,
  e.g. 0.42–0.45 mm for a 0.4 nozzle).
- **Pass criteria:** Walls within ±0.02–0.03 mm of target, consistent; no gaps between wall and itself.
- **If fail:** `new_flow = current_flow × (target_wall / measured_wall)`. Set flow ratio in Orca
  (Filament → Flow ratio) and reprint. Re-confirm E-steps if flow is wildly off (>10%).

## Step 4: zoffset
- **Goal:** Set CRTouch Z-offset for a perfect first layer; learn live babystepping.
- **STL:** [`STL/firstlayer_patch_60mm.stl`](STL/firstlayer_patch_60mm.stl)
- **Setup:** Bed trammed (Step 1), mesh exists (or run Step 9 first time). Nozzle + bed at PLA temps.
- **Commands:**
  ```gcode
  G28
  M851 Z-3.49        ; current probe Z-offset (info; from NOZZLE_TO_PROBE_OFFSET)
  ; start the firstlayer_patch print, then during layer 1:
  ;   double-click the encoder -> Babystep Z; nudge down (negative) if too high,
  ;   up (positive) if nozzle is dragging/scraping
  M500               ; save (note: persists Z babystep only if BABYSTEP_ZPROBE_OFFSET is enabled)
  ```
- **Observe:** First-layer lines squish together with no gaps, top surface smooth and matte-uniform,
  not translucent (too high) and not rough/ridged/scraped (too low).
- **Pass criteria:** Solid patch with no gaps between lines, no elephant-foot ooze, peels off in one piece.
- **If fail:** Adjust Z-offset ±0.02–0.05 mm and reprint a patch. See firmware review §3 — enabling
  `BABYSTEP_ZPROBE_OFFSET` makes the live babystep save into the probe offset with `M500`.

## Step 5: temp-tower
- **Goal:** Find the best nozzle temperature for this Elegoo PLA spool (adhesion vs stringing/quality).
- **STL:** [`STL/temp_tower_70mm.stl`](STL/temp_tower_70mm.stl) — 7 bands; sweep ~220 → 190 °C (one temp per band). For a fancier labeled tower see `STL/ATTRIBUTION.md`.
- **Setup:** Use the model's per-band temperature G-code (or Orca's temperature-tower calibration,
  which inserts `M104` per height). 0.2 mm layer, normal speed.
- **Commands:** (Orca handles this; manual height-change marker shown for reference)
  ```gcode
  ; at each band height the slicer inserts e.g.:
  M104 S210
  ```
- **Observe:** Per band, judge layer adhesion (try to snap it), bridging strands, overhang quality,
  stringing, and surface finish.
- **Pass criteria:** Pick the **lowest** temperature that still gives strong layer bonding and clean
  surfaces — usually ~200–210 °C for Elegoo PLA.
- **If fail:** If every band strings, you're too hot and/or retraction needs Step 6; if layers
  delaminate at all bands, you're too cold or cooling too aggressively.

## Step 6: retraction-pa
- **Goal:** Eliminate stringing/oozing (retraction) and sharpen corners/seams (pressure/linear advance).
- **STL:** [`STL/retraction_test_50mm.stl`](STL/retraction_test_50mm.stl) — two posts, travel across the 32 mm gap strings if retraction is poor; PA via Orca's calibration test.
- **Setup:** Use the temp from Step 5. Direct drive = **short** retraction.
- **Commands / values:**
  ```gcode
  M83
  ; Orca Pressure Advance (Pattern, Direct Drive): sweep K 0.0–0.10 step 0.005, then a fine
  ; second pass at 0.002 around the best band. Or set Marlin Linear Advance directly:
  M900 K0.04     ; try a value
  M500
  ```
  **Order: tune pressure advance (K) first, then retraction** — good PA relieves nozzle pressure and
  shrinks the retraction you need. Retraction starting point (direct drive, Sprite): **0.6–0.8 mm @
  25 mm/s**. ⚠️ The firmware E max feedrate is **25 mm/s**, so any higher retraction speed is silently
  clamped — tune **distance**, not speed (or raise `DEFAULT_MAX_FEEDRATE` E). Tune distance down until
  stringing returns, then back up one notch.
- **Observe:** Retraction tower — strings between towers. PA test — corner bulge / gaps at line ends.
- **Pass criteria:** No (or wispy, removable) strings; corners crisp with no bulge and no under-fill
  at the start of perimeters.
- **If fail:** More retraction **distance** for strings (speed is capped at 25 mm/s, so raising it does
  nothing; don't exceed ~1.5 mm on direct drive); adjust `M900 K` up if corners bulge, down if corners
  show gaps. Use **one** of Marlin K or Orca PA.

## Step 7: speed-accel
- **Goal:** Find the highest acceleration the machine runs without ringing/skips; raise firmware
  ceilings if needed.
- **STL:** [`STL/calibration_cube_20mm.stl`](STL/calibration_cube_20mm.stl) and/or [`STL/ringing_tower_60mm.stl`](STL/ringing_tower_60mm.stl).
- **Setup:** Print the cube at increasing accel; watch for ghosting after sharp features and for
  skipped steps (layer shift).
- **Commands:**
  ```gcode
  M201 X1000 Y1000     ; raise max accel to test (firmware default 500)
  M204 P1000           ; print accel
  M203 X500 Y500       ; max feedrate (already high)
  M500                 ; save only the values you settle on
  ```
- **Observe:** Dimensional accuracy of the 20 mm cube (X/Y/Z within ±0.1–0.2 mm), echo/ghost lines
  after corners, any layer shift.
- **Pass criteria:** Cube measures 20 ±0.2 mm each axis; no skipped steps; acceptable ringing.
- **If fail:** Back off accel; if the cube is consistently off-dimension, recheck belt tension and
  steps/mm (X/Y 80, Z 400). Don't exceed what Step 8 shows is ring-free.

## Step 8: shaping
- **Goal:** Reduce ringing/ghosting — measure resonance and (optionally) enable Input Shaping.
- **STL:** [`STL/ringing_tower_60mm.stl`](STL/ringing_tower_60mm.stl) — nubs every 10 mm imprint resonance echoes.
- **Setup:** **First confirm IS even fits on the F103.** Enable `INPUT_SHAPING_X/Y` plus
  `SHAPING_MIN_FREQ 20.0` (bounds the SRAM step buffer), build, and check the linker does **not** report
  *"region RAM overflowed"* before you bother printing (firmware review §7). Then print the ringing tower
  in vase mode at high accel (override the 500 ceiling for the test: `M204 S1500`) and sweep frequency up
  the tower with a slicer "after layer change" macro:
  ```gcode
  ; sweeps M593 frequency 15 → 60 Hz over the tower height:
  M593 F{(layer_num < 2 ? 0 : 15 + 45.0 * (layer_num - 2) / 297)}
  ```
- **Commands:** (only if IS compiled + fit) — read the smoothest band, convert its height to Hz, set per axis:
  ```gcode
  M593 X F40       ; X shaper frequency (from the cleanest band)
  M593 Y F38       ; Y shaper frequency
  M593 X D0.15 Y D0.15  ; damping (zeta) — then refine in 0.05 steps
  M500
  ```
  Then **re-tune Linear Advance K (Step 6) after IS** — the sweep runs with LA off, so K is finalized last.
- **Observe:** Ghosting echoes after sharp corners; their period gives the resonant frequency.
- **Pass criteria:** Visible reduction in ghosting; corners clean at your chosen accel.
- **If fail:** If IS won't build/flash, instead **lower acceleration** (Step 7) to the ring-free value,
  or consider Klipper for first-class resonance compensation.

## Step 9: bed-mesh
- **Goal:** Produce a reliable ABL mesh and validate first-layer consistency across the whole bed.
- **STL:** [`STL/firstlayer_patch_60mm.stl`](STL/firstlayer_patch_60mm.stl) (print at several bed
  locations or scale up).
- **Setup:** Probe at **real print temp**. `PREHEAT_BEFORE_LEVELING` is on, but check
  `LEVELING_BED_TEMP` — if it's left at a low preheat default (often ~50 °C) it's below your 60 °C PLA bed,
  so the mesh misses warp present when hot. Set `#define LEVELING_BED_TEMP 60`, or run `G29` in start-gcode
  after the bed soaks (`M190 S60` → `G4 S300`). Clean nozzle (no ooze blob on tip).
- **Commands:**
  ```gcode
  M190 S60 ; M109 S205   ; reach + hold print temps first
  M48 P10                ; probe repeatability — want std dev < 0.02mm (>0.05 = EMI/loose mount)
  G28
  G29                    ; probe the bilinear mesh
  M500                   ; store mesh
  M420 S1 Z10            ; enable leveling + fade height 10mm
  G26 B60 H205           ; (if G26_MESH_VALIDATION compiled) print a mesh-check pattern
  ```
- **Observe:** `M48` std dev < 0.02 mm. Mesh values in the LCD/`M420 V` — spread should be small (a few
  tenths). First-layer patches (and the `G26` pattern) consistent in every region.
- **Pass criteria:** `M48` σ < 0.02 mm; mesh Z range < ~0.3–0.4 mm; first layer equally good center and edges.
- **If fail:** If the spread is large, redo Step 1 (tramming). Consider `GRID_MAX_POINTS 5×5` and
  lowering `PROBING_MARGIN` (firmware review §5–6) to mesh more of the bed.

---

## Done / save order

After each step that changes a stored value, run `M500`. Recommended end state: PID saved, flow
dialed in Orca, Z-offset saved, best temp + retraction + K saved, accel set, mesh stored and
`M420 S1` enabled in your slicer's start G-code.
