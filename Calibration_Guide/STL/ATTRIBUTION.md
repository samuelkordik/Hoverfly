# Calibration STL models — sources & licenses

## Generated for this repo (CC0 / public domain — do whatever you like)

Authored procedurally by [`_generate.py`](_generate.py) (in this folder). Re-run
`python3 _generate.py` to regenerate. Simple axis-aligned solids (box unions) that slice
cleanly on any slicer.

| File | Size | Purpose |
|------|------|---------|
| `calibration_cube_20mm.stl` | 20×20×20 mm | XYZ dimensional-accuracy / steps & flow sanity check |
| `single_wall_flow_25mm.stl` | 25×25×20 mm | Single-wall flow / extrusion-multiplier test (slice: 1 perimeter, 0 top/bottom, 0% infill, or Spiral/Vase) |
| `firstlayer_patch_60mm.stl` | 60×60×0.30 mm | First-layer / Z-offset tuning patch |
| `bridge_test_40mm.stl` | 60×40×12 mm, 40 mm span | Bridging / part-cooling test |
| `temp_tower_70mm.stl` | 25×30×70 mm, 7 bands | Temperature tower — change nozzle temp per 10 mm band in the slicer (≈220 °C bottom → 190 °C top). Each band has a −Y overhang fin so temp-dependent overhang/bridging shows band to band. |
| `retraction_test_50mm.stl` | 48×8×50 mm, 32 mm gap | Two posts on a shared base; the nozzle travels across the gap each layer, so poor retraction leaves strings between them. |
| `ringing_tower_60mm.stl` | 20×15×61 mm | A column with a 5 mm nub every 10 mm; each nub forces a sharp direction change and the wall just after it echoes the machine's resonance (ghosting). For accel limits + Input Shaping. |

> The temp / retraction / ringing towers are **simplified procedural stand-ins** for the
> community "smart" towers listed at the bottom. They exercise the same physics but don't
> carry printed text labels or fancier features. Want the de-facto-standard versions?
> Download them and record their source + license in the last table.

## Downloaded community models

| File | Source | Author | License |
|------|--------|--------|---------|
| `3DBenchy.stl` | <https://github.com/CreativeTools/3DBenchy> (`Single-part/3DBenchy.stl`, official repo) · <https://www.3dbenchy.com> | CreativeTools.se | **CC BY‑ND 4.0** — redistribute unmodified with attribution; **no derivatives** (don't reshape/remix the model). |

## Optional upgrades — fancier community models (not committed)

The de-facto-standard "smart" calibration prints, if you want richer features than the
generated towers above. Download into this folder and **record the exact source URL +
author + license here before printing/redistributing**:

| Model | Where | License |
|-------|-------|---------|
| Smart temperature tower (PLA) | Printables #19094 / Thingiverse #2493504 | CC BY / CC BY-SA (check listing) |
| Retraction test tower | Thingiverse #2415908 and many mirrors | CC BY-SA |
| All-in-one calibration (CHEP) | Printables / Thingiverse | CC BY |
| Ringing / ghosting tower | Marlin docs / Printables | CC BY |
