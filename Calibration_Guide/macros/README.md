# SD-card macro files (no-terminal calibration)

Hoverfly has **no G-code terminal** (no Raspberry Pi / OctoPrint / USB console), so the calibration
steps that need a one-off command are packaged here as small `.gcode` files you **print from the SD
card**. Marlin runs them like any print.

## How to use

1. **Copy these `.gcode` files to the root of your printer's SD card** (once).
2. When a step in [`../GUIDE.md`](../GUIDE.md) / [`../index.html`](../index.html) says
   *"Run `NAME.gcode` from SD"*, on the printer select **Print → `NAME.gcode`**.
3. Files whose name starts with `SET_` **must be edited first** — open them in a text editor, change the
   value on the marked line (`<-- EDIT`), save, recopy to SD.

## What each file does

| File | Purpose | Edit first? | Verify on LCD |
|------|---------|:-----------:|---------------|
| `PID_HOTEND.gcode` | Hotend PID autotune @205 °C, saves result | no | no numeric readout — confirm by a stable temp hold |
| `PID_BED.gcode` | Bed PID autotune (only if you compiled `PIDTEMPBED`) | no | no numeric readout — confirm by a stable bed temp hold |
| `ESTEPS_TEST.gcode` | Extrude exactly 100 mm to verify E-steps | no | — (measure the filament) |
| `SET_ESTEPS.gcode` | Set & save extruder steps/mm | **yes** | Configuration → Advanced Settings → Steps/mm → E steps/mm |
| `SET_PA.gcode` | Set & save Linear Advance K | **yes** | no stock LCD readout for K — verify by print result |
| `SET_ACCEL.gcode` | Set & save acceleration limits | **yes** | Configuration → Advanced Settings → Acceleration |
| `SET_SHAPER.gcode` | Set & save Input Shaping freqs (only if IS compiled) | **yes** | only if `SHAPING_MENU` compiled (it's off) — else verify by ringing-tower result |
| `SET_ZOFFSET.gcode` | Set & save probe Z-offset | **yes** | Configuration → Probe Z Offset |
| `SET_ZCURRENT.gcode` | Set & save Z TMC2209 run current (mA) | **yes** | no stock LCD readout — confirm by Z torque / no skips |
| `BUILD_MESH.gcode` | Heat, home, probe mesh, save, enable | no | Configuration → (Bed) Leveling → Mesh viewer |

## Good to know

- **`M303` (PID) pauses at the end** and waits for you to acknowledge on the LCD — that's normal.
- **`M500` (save to EEPROM)** is built into each macro that changes a stored value. You can also save
  any time from the LCD: **Configuration → Store Settings**.
- **`M500` here writes flash-emulated EEPROM** (the SKR Mini E3 V2.0 has no real EEPROM — it uses a
  reserved flash sector). Reliable day-to-day, but **a reflash can change the EEPROM layout and reset
  stored values to defaults** — re-verify (and re-save) PID, E-steps, Z-offset, K, accel, and rebuild
  the mesh after any firmware update.
- **Many things don't need a macro at all:**
  - **LCD menu** handles steps/mm, acceleration/feedrate/jerk, babystep Z + store, and the mesh viewer.
  - **Orca Slicer's Calibration menu** generates the temperature / flow / pressure-advance / retraction /
    max-volumetric-speed tests as ordinary prints — no codes needed.
- **Serial-only commands can't show output here.** `M48` (probe repeatability), `M503` (settings dump),
  and `M420 V` (mesh print-out) only report over USB serial, which you don't have. Use the **LCD mesh
  viewer** instead of `M420 V`, and **defer `M48`** until the planned Klipper move (its Mainsail/Fluidd
  web console gives you a full terminal). See the firmware review's *Future: Klipper* section.
