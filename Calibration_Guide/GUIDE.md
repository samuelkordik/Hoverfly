# Hoverfly Calibration & Tuning Guide (structured)

Machine-parseable procedure for calibrating the Hoverfly (Ender 3 Pro · SKR Mini E3 V2.0 ·
Sprite Extruder Pro direct drive · CRTouch · TMC2209). Human-friendly version:
[`index.html`](index.html). Interactive driver: [`CLAUDE.md`](CLAUDE.md).

Each step has a stable `id` and the fields: **Goal**, **STL**, **Run** (how to do it with no G-code
terminal), **Setup**, **Commands** (the raw codes, for reference), **Observe**, **Pass criteria**,
**If fail**. Do the steps **in order** — later steps assume earlier ones passed.

## Firmware baseline (ground truth)

- Steps/mm `{80, 80, 400, 423}` (E already calibrated for Sprite). `EDITABLE_STEPS_PER_UNIT` on.
- Hotend PID `KP 21.73 / KI 1.54 / KD 76.55`. Bed = bang-bang (`PIDTEMPBED` off).
- `LIN_ADVANCE` on, `ADVANCE_K 0.0` (untuned). Input shaping off. `BABYSTEP_ZPROBE_OFFSET` off.
- ABL bilinear, 4×4 grid, `PROBING_MARGIN 50`, `NOZZLE_TO_PROBE_OFFSET {-30,-40,-3.49}`.
- Bed 210×210 (firmware), Zmax 250. Save with `M500` (built into the SD macros, or LCD → Store Settings).

Filament for all temp/flow numbers below: **Elegoo PLA** (≈190–220 °C hotend, 50–60 °C bed).

## Running these without a terminal

Hoverfly has **no G-code console** (no Pi / OctoPrint / USB terminal). Each step's **Run** line says how
to do it, one of three ways:

- **LCD menu** — steps/mm, acceleration, babystep Z, Store Settings (`M500`), and the mesh viewer.
- **Orca Slicer → Calibration menu** — generates the temperature / flow / pressure-advance / retraction
  tests as ordinary prints. No codes.
- **SD macro files** in [`macros/`](macros/) — for one-off commands (PID, mesh build, set-a-value). Copy
  them to the SD card once, then **Print** the named file. `SET_*` files must be **edited first**.

The **Commands** blocks below show the raw M-codes for reference (and for the planned Klipper console) —
you don't type them. `M48`, `M503`, and `M420 V` only report over USB serial, so they're skipped here:
use the **LCD mesh viewer**, and defer `M48` probe-repeatability to the Klipper move.

**First-run order (fresh printer):** the steps are written 1→9, but Step 4 (Z-offset) needs an active
mesh — a good first layer is mesh-compensated. So on a brand-new printer run **1 → 2 → 3 → 9 (build the
first mesh) → 4 → 5–8**. PID and E-steps (Steps 2–3) are independent and can precede the mesh; the mesh
itself (Step 9) builds fine before the Z-offset is dialed (it's relative). After that initial pass the
numeric 1→9 order is fine for re-tuning.

---

## Step 1: bed-tramming
- **Goal:** Mechanically level (tram) the bed so all four corners are within ~0.1 mm before relying
  on the CRTouch mesh. ABL compensates for small variation; it should not paper over a badly skewed bed.
- **STL:** none (use the LCD / live moves).
- **Run:** All on the **LCD**, no macro — heat the bed, Auto Home, then jog Z to ~0.2 mm and visit each
  corner (or use the Bed Tramming menu if your build has it).
- **Setup:** Heat bed to print temp (60 °C) so it sits at its working shape. Nozzle clean.
- **Commands:**
  ```gcode
  M140 S60      ; heat bed
  G28           ; home
  M211 S0       ; (reference only — disables soft endstops; re-enable with M211 S1 after)
  G1 Z0.2 F600  ; move nozzle near bed, then jog to each corner
  ```
  Use the paper-drag test at each corner knob; adjust knobs until drag is equal everywhere. The supported
  flow is **LCD jog only** — no macro sends `M211`, so soft endstops stay on. If you ever disable them
  manually (`M211 S0`), re-enable with `M211 S1` afterward (they also reset on power-cycle).
- **Observe:** Paper drag (slight resistance) feels identical at all four corners + center.
- **Pass criteria:** Corner-to-corner nozzle height varies by < 0.1 mm (paper drag consistent).
- **If fail:** Re-level corners; if one corner can't reach, check bed springs/silicone spacers and
  gantry squareness (both Z leadscrews at equal height — power off, hand-turn to match).

## Step 2: pid-hotend
- **Goal:** Confirm/refresh hotend PID so temperature holds ±0.5 °C at print temp.
- **STL:** none.
- **Run:** Print [`macros/PID_HOTEND.gcode`](macros/PID_HOTEND.gcode) from SD (autotunes with the part
  fan on, applies, and saves). `M303` pauses for an LCD acknowledge when it finishes — that's normal.
- **Setup:** The stored `KP/KI/KD` (21.73/1.54/76.55) are generic stock Ender-3 values, **not** autotuned
  for the Sprite Pro's heavier heater block — a fresh autotune is worthwhile. The macro tunes with the
  part fan on, matching real PLA printing.
- **Commands:** (what the macro runs — for reference, you don't type these)
  ```gcode
  M106 S255            ; part fan on (tune under print-like cooling)
  M303 E0 S205 C8 U1   ; autotune hotend at 205C, 8 cycles, apply result
  M107                 ; fan off
  M500                 ; save
  ```
- **Observe:** During a hold at 205 °C the temperature is stable, not sawtoothing > ±1 °C.
- **Pass criteria:** Steady-state within ±0.5–1 °C; no thermal-runaway trip.
- **If fail:** Re-run with more cycles (`C10`); check the hotend fan and that the thermistor/heater
  cartridge are seated. Existing values (21.73/1.54/76.55) are a fine fallback.

## Step 3: esteps-flow
- **Goal:** Verify extruder E-steps (already 423) and then dial slicer **flow / extrusion multiplier**.
- **STL:** [`STL/single_wall_flow_25mm.stl`](STL/single_wall_flow_25mm.stl)
- **Run:** E-steps — Print [`macros/ESTEPS_TEST.gcode`](macros/ESTEPS_TEST.gcode), measure, then set the
  new value via the **LCD Steps/mm** menu or [`macros/SET_ESTEPS.gcode`](macros/SET_ESTEPS.gcode) (edit
  first). Flow — use Orca's **Flow Rate** calibration (generates the print).
- **Setup (E-steps check):** Heat to 205 °C. Mark 120 mm of filament above the extruder. Measure the
  remaining filament **2–3 times (or re-run) and average** — a 1 mm read error is ~1% of E-steps. Mark
  and measure against a fixed point on the **extruder body**, not the nozzle tip. The test extrudes
  100 mm and does **not** retract, so expect a ~100 mm strand hanging from the nozzle — snip it off after
  measuring. **Confirm on LCD:** Configuration → Advanced Settings → Steps/mm → E steps/mm.
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
- **Run:** **Until you reflash with `BABYSTEP_ZPROBE_OFFSET` (firmware review §3), use
  [`macros/SET_ZOFFSET.gcode`](macros/SET_ZOFFSET.gcode)** (edit `M851 Z<value>` + `M500`) — that
  persists. The **LCD live-babystep method** (double-click the encoder → **Babystep Z**, dial by feel) is
  great for finding the value, but with `BABYSTEP_ZPROBE_OFFSET` *off* the babystep is **not** folded into
  the probe offset by Store Settings and is lost on reboot; once that flag is enabled, the live method
  persists with **Configuration → Store Settings**. **Confirm on LCD:** Configuration → Probe Z Offset.
- **Setup:** Bed trammed (Step 1) **and a mesh already built (Step 9)** — on a fresh printer do Step 9
  before this step (see *First-run order* above). Nozzle + bed at PLA temps.
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
- **Run:** Orca → **Calibration → Temperature tower** generates the print and inserts the per-band temps
  for you — no codes. (Or slice the STL above with Orca's height-based temperature changes.)
- **Setup:** 0.2 mm layer, normal speed. Orca's temperature-tower calibration inserts `M104` per height.
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
- **Loop back if needed:** Step 2 autotuned PID at 205 °C. If your chosen tower temp differs from 205 by
  more than ~10 °C, re-run [`macros/PID_HOTEND.gcode`](macros/PID_HOTEND.gcode) after editing it to
  autotune at your final temp (`M303 E0 S<temp>`), then `M500` — PID constants are mildly
  temperature-dependent, so tuning near your real print temp is best. A ±5–10 °C delta rarely matters.

## Step 6: retraction-pa
- **Goal:** Eliminate stringing/oozing (retraction) and sharpen corners/seams (pressure/linear advance).
- **STL:** [`STL/retraction_test_50mm.stl`](STL/retraction_test_50mm.stl) — two posts, travel across the 32 mm gap strings if retraction is poor; PA via Orca's calibration test.
- **Run:** Orca → **Calibration → Pressure Advance** (Pattern, Direct Drive) and **Retraction test** —
  both generate prints. Apply the chosen PA via Orca, or [`macros/SET_PA.gcode`](macros/SET_PA.gcode);
  set retraction distance/speed in Orca's filament/printer settings.
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
  stringing returns, then back up one notch. **Note:** Orca's *Enable pressure advance* checkbox injects
  `M900 K` into the print G-code and overrides firmware K every print, so **untick it** when you're relying
  on `SET_PA.gcode`/`M500` (Marlin K).
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
- **Run:** Set acceleration via the **LCD Acceleration** menu or [`macros/SET_ACCEL.gcode`](macros/SET_ACCEL.gcode)
  (edit values first), then print the cube/tower from SD at each setting to test.
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
  after corners, any layer shift. **Confirm on LCD:** Configuration → Advanced Settings → Acceleration.
- **Pass criteria:** Cube measures 20 ±0.2 mm each axis; no skipped steps; acceptable ringing.
- **If fail:** Back off accel; if the cube is consistently off-dimension, recheck belt tension and
  steps/mm (X/Y 80, Z 400). Don't exceed what Step 8 shows is ring-free.

## Step 8: shaping
- **Goal:** Reduce ringing/ghosting — measure resonance and (optionally) enable Input Shaping.
- **STL:** [`STL/ringing_tower_60mm.stl`](STL/ringing_tower_60mm.stl) — nubs every 10 mm imprint resonance echoes.
- **Run:** Only if Input Shaping is compiled **and** fits. Sweep with the slicer "after layer change"
  macro (below), then apply the result with [`macros/SET_SHAPER.gcode`](macros/SET_SHAPER.gcode) (edit
  the measured frequencies first). If IS won't fit, this step is "lower accel" only (see *If fail*).
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
- **If fail:** If IS won't build/flash, instead **lower acceleration** (Step 7) to the ring-free value.
  First-class resonance compensation is part of the planned Klipper migration (firmware review).

## Step 9: bed-mesh
- **Goal:** Produce a reliable ABL mesh and validate first-layer consistency across the whole bed.
- **STL:** [`STL/firstlayer_patch_60mm.stl`](STL/firstlayer_patch_60mm.stl) (print at several bed
  locations or scale up).
- **Run:** Print [`macros/BUILD_MESH.gcode`](macros/BUILD_MESH.gcode) from SD (heats, homes, probes,
  saves, enables). View the result on the **LCD mesh viewer** — `M420 V` and `M48` are serial-only, so
  skip `M48` probe-repeatability until the Klipper console.
- **Setup:** Probe at **real print temp**. `PREHEAT_BEFORE_LEVELING` is on, but `LEVELING_BED_TEMP` is
  currently **50** (below your 60 °C PLA bed), so a reflash to `#define LEVELING_BED_TEMP 60` is
  worthwhile; until then, run `G29` in start-gcode after the bed soaks (`M190 S60` → `G4 S300`). Clean
  nozzle (no ooze blob on tip). **Confirm on LCD:** Configuration → (Bed) Leveling → Mesh viewer.
- **Commands:** (what `BUILD_MESH.gcode` runs — for reference)
  ```gcode
  M140 S60 ; M104 S150   ; bed to print temp; warm nozzle (low ooze)
  M190 S60 ; M109 S150    ; wait for both
  G28
  G29                    ; probe the bilinear mesh
  M500                   ; store mesh
  M420 S1 Z10            ; enable leveling + fade height 10mm
  ; optional, separately: G26 B60 H205  (if G26_MESH_VALIDATION compiled) prints a mesh-check pattern
  ```
- **Observe:** View the stored mesh on the **LCD mesh viewer** — spread should be small (a few tenths).
  First-layer patches consistent in every region (optionally confirm with a `G26` pattern if compiled).
- **Pass criteria:** Mesh Z range < ~0.3–0.4 mm; first layer equally good center and edges.
- **If fail:** If the spread is large, redo Step 1 (tramming). Consider `GRID_MAX_POINTS 5×5` and
  lowering `PROBING_MARGIN` (firmware review §5–6) to mesh more of the bed.

---

## Done / save order

Each step that changes a stored value saves it with `M500` (the SD macros do this; or use the LCD →
Store Settings). Recommended end state: PID saved, flow dialed in Orca, Z-offset saved, best temp +
retraction + K saved, accel set, mesh stored and `M420 S1` enabled in your slicer's start G-code.
If the temp tower moved your print temp more than ~10 °C from 205, re-run hotend PID at the new temp.

> **Flash-emulated EEPROM caveat (SKR Mini E3 V2.0):** there's no real EEPROM — `M500` writes to a
> reserved flash sector and is reliable day-to-day, but a **reflash can change the EEPROM layout and
> reset all stored values to defaults**. After *any* firmware update, re-verify (and re-save) PID,
> E-steps, Z-offset, K, accel, and rebuild the mesh — don't assume they survived.
