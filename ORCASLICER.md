# OrcaSlicer setup for Hoverfly

Reference sheet for getting the OrcaSlicer profile matched to Hoverfly, with a
PETG-focused, time-boxed plan (goal: a reliable PETG print running by later in
the day). Companion to `MIGRATION.md` §7 (slicer + print-macro to-dos) and the
calibrated values already baked into `klipper/printer.cfg`.

**Context:** OrcaSlicer is still running on a separate machine (not the delicass
container yet). The physical printer now lives on **delicass — upload/connect
target is Moonraker at `http://192.168.1.70`** (was trantor `.69` before the
migration).

---

## 1. Printer / machine settings (must match the hardware)

These caused the "Move out of range" failure when they were wrong (generic
profile). Get these exact:

| Setting | Value | Notes |
|---|---|---|
| Bed size (X × Y) | **235 × 235 mm** | ✅ already fixed. `position_max` in printer.cfg. |
| Origin | (0, 0) front-left | Standard Ender 3. |
| Max print height (Z) | **250 mm** | `stepper_z position_max`. Use 248 if you want margin. |
| Nozzle diameter | 0.4 mm | |
| Extruder type | **Direct drive** | Sprite Extruder Pro — this drives the *short* retraction below. |
| G-code flavor | **Klipper** (Marlin-compatible) | |
| Printer host (upload) | `http://192.168.1.70` (Moonraker/Mainsail on delicass) | Not the old .69. |

**Don't** put rotation_distance, PID, z-offset, or the mesh in the slicer —
those live in `klipper/printer.cfg` and are already calibrated:
- rotation_distance 7.501, extruder PID (240 °C), bed PID (80 °C), z_offset
  3.779, bed mesh `default` saved (0.25 mm range after leveling).

---

## 2. Start / end G-code (machine G-code)

**The clean approach (recommended):** create `PRINT_START` / `PRINT_END`
macros in `printer.cfg` and keep the slicer G-code thin. Those macros don't
exist yet — see `MIGRATION.md` §7. Sketch of what `PRINT_START` should do:

```gcode
[gcode_macro PRINT_START]
gcode:
    {% set BED = params.BED|default(80)|float %}
    {% set EXTRUDER = params.EXTRUDER|default(240)|float %}
    M140 S{BED}                      # start bed heating
    G28                              # home all
    M190 S{BED}                      # wait for bed
    M109 S{EXTRUDER}                 # wait for nozzle
    BED_MESH_PROFILE LOAD=default    # <-- APPLIES THE SAVED MESH (easy to forget)
    # purge line near front-left, INSIDE the 235x235 bounds:
    G1 Z2 F600
    G1 X5 Y5 F3000
    G1 Z0.3 F600
    G1 X120 Y5 E15 F1000             # prime line
    G1 Z2 F600
```

**Matching OrcaSlicer machine start G-code** (passes the slicer's temps in):

```gcode
PRINT_START EXTRUDER=[nozzle_temperature_initial_layer] BED=[bed_temperature_initial_layer_single]
```

> ⚠️ Verify those two placeholder names against OrcaSlicer's own variable list
> before relying on them — Orca uses `{...}`/`[...]` template syntax and the
> exact identifiers occasionally differ by version. Slice one object and read
> the generated G-code header to confirm the values substituted correctly.

**End G-code** — the generic profile's "present" move went to `Y 320 / Z 80`,
off this bed. Keep everything inside the envelope:

```gcode
PRINT_END
```
with `PRINT_END` doing: turn off heaters/fan, retract a little, lift Z a safe
amount (e.g. `G91 / G1 Z10 / G90` capped so Z ≤ 250), and move Y to **max 220**
(not 320) to present the part.

---

## 3. PETG filament settings (the priority for tomorrow)

Starting points tuned to what's already known about this printer. Bold = most
likely to bite you if wrong.

| Setting | Starting value | Notes |
|---|---|---|
| Nozzle temp | **240 °C** (first layer 245) | PID was tuned at 240. Range 230–250. |
| Bed temp | **80 °C** | PID tuned at 80. First layer 80, can drop to 70–75 after. |
| **Part cooling fan** | **~40 %** (0 % first 2–3 layers) | PETG is fan-sensitive: too much → weak layer bonding & warping; too little → droopy overhangs/stringing. 40 % is a safe middle. |
| Flow / extrusion multiplier | **0.95** (then calibrate) | PETG usually lands 0.92–0.98. |
| **Retraction distance** | **1.0 mm** | Direct drive — do NOT use bowden-style 4–6 mm. Range 0.6–1.5 mm. |
| Retraction speed | 35 mm/s | |
| Z-hop | 0.2 mm | Helps PETG's ooze/stringing on travels. |
| Travel speed | 150–200 mm/s | |
| Outer wall speed | 30–40 mm/s | PETG likes slow walls for surface quality. |
| Inner wall / infill | 45–60 mm/s | |
| First layer speed | 20–25 mm/s | |
| Max volumetric speed | **8 mm³/s** | PETG ≈ 7–10; keep low to avoid under-extrusion. |
| Line width | 0.42 mm (first layer 0.45) | |

---

## 4. Process / quality settings

| Setting | Value |
|---|---|
| Layer height | 0.20 mm (0.24 first layer) |
| Walls / perimeters | 3 |
| Top/bottom layers | 4–5 |
| Infill | 15–20 % (bump for the mount if it's structural) |
| Seam position | Aligned / rear |
| Supports | only if the webcam-mount geometry needs them |

---

## 5. ⚠️ PETG gotchas (don't skip these)

- **Bed adhesion is the opposite problem from PLA — PETG bonds *too* hard.**
  On bare smooth PEI or glass it can fuse and tear chunks out of the surface.
  Use a **glue stick as a *release* layer** (it stops PETG welding to the
  plate), or print on textured PEI. This protects your build surface.
- **Dial fan down, not up.** Over-cooling is the #1 cause of PETG layer
  splitting/delamination.
- **Stringing is normal-ish** with PETG; retraction + Z-hop + not-too-hot
  temps manage it. Don't chase it at the expense of layer adhesion.
- **Keep it dry.** PETG absorbs moisture; wet filament = popping, stringing,
  weak parts. Dry it if it's been open a while.
- **Pressure Advance is a Klipper-side tune, not a slicer setting** — it lives
  in `printer.cfg` (or `SET_PRESSURE_ADVANCE`). Not yet calibrated. Reduces
  corner bulge/gaps. See the calibration order below.

---

## 6. Minimum calibration path for tomorrow (time-boxed)

You've got temps already pinned down by the PID work, so skip the temp tower.
Prioritized by impact-per-minute, using OrcaSlicer's built-in **Calibration**
menu. If time is tight, #1 and #2 alone get you a solid print.

1. **Flow rate** (Calibration → Flow Rate, Pass 1 then Pass 2) — biggest win
   for dimensional accuracy and top-surface quality. ~15 min including prints.
2. **Retraction test** — quick check that 1.0 mm kills most stringing on this
   direct-drive setup. Adjust if needed.
3. **Pressure Advance** (Orca's PA test drives Klipper's `TUNING_TOWER`) —
   sharpens corners, evens extrusion. ~15 min. Do it if the flow/retraction
   went smoothly and you have time.
4. **Max volumetric speed** — only if you intend to push print speed; otherwise
   the 8 mm³/s starting cap is safe to leave.

Skip input shaper for now (no accelerometer wired — it's a separate manual
job, noted in `MIGRATION.md`).

---

## 7. Pre-flight checklist before the real PETG print

- [ ] Machine settings match §1 (bed 235×235, host 192.168.1.70).
- [ ] `PRINT_START` / `PRINT_END` macros exist and start G-code calls them.
- [ ] `BED_MESH_PROFILE LOAD=default` is in `PRINT_START` (mesh actually applied).
- [ ] Slice one object, **read the generated G-code header** — confirm temps
      substituted, and no coordinate exceeds 235 (X/Y) or 250 (Z).
- [ ] Glue-stick release layer down on the bed for PETG.
- [ ] Flow rate calibrated (§6 #1).
- [ ] First-layer watched live on the Mainsail webcam.
