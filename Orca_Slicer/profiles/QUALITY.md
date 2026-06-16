# ◆ Quality / high-detail process profile — Elegoo PLA

For miniatures, mechanical fits, and display parts. Trades time for surface finish and fine features.

## Quality
- Layer height: **0.12–0.16 mm** · first layer: 0.20 mm
- Line width: **0.40 mm** (= nozzle, for crisp detail)
- Walls: **3–4** · top/bottom: 5 / 4
- Infill: **15–20%** gyroid (isotropic, clean top surfaces)

## Speeds (mm/s)
- Outer wall: **30–40** (slow = smooth) · Inner wall: **60**
- Infill: **80** · Top surface: 30 · Travel: 180
- First layer: 20–25 · Small-perimeter speed: 25 (slow tiny loops)

## Acceleration
- Print: **500 mm/s²** (firmware default is fine here — low accel helps detail)

## Temperature / flow
- Nozzle: **200–205 °C** (cooler = crisper, less stringing) · Bed: 60/55 °C
- Flow ratio: dialed from flow test; accuracy matters more at fine layers

## Retraction / PA
- Retraction: **0.6–0.8 mm @ 25 mm/s** (speed capped by firmware E feedrate 25 mm/s — tune distance, not speed)
- Pressure advance / Marlin K: tuned value — most visible on fine detail and seams

## Cooling / overhangs
- Fan: 0% layer 1 → **100%** by layer 3 · Min layer time: 8–10 s
- Slow down for overhangs: **on** · Slow down for layer cooling: on

## Other
- Seam: Aligned (or Back) for hidden seams · Ironing: optional on flat tops
- Supports: tree/normal as needed; support interface gap 0.2 mm
