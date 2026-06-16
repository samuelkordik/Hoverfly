# Hoverfly — Marlin Firmware Review

Prioritized configuration recommendations for the Creality Ender 3 Pro with SKR Mini E3 V2.0,
Sprite Extruder Pro (direct drive), CRTouch, and TMC2209 drivers.

> **Review only** — no firmware files were modified. Each item gives the current value, the
> recommendation, and how to apply it (`#define` edit and/or live `M`-code). Confirm motion/temp
> numbers against the [Calibration Guide](../../Calibration_Guide/GUIDE.md) before committing.

## Priority table

| # | Area | Current | Recommended | Priority |
|---|------|---------|-------------|----------|
| 1 | Dual-Z wiring | Two motors **parallel** on one Z driver (Creality cable); firmware single-Z (correct) | Works as-is; raise Z current if torque short; series = optional cable swap | LOW |
| 2 | Linear Advance | `LIN_ADVANCE` on, `ADVANCE_K 0.0` | Calibrate K (~0.02–0.10 for Sprite direct drive) | **HIGH** |
| 2b | S-curve × Lin. Advance | `S_CURVE_ACCELERATION` + `LIN_ADVANCE` both on (OK on Marlin 2.1.2.7) | Optional: try with S-curve off; not required — the pair is supported | LOW |
| 3 | Live Z-offset | `BABYSTEP_ZPROBE_OFFSET` off | Enable so babysteps adjust & save probe Z-offset | MED |
| 4 | Bed heating | bang-bang (`PIDTEMPBED` off) | Optional: bed PID + autotune | MED |
| 5 | Probe coverage | `PROBING_MARGIN 50` | Reduce to ~20–30 mm | MED |
| 6 | Mesh density | 4×4 grid | 5×5 | LOW |
| 7 | Input Shaping | disabled | Try Marlin IS; fall back to slicer/Klipper | MED |
| 8 | Motion / JD | accel 500, JD 0.08 | Keep; tune via calibration | LOW |
| 9 | QoL items | mostly off | Optional (see §9) | LOW |

## 1. Dual-Z wiring — parallel, one driver (LOW)

The "Dual Z-axis" mod is two Z steppers + lead screws driven from the **single** Z output via the
Creality kit's **parallel Y-splitter cable**. Firmware is correctly single-Z (`Z2_DRIVER_TYPE`
commented): the **SKR Mini E3 V2.0 has only 4 drivers (X, Y, Z, E0)** and no spare socket, so a second
*independent* Z driver isn't possible here. This works — the rest is optional.

- **Parallel current (watch this):** both motors share the one TMC2209, so they split its current. Stock
  Z current is **580 mA** (`Z_CURRENT`, `Configuration_adv.h`). If Z lacks torque or skips, raise it
  either by editing `Z_CURRENT` (reflash) or — since the TMC2209 is in UART mode — live via the new
  `SET_ZCURRENT.gcode` macro (`M906 Z<mA>` + `M500`, no reflash). The driver's *set* current is the
  **total** it sources for both motors; it divides ~50/50 on average but shifts with each motor's
  load/back-EMF, so budget against the **driver's ~1.4 A RMS ceiling** (total), not a per-motor figure.
  Keep the set value ≤ ~1000 mA and check the driver isn't hot. Z is slow, so this is rarely a problem.
- **Series is cleaner but a hardware swap:** series gives both motors full, synced current within the
  driver rating (Z's low speed makes the inductance penalty moot) — but the stock Creality cable is the
  **parallel** one, so series needs a *different* splitter cable. Optional, not urgent.
- **No auto gantry-align:** with one driver you **cannot** use `Z_STEPPER_AUTO_ALIGN` / `G34` — square
  the gantry manually (stays true even under future Klipper). Reword the README mod list to
  *"two Z motors, parallel-wired to the single driver."*

## Fan wiring & cooling — dual 5015 blowers

Three fans, two controllable 24 V PWM headers (FAN0/FAN1). The current wiring is already correct:

| Fan | Connect to | Firmware | Behaviour |
|-----|-----------|----------|-----------|
| Hotend / heatbreak | **FAN1** | `E0_AUTO_FAN_PIN FAN1_PIN` | Auto-on when hot (`EXTRUDER_AUTO_FAN_TEMPERATURE 50`, speed 255) |
| Parts cooling — **dual 5015 blowers** | **FAN0** → Sprite PCB part-fan connector | default `M106` PWM | Slicer-controlled; two 5015s ≈ 0.2 A, within FAN0 |
| Mainboard / controller | **PWR** (always-on) | `USE_CONTROLLER_FAN` off | Hard-wired to power; correct as-is (not on a header) |

**One firmware add for the blowers** — they often won't start at low PWM:

```c
// Configuration_adv.h
#define FAN_KICKSTART_TIME 150   // (ms) full-speed pulse on start
#define FAN_MIN_PWM 75           // PWM floor out of 255 (~29%), not a percent — so they don't stall
```

**`FAN_MIN_PWM` only rescales non-zero speeds.** A commanded **0 is always fully off** (Marlin's own
comment: *"Value 0 always turns off the fan."*), so your layer-1 0% fan still means no airflow — PLA bed
adhesion is unaffected. The ~29% floor applies only when the slicer asks for a low but non-zero speed.

**PLA duct caveat:** the Taurus V5 duct is printed in PLA (softens ~60 °C) right by the hotend — watch for
sag on long/hot prints, reprint in PETG/ABS/ASA if it deforms. Keep the layer-1 fan low for adhesion; the
Orca profiles already ramp 0%→100% by layer 3.

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

> **S-curve + Linear Advance is fine on this Marlin (not a conflict).** Both `S_CURVE_ACCELERATION`
> (`Configuration.h`) and `LIN_ADVANCE` are enabled, and on **Marlin 2.1.2.7 that is supported** — the
> old sanity-check `#error` that rejected the pair was removed. Current Marlin guards the LA/S-curve
> math with `#if ANY(S_CURVE_ACCELERATION, LIN_ADVANCE)` (`planner.cpp`, `planner.h`) and compiles both
> together. No `EXPERIMENTAL_SCURVE` is needed — in fact defining it now *breaks* the build
> (`inc/Changes.h`: "EXPERIMENTAL_SCURVE is no longer needed and should be removed"), and it is not set
> here. **Your build is not secretly broken.** *Optional preference:* some find Linear Advance pressure
> timing crispest with S-curve off, since junction deviation already smooths corners, so you *may*
> `//#define S_CURVE_ACCELERATION` — but it is not required. Refs (historical, now resolved): Marlin
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
Marlin auto-clamps the probe grid so the pin always stays on the bed — no trial-and-error off a hot bed
needed. With offset `{-30,-40}` and `PROBING_MARGIN 25`, `probe.h`'s `_min/_max` bounds work out to
sampled region **X ∈ [25, 180], Y ∈ [25, 170]** (e.g. `max_x = MIN(210−25, 210−30) = 180`,
`max_y = MIN(210−25, 210−40) = 170`). The far edges are pulled in by the **offset**, not the margin; the
margin only governs how close to the front/left near edges the pin lands. The probe never deploys off the
bed at 25 (it stays on even down to ~10), so 25 is a conservative, verified-safe choice.

## 6. Mesh density 4×4 → 5×5 (LOW)

```c
#define GRID_MAX_POINTS_X 5   // Y inherits
```

**Probe at print temperature.** `PREHEAT_BEFORE_LEVELING` is on, but `LEVELING_BED_TEMP` is currently
**`50`** (`Configuration.h`) — below your ~60 °C PLA bed, so the mesh is probed ~10 °C cold, and aluminum
warps differently when hot, so a cold mesh misses real warp. Set `#define LEVELING_BED_TEMP 60` (reflash),
or probe fresh in start G-code after a soak (`M190 S60` → `G4 S300` → `G28` → `G29` → `M500`). An `M48 P10` probe-repeatability
check (target σ < 0.02 mm) is worthwhile too, but it only reports over serial — it waits for the Klipper
console. See Calibration Guide §9.

## 7. Input Shaping on STM32F103 (MED)

`INPUT_SHAPING_X/Y` disabled. IS cancels ringing and enables higher accel, but the SKR Mini E3 V2.0
is an STM32F103RC (72 MHz, **48 KB** SRAM) — the build may still overflow because Marlin IS is
RAM-hungry, or limit step rate.

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
- `S_CURVE_ACCELERATION` on — fine alongside `LIN_ADVANCE` on this Marlin (2.1.2.7); disabling it is an
  optional preference, not a fix (see §2). Z feedrate 5 mm/s and E max accel 5000 are fine.

Raise limits only with a test; firmware ceiling must be ≥ slicer requests.

> **Gotcha — E max feedrate caps retraction speed.** `DEFAULT_MAX_FEEDRATE` E is **25 mm/s**, so any
> slicer retraction speed above 25 is silently clamped. The "40 mm/s" retraction in the slicer/calibration
> guides never actually happens — either set slicer retraction speed to **≤ 25 mm/s**, or raise the E
> ceiling (`M203 E50` + `M500`) if you want faster retracts. A light Sprite rarely needs more than ~25.

## 9. Smaller items / QoL (LOW)

- `ALLOW_LOW_EJERK` — `DEFAULT_EJERK` is `5.0` with `LIN_ADVANCE` on. With `CLASSIC_JERK` off you're on
  junction deviation, so Marlin's `DEFAULT_EJERK >= 10` check is **compiled out entirely** (`SanityCheck.h`
  guards it with `NONE(HAS_JUNCTION_DEVIATION, ALLOW_LOW_EJERK)`). So `DEFAULT_EJERK 5.0` is harmless and
  `ALLOW_LOW_EJERK` is **not needed** here — it would only matter if you switched back to classic jerk.
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
| Value change (no terminal) | K-factor, PID, steps/mm, mesh, Z-offset, accel, shaper freq | No G-code console — use an LCD-menu action, an Orca calibration test, or an SD macro (`../../Calibration_Guide/macros/`); each saves with `M500`. `M48`/`M503`/`M420 V` are serial-only (skip; defer to Klipper) |
| Recompile | feature toggles (`BABYSTEP_ZPROBE_OFFSET`, `PIDTEMPBED`, `INPUT_SHAPING_*`, `GRID_MAX_POINTS`, `PROBING_MARGIN`) | edit `Configuration*.h` → build (PlatformIO) → flash `firmware.bin` via SD → recalibrate → `M500` |

Change **one** thing at a time, reflash, verify, `M500`. Keep firmware edits on a branch.

## Future: Klipper migration (planned)

Longer-term: host **Klipper on a wiped x86 ThinkPad** (a laptop host is fully supported — no Pi needed)
and reflash the SKR Mini E3 V2.0 as the Klipper MCU (a reference board). **Marlin-now is the priority**;
this is a separate project. Two big wins here:

- **Solves the no-terminal problem** — Mainsail/Fluidd give a web G-code console, so the serial-only
  blockers (`M48`, `M503`, mesh dumps) and PID/shaper tuning all become live.
- **Input Shaping is native** and not RAM-constrained like Marlin IS on the F103 (§7).

Carry-over vs. redo:

| Setting | Marlin | Klipper | Carry over? |
|---------|--------|---------|-------------|
| Steps/mm | `M92` | `rotation_distance` | Recompute |
| Pressure advance | `M900 K` | `pressure_advance` | Re-tune |
| Hotend/bed PID | `M303` | `PID_CALIBRATE` | Re-tune |
| Bed mesh | `G29` | `BED_MESH_CALIBRATE` | Re-run |
| Input shaping | limited on F103 | native | Tune fresh (better) |
| Dual Z | one driver | one driver (no spare) | Still parallel/series on one driver (§1) |

## Sources

- Marlin docs — Linear Advance, Input Shaping, PID, Bed Leveling: <https://marlinfw.org/docs/>
- M900 / M593 G-code: <https://marlinfw.org/docs/gcode/M900.html>, <https://marlinfw.org/docs/gcode/M593.html>
- BTT SKR Mini E3 V2.0 hardware: <https://github.com/bigtreetech/BIGTREETECH-SKR-mini-E3>
- Teaching Tech calibration: <https://teachingtechyt.github.io/calibration.html>
- Ellis' Print Tuning Guide: <https://ellis3dp.com/Print-Tuning-Guide/>
- Marlin S-curve × Linear Advance — historical (now-resolved) incompatibility: issues [#22547](https://github.com/MarlinFirmware/Marlin/issues/22547), [#14728](https://github.com/MarlinFirmware/Marlin/issues/14728)
- Input Shaping on STM32F103 / SRAM limits: Marlin [#26183](https://github.com/MarlinFirmware/Marlin/issues/26183); `ALLOW_LOW_EJERK` PR [#23054](https://github.com/MarlinFirmware/Marlin/pull/23054)
