# Hoverfly — Marlin Firmware Review

Prioritized configuration recommendations for the Creality Ender 3 Pro with SKR Mini E3 V2.0,
Sprite Extruder Pro (direct drive), CRTouch, and TMC2209 drivers.

> **Review only** — no firmware files were modified. Each item gives the current value, the
> recommendation, and how to apply it (`#define` edit and/or live `M`-code). Confirm motion/temp
> numbers against the [Calibration Guide](../../Calibration_Guide/GUIDE.md) before committing.

## Priority table

| # | Area | Current | Recommended | Priority |
|---|------|---------|-------------|----------|
| 1 | Dual-Z vs README | `Z2_DRIVER_TYPE` commented (single driver) | Confirm motors series-wired to one driver; fix README wording | **HIGH** |
| 2 | Linear Advance | `LIN_ADVANCE` on, `ADVANCE_K 0.0` | Calibrate K (~0.02–0.10 for Sprite direct drive) | **HIGH** |
| 2b | S-curve × Lin. Advance | `S_CURVE_ACCELERATION` + `LIN_ADVANCE` both on | Disable `S_CURVE_ACCELERATION` (Marlin flags the pair incompatible) | **HIGH** |
| 3 | Live Z-offset | `BABYSTEP_ZPROBE_OFFSET` off | Enable so babysteps adjust & save probe Z-offset | MED |
| 4 | Bed heating | bang-bang (`PIDTEMPBED` off) | Optional: bed PID + autotune | MED |
| 5 | Probe coverage | `PROBING_MARGIN 50` | Reduce to ~20–30 mm | MED |
| 6 | Mesh density | 4×4 grid | 5×5 | LOW |
| 7 | Input Shaping | disabled | Try Marlin IS; fall back to slicer/Klipper | MED |
| 8 | Motion / JD | accel 500, JD 0.08 | Keep; tune via calibration | LOW |
| 9 | QoL items | mostly off | Optional (see §9) | LOW |

## 1. Dual-Z discrepancy (HIGH)

README lists "Dual Z-axis" but `Z2_DRIVER_TYPE` is commented out — Marlin is set for a **single** Z
driver. The **SKR Mini E3 V2.0 has only 4 onboard drivers (X, Y, Z, E0)** and no spare socket, so the
normal "dual Z" on this board is **two motors wired to the one Z driver** (Y-splitter/series cable).
In that case the single-driver firmware is **correct** — nothing to enable.

**Action:** confirm wiring. If series-wired (almost certainly the case), leave firmware as-is and
reword the README to *"Dual Z motors (series-wired to the single Z driver)."* Trade-off: with one
driver you **cannot** use `Z_STEPPER_AUTO_ALIGN` / `G34` — gantry squaring stays manual.

## 2. Linear Advance K is 0.0 (HIGH)

`LIN_ADVANCE` is compiled in but `ADVANCE_K 0.0` = no effect. It pays off on a light direct drive
like the Sprite (crisper corners/seams, less bulging). Direct-drive PLA K is typically **0.02–0.10**.
Measure it (Orca "Pressure advance" test or Marlin K pattern — see Calibration Guide §6).

```gcode
M900 K0.04    ; set K (your measured value)
M500          ; save
M900          ; report
```
Or bake in: `#define ADVANCE_K 0.04` in `Configuration_adv.h`. **Pick one** of firmware K *or*
slicer pressure advance — not both.

> **Fix this first — latent conflict (HIGH).** `S_CURVE_ACCELERATION` and `LIN_ADVANCE` are **both
> enabled**, a combination Marlin's sanity check `#error`s unless you force `EXPERIMENTAL_SCURVE`.
> S-curve's Bézier accel profile breaks Linear Advance's pressure timing → over/under-extrusion at
> accel/decel edges. **Comment out `S_CURVE_ACCELERATION`** (`//#define S_CURVE_ACCELERATION`) so LA
> times correctly; junction deviation already provides the corner smoothing. Refs: Marlin issues
> [#22547](https://github.com/MarlinFirmware/Marlin/issues/22547),
> [#14728](https://github.com/MarlinFirmware/Marlin/issues/14728).

## 3. Enable BABYSTEP_ZPROBE_OFFSET (MED)

Babystepping is on, but `BABYSTEP_ZPROBE_OFFSET` is off. Enabling it makes live Z babysteps adjust
the **probe Z-offset**, so you dial the first layer by feel and `M500` to persist — ideal with a
CRTouch.

```c
// Configuration_adv.h
#define BABYSTEP_ZPROBE_OFFSET
```

## 4. Bed PID vs bang-bang (MED)

`PIDTEMPBED` disabled → bang-bang. Fine for PLA. Enable only for tighter bed-temp stability, and
**autotune** rather than trusting fallback constants:

```c
#define PIDTEMPBED        // Configuration.h, then rebuild
```
```gcode
M303 E-1 S60 C8 U1   ; bed autotune, 60C, 8 cycles, apply
M500
```
Recommendation: keep bang-bang for now.

## 5. PROBING_MARGIN 50 mm is large (MED)

With a 210 mm bed, margin 50 means the mesh only samples the central ~110×110 mm. Lower it to mesh
more of the bed:

```c
#define PROBING_MARGIN 25   // was 50
```
After lowering, run `G29` and watch the corner points — the **probe** sits 30 mm left / 40 mm front
of the nozzle, so it limits the usable margin. Raise back if the probe deploys off the bed.

## 6. Mesh density 4×4 → 5×5 (LOW)

```c
#define GRID_MAX_POINTS_X 5   // Y inherits
```

**Probe at print temperature.** `PREHEAT_BEFORE_LEVELING` is on, but check `LEVELING_BED_TEMP` — if it's
left at a low preheat default (often ~50 °C) it's below your ~60 °C PLA bed, and aluminum warps differently
when hot, so a cold mesh misses real warp. Set `#define LEVELING_BED_TEMP 60`, or probe fresh in start
G-code after a soak (`M190 S60` → `G4 S300` → `G28` → `G29` → `M500`). Verify the probe with `M48 P10`
(target σ < 0.02 mm). See Calibration Guide §9.

## 7. Input Shaping on STM32F103 (MED)

`INPUT_SHAPING_X/Y` disabled. IS cancels ringing and enables higher accel, but the SKR Mini E3 V2.0
is an STM32F103 (72 MHz, 20 KB RAM) — the build may overflow or limit step rate.

- **Try:** enable both, set frequencies from a ringing-tower measurement, live-tune `M593 X F.. ` /
  `M593 Y F..`, then `M500`.
- **If it won't fit:** drop it; keep accel modest, or move to Klipper for first-class input shaping.

```c
#define INPUT_SHAPING_X
#define INPUT_SHAPING_Y
#define SHAPING_MIN_FREQ 20.0   // caps the SRAM step buffer so it fits on 48KB F103
```

**Making it fit (48 KB SRAM).** The IS step buffer grows with steps/mm and feedrate; `SHAPING_MIN_FREQ
20.0` bounds it. After enabling, **build and read the linker summary before flashing** — if it says
*"region RAM overflowed"*, free SRAM (drop unused LCD languages, keep `SHAPING_MENU` off) or skip IS.
**Tuning order:** measure frequency → `M593 X F.. Y F..`, then damping `M593 X D.. Y D..` (zeta ~0.15,
step 0.05). **Re-tune Linear Advance K *after* IS** (the sweep runs with LA off): mechanics → IS → LA K.

## 8. Motion limits / junction deviation (LOW)

- `DEFAULT_ACCELERATION 500` — conservative; the Sprite is light, you can likely reach 1000–2000
  after a ringing test.
- `JUNCTION_DEVIATION_MM 0.08` — good default. Lower 0.05 = crisper/slower, higher 0.10–0.13 =
  faster/rounder.
- `S_CURVE_ACCELERATION` on — **disable it** (incompatible with `LIN_ADVANCE`, see §2). Z feedrate
  5 mm/s and E max accel 5000 are fine.

Raise limits only with a test; firmware ceiling must be ≥ slicer requests.

> **Gotcha — E max feedrate caps retraction speed.** `DEFAULT_MAX_FEEDRATE` E is **25 mm/s**, so any
> slicer retraction speed above 25 is silently clamped. The "40 mm/s" retraction in the slicer/calibration
> guides never actually happens — either set slicer retraction speed to **≤ 25 mm/s**, or raise the E
> ceiling (`M203 E50` + `M500`) if you want faster retracts. A light Sprite rarely needs more than ~25.

## 9. Smaller items / QoL (LOW)

- `ALLOW_LOW_EJERK` — `DEFAULT_EJERK` is `5.0` with `LIN_ADVANCE` on. Marlin historically blocks
  E-jerk < 10 with Linear Advance unless this is defined (it's meant for light direct drives). With
  `CLASSIC_JERK` off (junction-deviation mode) it likely won't bite, but uncomment it if a build errors
  on E-jerk — don't raise the jerk instead.
- `G26_MESH_VALIDATION` — commented out; enable to print a single-layer pattern (`G26`) that confirms
  the mesh gives a flat first layer across the whole bed (companion to `M48` repeatability).
- `PROBING_HEATERS_OFF` — enable if probing is electrically noisy.
- `POWER_LOSS_RECOVERY` — off; enable only if you need it (adds SD writes).
- Sensorless homing — not worth it (physical endstops present, DIAG jumpers needed).
- `TEMP_SENSOR_0 = 1` — confirm if temps read oddly.
- `EDITABLE_STEPS_PER_UNIT` — already on (good).
- `THERMAL_PROTECTION_CHAMBER` — enabled w/o chamber heater; harmless.

## Applying & saving

| Path | Use for | Steps |
|------|---------|-------|
| Live M-code | K-factor, PID, steps/mm, mesh, Z-offset, shaper freq | send M-code → test → `M500` (persist). `M501` reload, `M502` reset |
| Recompile | feature toggles (`BABYSTEP_ZPROBE_OFFSET`, `PIDTEMPBED`, `INPUT_SHAPING_*`, `GRID_MAX_POINTS`, `PROBING_MARGIN`) | edit `Configuration*.h` → build (PlatformIO) → flash `firmware.bin` via SD → recalibrate → `M500` |

Change **one** thing at a time, reflash, verify, `M500`. Keep firmware edits on a branch.

## Sources

- Marlin docs — Linear Advance, Input Shaping, PID, Bed Leveling: <https://marlinfw.org/docs/>
- M900 / M593 G-code: <https://marlinfw.org/docs/gcode/M900.html>, <https://marlinfw.org/docs/gcode/M593.html>
- BTT SKR Mini E3 V2.0 hardware: <https://github.com/bigtreetech/BIGTREETECH-SKR-mini-E3>
- Teaching Tech calibration: <https://teachingtechyt.github.io/calibration.html>
- Ellis' Print Tuning Guide: <https://ellis3dp.com/Print-Tuning-Guide/>
- Marlin S-curve × Linear Advance incompatibility: issues [#22547](https://github.com/MarlinFirmware/Marlin/issues/22547), [#14728](https://github.com/MarlinFirmware/Marlin/issues/14728)
- Input Shaping on STM32F103 / SRAM limits: Marlin [#26183](https://github.com/MarlinFirmware/Marlin/issues/26183); `ALLOW_LOW_EJERK` PR [#23054](https://github.com/MarlinFirmware/Marlin/pull/23054)
