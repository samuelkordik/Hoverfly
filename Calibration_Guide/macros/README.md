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

| File | Purpose | Edit first? |
|------|---------|:-----------:|
| `PID_HOTEND.gcode` | Hotend PID autotune @205 °C, saves result | no |
| `PID_BED.gcode` | Bed PID autotune (only if you compiled `PIDTEMPBED`) | no |
| `ESTEPS_TEST.gcode` | Extrude exactly 100 mm to verify E-steps | no |
| `SET_ESTEPS.gcode` | Set & save extruder steps/mm | **yes** |
| `SET_PA.gcode` | Set & save Linear Advance K | **yes** |
| `SET_ACCEL.gcode` | Set & save acceleration limits | **yes** |
| `SET_SHAPER.gcode` | Set & save Input Shaping freqs (only if IS compiled) | **yes** |
| `SET_ZOFFSET.gcode` | Set & save probe Z-offset | **yes** |
| `BUILD_MESH.gcode` | Heat, home, probe mesh, save, enable | no |

## Good to know

- **`M303` (PID) pauses at the end** and waits for you to acknowledge on the LCD — that's normal.
- **`M500` (save to EEPROM)** is built into each macro that changes a stored value. You can also save
  any time from the LCD: **Configuration → Store Settings**.
- **Many things don't need a macro at all:**
  - **LCD menu** handles steps/mm, acceleration/feedrate/jerk, babystep Z + store, and the mesh viewer.
  - **Orca Slicer's Calibration menu** generates the temperature / flow / pressure-advance / retraction /
    max-volumetric-speed tests as ordinary prints — no codes needed.
- **Serial-only commands can't show output here.** `M48` (probe repeatability), `M503` (settings dump),
  and `M420 V` (mesh print-out) only report over USB serial, which you don't have. Use the **LCD mesh
  viewer** instead of `M420 V`, and **defer `M48`** until the planned Klipper move (its Mainsail/Fluidd
  web console gives you a full terminal). See the firmware review's *Future: Klipper* section.
