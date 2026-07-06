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

## Klipper Migration
Hoverfly is moving from Marlin to Klipper. `klipper/printer.cfg` is the working config, symlinked into `~/printer_data/config/printer.cfg` and run via Mainsail/Moonraker on the host machine (a headless Ubuntu Server ThinkPad — see [Remote Access](#remote-access) below).

It's derived from BigTreeTech's stock SKR Mini E3 V2.0 reference config, adjusted for Hoverfly's specifics:
- Z homes exclusively via the CRTouch (`probe:z_virtual_endstop`), matching the old `USE_PROBE_FOR_Z_HOMING` Marlin setup — no physical Z endstop.
- Probe offsets (-30, -40) and the `safe_z_home` position carry over directly from the Marlin `NOZZLE_TO_PROBE_OFFSET`/`Z_SAFE_HOMING` values above.
- Display is a Mini12864-style ST7920 graphic panel + rotary encoder, wired entirely through the SKR's EXP1 header.

Still marked as placeholders in the config, pending on-printer calibration: extruder `rotation_distance` (Sprite Extruder Pro's 3.5:1 gearing), extruder/bed PID values, and the BLTouch `z_offset`. The MCU `serial` also needs to be filled in once connected via USB.

## Remote Access

The printer runs on a **headless Ubuntu Server ThinkPad** (no desktop). Everything is used remotely — SSH and web apps — with **no inbound ports opened on the router**. Access is published through a **Cloudflare Tunnel**, so the machine reaches out to Cloudflare and services are exposed at `*.samuelkordik.com` hostnames. This section documents the setup for anyone wanting to replicate it.

### Architecture

```
Browser / SSH client
      │  HTTPS / SSH over Cloudflare's edge
      ▼
Cloudflare Tunnel  ──►  cloudflared (systemd service on the host)
                              │
              ┌───────────────┼────────────────────────┐
              ▼               ▼                          ▼
        Mainsail (:80)   SSH (:22)          OrcaSlicer container (127.0.0.1:3000)
        Klipper/Moonraker                   lscr.io/linuxserver/orcaslicer
```

- **`cloudflared`** runs as a host `systemd` service (token-based connector). The tunnel token comes from the Cloudflare Zero Trust dashboard and is **not stored in this repo**.
- **Ingress rules are managed in the Cloudflare dashboard** (Zero Trust → Networks → Tunnels → *Public Hostname*), not in a local config file.
- Because some origins are host-local (`localhost:80`, `localhost:22`), `cloudflared` stays on the **host** rather than in a container.

### Published routes

| Public hostname | Origin service | Purpose |
| --- | --- | --- |
| `trantor2.samuelkordik.com/mainsail` | `http://localhost:80` | Mainsail — printer control |
| `trantor2.samuelkordik.com/remote` | `ssh://localhost:22` | SSH (browser terminal) |
| `trantor-ssh.samuelkordik.com` | `ssh://192.168.1.69:22` | SSH (native client) |
| `slicer.samuelkordik.com` | `http://localhost:3000` | OrcaSlicer in the browser |

### OrcaSlicer in the browser

Rather than a remote desktop, OrcaSlicer runs as a self-contained web app via the
[LinuxServer.io OrcaSlicer image](https://docs.linuxserver.io/images/docker-orcaslicer/)
(Selkies), so it's usable from any device including an iPad. It has native Moonraker upload, so you slice and send G-code straight to Mainsail. Key points for replication:

- Bind the container to loopback only (`127.0.0.1:3000`/`:3001`) and expose it **exclusively via the tunnel** — never publish to `0.0.0.0`.
- Cap CPU/RAM (`cpus`, `cpu_shares`, `mem_limit`) so slicing can't starve an active print.
- Persist `/config` for profiles and models.

### Securing it

The tunnel makes services publicly reachable, so **authentication is enforced with [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/policies/access/)** (email OTP / SSO) in front of every hostname — essential since Mainsail controls physical hardware and the OrcaSlicer web terminal has root inside its container.
