# Hoverfly — Orca Slicer Guide (Elegoo PLA)

Orca Slicer setup for the Ender 3 Pro · SKR Mini E3 V2.0 · Sprite Extruder Pro (direct drive) ·
CRTouch, printing **Elegoo PLA**. Human/HTML version: [`index.html`](index.html).

> Values are starting points tied to the firmware. Confirm flow / pressure advance / temperature /
> retraction in the [Calibration Guide](../Calibration_Guide/GUIDE.md), then lock them into the presets.

## 1. Add the printer (custom Marlin)

| Setting | Value | Why |
|---|---|---|
| Bed shape | 210 × 210 mm | Match firmware travel (`X/Y_BED_SIZE 210`). Plate is physically 220; firmware caps at 210. |
| Max height | 250 mm | `Z_MAX_POS 250` |
| Nozzle | 0.4 mm | standard |
| Flavor | Marlin | — |
| Extruder | Direct drive | Sprite Pro → short retraction, low PA |

## 2. Machine limits (mirror firmware)

| Limit | Value | Source |
|---|---|---|
| Max speed X/Y | 500/500 mm/s | `DEFAULT_MAX_FEEDRATE` |
| Max speed Z/E | 5/25 mm/s | `DEFAULT_MAX_FEEDRATE` |
| Max accel X/Y | 500/500 mm/s² | `DEFAULT_MAX_ACCELERATION` (raise via Cal §7) |
| Max accel E | 5000 mm/s² | `DEFAULT_MAX_ACCELERATION` |
| Jerk X/Y | leave default (no effect) | Classic jerk is OFF; firmware uses Junction Deviation 0.08, so Marlin **ignores** any `M205` X/Y jerk Orca emits. Only matters if you re-enable `CLASSIC_JERK`. (Marlin has no `M566`.) |

**Speed bottleneck:** firmware accel is 500 mm/s². Print accel is clamped by **both** the firmware
ceiling **and** Orca's machine max-accel limit (also 500). Raise them in order: (1) firmware via Cal §7
(`SET_ACCEL.gcode`/LCD + save), then (2) Orca → machine limits → max accel X/Y to match. Raising only
one leaves you clamped.

## 3. Elegoo PLA filament

| Setting | Value | Notes |
|---|---|---|
| Nozzle | 200–215 °C (first +5) | Envelope for Elegoo PLA. Quality runs cooler (~200–205), Speed hotter (~210–215); pick the final value with the temp tower (Cal §5). |
| Bed | 60 first / 55–60 rest | bang-bang, fine for PLA |
| Flow ratio | ~0.98 | set from flow test (Cal §3) |
| Pressure advance | OFF (untick **Enable pressure advance**) if using Marlin K | Orca's PA checkbox **injects `M900 K` into start G-code and overrides firmware K every print** — so to rely on firmware K you must untick it. If instead you tune PA in Orca, that's fine (Orca's `M900` wins); keeping firmware `ADVANCE_K 0` avoids confusion. |
| Max volumetric speed | ~11 mm³/s (starting default) | Verify with Orca → Calibration → **Max volumetric speed** test (this guide §6). Not a per-hotend measured value yet. |
| Cooling | 0% layer 1 → 100% by layer 3 | PLA loves cooling |

## 4. Speed vs Quality

| Setting | ⚡ Speed | ◆ Quality |
|---|---|---|
| Layer height | 0.28 | 0.12–0.16 |
| First layer | 0.28 (or 0.24 if adhesion is marginal) | 0.20 |
| Line width | 0.45–0.50 | 0.40 |
| Walls | 2 | 3–4 |
| Top/bottom | 3/3 | 5/4 |
| Infill | 10–15% grid | 15–20% gyroid |
| Outer wall speed | 120–150 | 30–40 |
| Inner wall speed | 200–250 | 60 |
| Infill speed | 250–300 | 80 |
| Travel | 250 | 180 |
| Print accel | 1500–2000 (needs firmware) | 500 |
| Nozzle temp | 210–215 | 200–205 |
| Retraction | 0.8 mm @ 25 mm/s* | 0.6–0.8 mm @ 25 mm/s* |
| Overhang slowdown | off | on |
| Use for | drafts, jigs, big parts | minis, fits, display |

> \* **Retraction speed is capped at 25 mm/s** by the firmware E max feedrate (`DEFAULT_MAX_FEEDRATE`
> E = 25). Higher slicer values are silently clamped — tune retraction *distance*, not speed, or raise
> the E ceiling (`M203 E50` + `M500`) first.

Full per-profile notes: [`profiles/SPEED.md`](profiles/SPEED.md),
[`profiles/QUALITY.md`](profiles/QUALITY.md), [`profiles/printer-settings.md`](profiles/printer-settings.md).

## 5. Start / end G-code

See `index.html` §5. **Prerequisite (do this first):** `M420 S1 Z10` loads a **stored** mesh — but
with no stored mesh it silently prints with **zero compensation** (Marlin's "No mesh" warning only goes
to serial, which you can't see), risking a bad or crashing first layer. Run `macros/BUILD_MESH.gcode`
(Cal §9 — does `G29`+`M500`+enable) **once before ever using this start block**, or keep `G29` in the
start G-code until a mesh exists.

## 6. Orca calibration order

Temperature tower → Flow rate → Pressure advance (or Marlin K) → Retraction test → **Max volumetric
speed** (run Orca's Max Volumetric Speed test — there is no separate Calibration-guide MVS step; the
~11 mm³/s default in §3 is a starting point, verify it here). Each maps to a step in the
[Calibration Guide](../Calibration_Guide/GUIDE.md).

## Sources

- Orca Slicer calibration docs: <https://github.com/SoftFever/OrcaSlicer/wiki/Calibration>
- Ellis' Print Tuning Guide: <https://ellis3dp.com/Print-Tuning-Guide/>
- Elegoo PLA spec sheet (temp ranges): Elegoo product/filament documentation
