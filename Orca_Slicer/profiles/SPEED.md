# ⚡ Speed / fast process profile — Elegoo PLA

For drafts, jigs, and big simple parts. Trades surface finish and fine detail for throughput.

> **Prerequisite:** raise firmware acceleration (Calibration §7) to ~1500–2000 mm/s² and match Orca's
> max accel — otherwise the printer can't reach these speeds and the profile is pointless.

## Quality
- Layer height: **0.28 mm** · first layer: 0.28 mm
- Line width: 0.45–0.50 mm (≥ nozzle for fatter, faster lines)
- Walls: **2** · top/bottom: 3 / 3
- Infill: **10–15%** grid (fast pattern)

## Speeds (mm/s)
- Outer wall: **120–150** (keep below inner — it's the visible surface)
- Inner wall: **200–250**
- Infill: **250–300**
- Top surface: 120 · Travel: **250**
- First layer: 25–30 (don't rush adhesion)

## Acceleration
- Print/travel: **1500–2000 mm/s²** (firmware ceiling must allow it)

## Temperature / flow
- Nozzle: **210–215 °C** (hotter to keep up with flow) · Bed: 60/55 °C
- Max volumetric speed: ~11 mm³/s (the real cap — Orca will slow moves to respect it)

## Retraction / PA
- Retraction: **0.8 mm @ 25 mm/s** (speed capped by firmware E feedrate 25 mm/s — tune distance, not speed)
- Pressure advance / Marlin K: keep tuned value; speed prints benefit most from correct PA

## Other
- Slow down for overhangs: **off** · Slow down for layer cooling: on (min layer time ~5 s)
- Seam: Nearest/Aligned · Supports: only if needed
