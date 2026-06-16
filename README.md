# Hoverfly
"Hoverfly" was the nickname given by the RAF to the Sikorsky R-4, the first military helicopter to enter service for Allied forces (during WWII). So it's the name I'm giving to my first 3D printer.

The printer is a Creality Ender 3 Pro with the following modifications/additions:

- SKR Mini E3 V2.0 mainboard
- Dual Z-axis — two steppers + lead screws, parallel-wired to the single Z driver
- Sprite Extruder Pro direct-drive extruder + hotend
- Dual 24 V 5015 blower parts cooling on a printed Taurus V5 duct
- CRTouch probe
- Marlin firmware

This repository is for me to keep track of configuration and firmware files.

## Documentation

- **[Firmware review](docs/firmware-review/index.html)** ([markdown](docs/firmware-review/firmware-review.md)) — prioritized Marlin config recommendations.
- **[Orca Slicer guide](Orca_Slicer/index.html)** ([markdown](Orca_Slicer/orca-slicer-guide.md)) — Elegoo PLA, with Speed and Quality profiles.
- **[Calibration & tuning guide](Calibration_Guide/index.html)** — 9-step ordered tune-up with [STL test models](Calibration_Guide/STL/) and ready-to-run [SD macro files](Calibration_Guide/macros/) (no G-code terminal needed — everything runs via the LCD, Orca's calibration tests, or printing a macro from SD); also a structured [GUIDE.md](Calibration_Guide/GUIDE.md) and a [CLAUDE.md](Calibration_Guide/CLAUDE.md) for working through calibration interactively with Claude.

### How these were built

These guides were produced by a multi-agent research workflow: parallel agents did real web research
(Marlin docs, Ellis' Print Tuning Guide, Teaching Tech, RepRap wiki, and vendor/community sources)
grounded in Hoverfly's actual firmware values, then wrote the guides, the 9-step procedure, and the
calibration test STLs. The raw structured findings behind every recommendation — including seven that
were recovered from the agent transcripts after the run was interrupted partway — are preserved in
[`docs/research/`](docs/research/README.md). The firmware review changes no firmware files; it's advisory,
and motion/temperature numbers should be confirmed against the calibration guide before you commit them.

## Hardware mods (current + planned)

**Current**

- **Dual Z** — two Z steppers + lead screws on the Creality kit's **parallel** Y-splitter, off the single
  Z driver (the board has no spare). Firmware is correctly single-Z. Works as-is; if Z ever lacks torque,
  raise the Z driver current, or switch to a series splitter cable.
  See [firmware review §1](docs/firmware-review/index.html#dualz).
- **Parts cooling** — the stock fan died; replaced with **dual 24 V 5015 blowers** on a printed
  **Taurus V5 duct (PLA)**, spliced to the Sprite Extruder Pro's part-fan connector (driven by the
  mainboard's FAN0). Firmware: add `FAN_KICKSTART_TIME` / `FAN_MIN_PWM` so they start at low PWM.
  See [firmware review: fan wiring](docs/firmware-review/index.html#fans). (The PLA duct sits near the
  hotend — reprint in PETG/ABS if it sags.)

**Planned**

- **12 V buck converter** off the PSU → barrel-jack receiver, to run a 12 V fan that circulates the
  **heated bed's warmth for drying filament**.
- **5 V buck converter** off the PSU → USB-A port, for a **removable** USB LED light bar (kept unwired so
  it can come off for other uses).
- **Klipper migration** — host on a wiped x86 ThinkPad, reflash the SKR Mini E3 V2.0; gains a web G-code
  console (which removes the current no-terminal limitation) and first-class input shaping. Marlin-now is
  the priority. See [firmware review: Future — Klipper](docs/firmware-review/index.html#klipper).

> The buck converters are PSU-side (no firmware impact). Size them to the PSU's spare wattage, fuse each
> output, and use appropriate wire gauge.

## Marlin Configuration Adjustments
Using the "Creality/Ender-3 Pro/BigTreeTech SKR Mini E3 2.0" config example, with the following key changes:

```c
#define DEFAULT_KP 21.73
#define DEFAULT_KI 1.54
#define DEFAULT_KD 76.55

#define DEFAULT_AXIS_STEPS_PER_UNIT { 80, 80, 400, 423 } // E calibrated for the Sprite Extruder Pro
#define EDITABLE_STEPS_PER_UNIT                           // Allow tuning steps/mm from the LCD / via M92

//#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN      // Probe is connected to Z-probe slot on board, not Z endstop.
#define USE_PROBE_FOR_Z_HOMING                    // Force use of probe for Z-axis homing
#define BLTOUCH
#define NOZZLE_TO_PROBE_OFFSET {-30, -40, -3.49 } // Experimentally verified.
#define PROBING_MARGIN 50                         // Wanting to stay inside bed cleanly
#define XY_PROBE_FEEDRATE (50*60)                 // Not sure why
#define MULTIPLE_PROBING 2                        // Doing two readings (average of fast + slow) seems like a good idea.
#define Z_PROBE_OFFSET_RANGE_MIN -10
#define Z_PROBE_OFFSET_RANGE_MAX 10
#define X_BED_SIZE 210                            // To ensure probe is able to stay in bed; might adjust in future
#define Y_BED_SIZE 210


#define AUTO_BED_LEVELING_BILINEAR
//#define MESH_BED_LEVELING
#define RESTORE_LEVELING_AFTER_G28
#define PREHEAT_BEFORE_LEVELING                    // Of course, we want this—shouldn't this be the default?

#define Z_SAFE_HOMING
  #define Z_SAFE_HOMING_X_POINT ((X_BED_SIZE - 10) / 2)  // (mm) X point for Z homing
  #define Z_SAFE_HOMING_Y_POINT ((Y_BED_SIZE - 10) / 2) // (mm) Y point for Z homing

#define HOMING_FEEDRATE_MM_M { (50*60), (50*60), (4*60) }
```

And in Configuration_adv.h:

```c
//#define USE_CONTROLLER_FAN                      // Because the controller (mainboard) fan is wired to PWR instead of fan1

#define E0_AUTO_FAN_PIN FAN1_PIN                  // Hot-end fan is wired to FAN1 connector on board
```

## Changes Since Last Documented

These adjustments were made to the Marlin configuration *after* the table above
was first written and were not reflected in it. They are highlighted here so the
delta is easy to track.

### `Configuration.h`

- **Extruder steps/mm: `93` → `423`.** `DEFAULT_AXIS_STEPS_PER_UNIT` was bumped
  from the stock Ender-3 value to calibrate the **E axis** for the Sprite
  Extruder Pro direct drive. The X/Y/Z values (`80, 80, 400`) are unchanged.

  ```c
  -#define DEFAULT_AXIS_STEPS_PER_UNIT   { 80, 80, 400, 93 }
  +#define DEFAULT_AXIS_STEPS_PER_UNIT   { 80, 80, 400, 423 }
  ```

- **Added `EDITABLE_STEPS_PER_UNIT`.** Enables tuning steps/mm at runtime from
  the LCD or via `M92` (and storing it to EEPROM), which makes dialing in the
  new extruder calibration easier.

- **`NUM_M106_FANS` example changed `1` → `2`.** Still commented out, so this is
  a no-op functionally — noted only for completeness.

  ```c
  -//#define NUM_M106_FANS 1
  +//#define NUM_M106_FANS 2
  ```

### `Marlin/src/pins/stm32f1/pins_BTT_SKR_MINI_E3_V2_0.h`

- **Disabled the board-default controller-fan pin.** The `CONTROLLER_FAN_PIN`
  fallback to `FAN1_PIN` was commented out. This complements the disabled
  `USE_CONTROLLER_FAN` in `Configuration_adv.h` and keeps **FAN1** dedicated to
  the hot-end auto-fan (`E0_AUTO_FAN_PIN`), since the mainboard fan is wired to
  PWR rather than a fan header.

  ```c
  -#ifndef CONTROLLER_FAN_PIN
  -  #define CONTROLLER_FAN_PIN            FAN1_PIN
  -#endif
  +// #ifndef CONTROLLER_FAN_PIN
  +//   #define CONTROLLER_FAN_PIN            FAN1_PIN
  +// #endif
  ```

> Note: these changes currently exist as uncommitted edits in the `Firmware`
> submodule (working tree), so they are not yet captured in the submodule's git
> history.
