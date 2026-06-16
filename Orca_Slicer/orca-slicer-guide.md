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
| Jerk X/Y | ~8 (advisory) | classic jerk OFF; firmware uses Junction Deviation 0.08 |

**Speed bottleneck:** firmware accel is 500 mm/s². Fast speeds are wasted until you raise it
(Calibration §7) to ~1500–2000, then match Orca's max accel.

## 3. Elegoo PLA filament

| Setting | Value | Notes |
|---|---|---|
| Nozzle | 200–210 °C (first +5) | confirm via temp tower (Cal §5) |
| Bed | 60 first / 55–60 rest | bang-bang, fine for PLA |
| Flow ratio | ~0.98 | set from flow test (Cal §3) |
| Pressure advance | OFF if using Marlin K | pick one: Orca PA *or* firmware `M900 K` |
| Max volumetric speed | ~11 mm³/s | PLA throughput cap |
| Cooling | 0% layer 1 → 100% by layer 3 | PLA loves cooling |

## 4. Speed vs Quality

| Setting | ⚡ Speed | ◆ Quality |
|---|---|---|
| Layer height | 0.28 | 0.12–0.16 |
| First layer | 0.28 | 0.20 |
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

See `index.html` §5. Key point: start G-code uses `M420 S1 Z10` to load a **stored** mesh (run `G29`
+ `M500` once, Cal §9) instead of re-probing every print. Add `G29` back if you prefer probing each time.

## 6. Orca calibration order

Temperature tower → Flow rate → Pressure advance (or Marlin K) → Retraction test → Max volumetric
speed. Each maps to a step in the [Calibration Guide](../Calibration_Guide/GUIDE.md).

## Sources

- Orca Slicer calibration docs: <https://github.com/SoftFever/OrcaSlicer/wiki/Calibration>
- Ellis' Print Tuning Guide: <https://ellis3dp.com/Print-Tuning-Guide/>
- Elegoo PLA spec sheet (temp ranges): Elegoo product/filament documentation
