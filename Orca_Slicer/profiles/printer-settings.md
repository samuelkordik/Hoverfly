# Orca printer settings — Hoverfly (enter once)

Custom **Marlin** printer. These mirror the firmware so Orca never commands more than the board allows.

## Machine
- Bed shape: **210 × 210 mm** (rectangular). Firmware caps travel at 210 (`X/Y_BED_SIZE`). The plate
  is physically 220×220 — bump firmware *and* this together if you want the extra ring.
- Max print height: **250 mm**.
- Nozzle diameter: **0.4 mm**. Origin front-left (0,0). G-code flavor: Marlin. Extruder: **direct drive**.

## Motion ability (match firmware)
- Max speed: X 500, Y 500, Z 5, E 25 (mm/s)
- Max acceleration: X 500, Y 500, Z 100, E 5000 (mm/s²) — *raise X/Y to 1500–2000 after Calibration §7*
- Max jerk: X 8, Y 8, Z 0.4, E 5 (advisory only — firmware uses Junction Deviation 0.08, classic jerk off)

## Retraction (direct drive — Sprite Pro)
- Length: **0.8 mm** (range 0.6–1.0). Speed: **25 mm/s**. Z-hop: 0.2 mm (optional).
- **Speed ceiling:** the firmware E max feedrate is 25 mm/s, so any higher retraction speed is silently
  clamped. Set 25 here (or raise `DEFAULT_MAX_FEEDRATE` E / `M203 E50` if you want faster). Tune *distance*.
- Do **not** use Bowden-sized retraction (>2 mm) — it will grind/heat-creep on a direct drive.

## Start G-code (loads stored mesh, no re-probe)
```gcode
M104 S[nozzle_temperature_initial_layer]
M140 S[bed_temperature_initial_layer]
G28
M420 S1 Z10
M190 S[bed_temperature_initial_layer]
M109 S[nozzle_temperature_initial_layer]
G92 E0
G1 Z2.0 F3000
G1 X2 Y20 Z0.3 F5000
G1 X2 Y200 E15 F1500
G92 E0
```

## End G-code
```gcode
M104 S0
M140 S0
G91
G1 E-2 F2700
G1 Z10 F600
G90
G1 X5 Y200 F3000
M84
```
