# Migration to delicass — remaining steps

Hoverfly's host is moving from `trantor` (Lenovo ThinkPad W540) to `delicass`
(ThinkPad P52s), primarily to get GPU-accelerated Obico AI failure detection
(delicass has a Pascal-generation Quadro P500; trantor's Kepler-era K1100M
can't run modern CUDA). This tracks what's left to reach print-ready on the
new host. See `README.md` for the finished pieces (webcam, crowsnest, the
Python 3.9 driver notes, etc.) and `CLAUDE.md` (not in this public repo) for
full machine-level context.

Status snapshot: delicass is running Ubuntu 24.04, NVIDIA driver + Docker +
container toolkit installed and GPU-passthrough verified, Klipper/Moonraker/
Mainsail already running there (no printer.cfg wired to real hardware yet),
`hoverfly` cloned and printer.cfg synced including the current probe
calibration. The SKR board and webcam are still physically on trantor.

## 1. Physical hardware swap (needs printer access, brief downtime)

- [ ] Confirm no print is active on trantor (`state: standby` in Mainsail).
- [ ] Stop `klipper` + `moonraker` on trantor.
- [ ] Move the SKR Mini E3's USB cable from trantor to delicass.
- [ ] Move the Logitech C615 webcam from trantor to delicass.
- [ ] On delicass, confirm `/dev/serial/by-id/...` matches what's in
      `printer.cfg` (`[mcu] serial:`) — should carry over since it's derived
      from the MCU's own USB descriptor, but verify rather than assume.
- [ ] Confirm Klipper reaches `state: ready` on delicass with real hardware.
- [ ] Confirm crowsnest picks up the C615 (`/dev/v4l/by-id/usb-046d_HD_Webcam_C615...`)
      and the Mainsail webcam view works.

## 2. Cloudflare tunnel cutover

- [x] `delicass-ssh.samuelkordik.com` already configured and live.
- [ ] Repoint `mainsail.samuelkordik.com` → delicass (`http://localhost:80`).
- [ ] Repoint `slicer.samuelkordik.com` → delicass (`http://localhost:3000`).
- [ ] Decide fate of trantor's remaining routes (`trantor2.samuelkordik.com/mainsail`,
      `/remote`) — remove, or keep trantor reachable for whatever it becomes next.
- [ ] Once cut over, confirm Mainsail + OrcaSlicer load correctly from outside
      the LAN (not just `192.168.1.70` directly).

## 3. Software still to finish on delicass

- [ ] `sudo apt install -y docker-compose-plugin ffmpeg`
- [ ] Bring up OrcaSlicer via `docker compose` (image already pulled and
      smoke-tested; just needs the compose plugin to launch with proper
      CPU/memory caps instead of the ad-hoc uncapped test run).
- [ ] Stand up the full `obico-server` stack (web + Postgres + redis + tasks
      + `ml_api`) with a GPU device-reservation override for `ml_api` — the
      upstream compose file has no GPU wiring by default.
- [ ] Run `migrate` + `collectstatic`, then **you** run `createsuperuser`
      interactively (deliberately not automating this — don't want to handle
      your password).
- [ ] Generate a printer auth token from the Obico web UI.
- [ ] Install `moonraker-obico` (the separate lightweight client that talks
      to Moonraker and streams frames) pointed at `http://127.0.0.1:<port>`
      — everything stays on-box, nothing leaves the LAN.
- [ ] Decide whether the Obico web dashboard itself gets a tunnel hostname
      (with Cloudflare Access in front, like Mainsail) or stays LAN-only.

## 4. Klipper calibration still needed (placeholders in printer.cfg)

Probe `z_offset` is done (`3.779`, from `PROBE_CALIBRATE`). Still open:

- [ ] **Extruder `rotation_distance`** — currently `4.637`, a starting guess
      for the Sprite Extruder Pro's 3.5:1 gearing. Run the standard
      "measure and trim" extruder calibration.
- [ ] **Extruder PID** — `PID_CALIBRATE HEATER=extruder`. Marlin's tuned
      values don't transfer (different PWM scaling/loop timing).
- [ ] **Bed PID** — `PID_CALIBRATE HEATER=heater_bed`, same reason.
- [ ] **Bed mesh** — no saved profile yet; run `BED_MESH_CALIBRATE` once the
      above is done, then `SAVE_CONFIG`.
- [ ] **`[bed_screws]` corner coordinates** — still the generic Ender 3
      4-corner layout; verify against Hoverfly's actual screw positions via
      `BED_SCREWS_ADJUST`.
- [ ] **Firmware retraction** — starting guesses for the direct-drive Sprite
      Extruder Pro (`retract_length: 0.5`, etc.); tune against real
      oozing/stringing vs. clogging behavior.
- [ ] Remember: after **every** `SAVE_CONFIG`, the `printer.cfg` symlink
      breaks (Klipper's backup-via-rename clobbers it — see the note in
      recent git history). Re-sync manually: copy the live
      `printer_data/config/printer.cfg` content back over
      `hoverfly/klipper/printer.cfg`, delete the stray real file, re-link,
      commit. Worth switching to a `[include]`-based split (tracked base
      config + untracked autosave file) if this gets tedious.

## 5. Loose ends to resolve (not blocking print-readiness)

- [ ] Two uncommitted local edits on trantor's `printer.cfg` from a
      concurrent Klipper-bringup session, still sitting in the working tree:
      the real MCU `serial:` value, and removal of `screw_thread: CW-M3`
      from `[bed_screws]`. Review and decide whether/how to commit once
      that session's work is understood — didn't want to absorb someone
      else's in-progress edits into an unrelated commit.
- [ ] Stray `klipper/printer.cfg.save` file (editor backup, untracked) —
      safe to delete once confirmed unneeded.
- [ ] Decide trantor's fate post-migration: repurposed, warm spare, or wound
      down. Drives how much of `CLAUDE.md` (trantor-centric today) needs
      rewriting for a two-machine (or delicass-only) world.

## 6. Final verification

- [ ] First real test print on delicass-hosted Klipper, watched closely.
- [ ] Confirm timelapse capture works end-to-end during that print.
- [ ] Confirm Obico actually flags something (or correctly flags nothing)
      during/after that print.
