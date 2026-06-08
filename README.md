# Hoverfly
"Hoverfly" was the nickname given by the RAF to the Sikorsky R-4, the first military helicopter to enter service for Allied forces (during WWII). So it's the name I'm giving to my first 3D printer.

The printer is a Creality Ender 3 Pro with the following modifications/additions:

- SKR Mini E3 V2.0 mainboard
- Dual Z-axis
- Sprite Extruder Pro direct-drive extruder + hotend
- CRTouch probe
- Marlin firmware

This repository is for me to keep track of configuration and firmware files.

## Marlin Configuration Adjustments
Using the "Creality/Ender-3 Pro/BigTreeTech SKR Mini E3 2.0" config example, with the following key changes:

```c
#define DEFAULT_KP 21.73
#define DEFAULT_KI 1.54
#define DEFAULT_KD 76.55

//#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN      // Probe is connected to Z-probe slot on board, not Z endstop.
#define USE_PROBE_FOR_Z_HOMING                    // Force use of probe for Z-axis homing
#define BLTOUCH
#define NOZZLE_TO_PROBE_OFFSET {-30, -40, -3.49 } // Experimentally verified.
#define PROBING_MARIN 50                          // Wanting to stay inside bed cleanly
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
