# Migration to delicass — remaining steps

Hoverfly's host is moving from `trantor` (Lenovo ThinkPad W540) to `delicass`
(ThinkPad P52s), primarily to get GPU-accelerated Obico AI failure detection
(delicass has a Pascal-generation Quadro P500; trantor's Kepler-era K1100M
can't run modern CUDA). This tracks what's left to reach print-ready on the
new host. See `README.md` for the finished pieces (webcam, crowsnest, the
Python 3.9 driver notes, etc.) and `CLAUDE.md` (not in this public repo) for
full machine-level context.

Status snapshot: physical migration is complete and verified. delicass is
running Klipper/Moonraker/Mainsail with the real SKR board and C615 webcam,
the full self-hosted Obico stack (GPU-accelerated `ml_api`) is up and linked,
and OrcaSlicer is running with proper CPU/memory caps. Remaining work is the
Cloudflare tunnel cutover, Klipper calibration, and some loose ends.

## 1. Physical hardware swap — done

- [x] Confirmed no print active on trantor before touching anything.
- [x] Stopped `klipper` + `moonraker` on trantor.
- [x] Moved the SKR Mini E3's USB cable and the Logitech C615 to delicass.
- [x] `/dev/serial/by-id/...` and the webcam's `/dev/v4l/by-id/...` both
      carried over identically — confirmed host-independent, as expected.
- [x] Klipper reaches `state: ready` on delicass with the real hardware.
- [x] crowsnest streaming confirmed (`200` on snapshot, through nginx's
      `/webcam/` proxy).

## 2. Cloudflare tunnel cutover — done

- [x] `delicass-ssh.samuelkordik.com` already configured and live.
- [x] `mainsail.samuelkordik.com` repointed to delicass and confirmed working.
- [x] `slicer.samuelkordik.com` repointed to delicass and confirmed working.
- [ ] Decide fate of trantor's remaining routes (`trantor2.samuelkordik.com/mainsail`,
      `/remote`) — remove, or keep trantor reachable for whatever it becomes next.
      Depends on trantor's fate (see loose ends, below).
- [ ] Decide whether the Obico web dashboard gets a tunnel hostname too (with
      Cloudflare Access in front, like Mainsail) or stays LAN-only.

**Known issue found post-cutover:** OrcaSlicer's Selkies session can go to a
black screen intermittently. Suspected cause is `mem_limit` (currently `8g`)
being too tight, but not yet root-caused. Workaround is restarting the
container. Documented in `README.md`; fix properly on a later date.

## 3. Software on delicass — done

- [x] `docker compose` working (installed as a per-user CLI plugin binary —
      `docker-compose-plugin` isn't in Ubuntu's own apt repo, only Docker's
      official one, so this sidesteps adding another apt source entirely).
- [x] OrcaSlicer up via `docker compose`, same CPU/mem caps as trantor
      (`cpus: 6.0`, `mem_limit: 8g`), loopback-only.
- [x] Full self-hosted `obico-server` stack up: `web`, `redis`, `tasks`,
      `ml_api` (no separate Postgres needed — defaults to SQLite). GPU
      reservation added via a `docker-compose.override.yml` (upstream has no
      GPU wiring by default). Confirmed the Darknet model loads on the P500
      (`compute_capability = 610`) inside the real stack, not just the
      earlier standalone smoke test.
- [x] `.env` created with a freshly generated `DJANGO_SECRET_KEY` (never
      rely on the hardcoded fallback baked into the public repo) and
      `SITE_IS_PUBLIC=False` / `ACCOUNT_ALLOW_SIGN_UP=False` for a private
      instance.
- [x] Hit and fixed a Django `Site` framework 500 error — the seeded
      `Site` record defaulted to `localhost:3334`, which didn't match
      `192.168.1.70:3334`. Updated to match. **If this is ever reached via a
      different hostname (e.g. a future tunnel route), the `Site` record
      needs updating again** — it hard-matches by domain.
- [x] `moonraker-obico` installed and linked to the self-hosted server
      (`http://127.0.0.1:3334`) — confirmed connected both directions:
      Moonraker's log shows `Client Identified - Name: Obico, Type: agent`,
      and the Obico server's DB shows live printer state (temps, status)
      flowing in.
- [x] The `moonraker-obico` systemd service needed a manual first `start`
      after `install.sh` finished — `enable` alone doesn't start it.

## 4. Database audit — done

Deliberately skipped copying trantor's `moonraker-sql.db` during the
software migration (job history was empty, seemed safe to skip). That
turned out to be half-right — worth a full audit rather than assuming:

- [x] **Webcam registration was missing.** Streaming worked fine
      (`crowsnest` doesn't need Moonraker to function), but Mainsail didn't
      know a camera existed because that pairing lives in Moonraker's own
      `[webcams]` namespace, not in `crowsnest.conf`. Registered via
      Moonraker's `/server/webcams/item` API, then corrected to match
      trantor's exact settings (`service: mjpegstreamer-adaptive` not plain
      `mjpegstreamer`, `aspect_ratio: 16:9` not the default `4:3`, plus
      matching icon/name/fps).
- [x] Carried over three real `[mainsail]` preferences via Moonraker's
      `/server/database/item` API: `general` (printer display name
      "Hoverfly"), `uiSettings` (custom theme colors), and `dashboard` (a
      genuinely customized panel layout across desktop/tablet/mobile — not
      the stock default).
- [x] Confirmed safe to leave behind: `[moonraker]` instance bookkeeping
      (`instance_id`, `klippy_connection`, etc. — copying would corrupt
      delicass's own identity), `[update_manager]` cached hashes
      (auto-regenerate), `authorized_users` (holds trantor's own API key —
      a credential, not something to copy; delicass has its own), and minor
      UX state (`gcodehistory`, `macros` mode, `view` autoscale).
- [ ] Note: Mainsail also keeps some state in the **browser's** own
      localStorage (e.g. the saved-instances picker on a phone) — that's
      client-side and can't be migrated server-side.

## 5. Klipper calibration still needed (placeholders in printer.cfg)

Probe `z_offset` is done (`3.779`, from `PROBE_CALIBRATE`). Still open:

- [x] **Extruder `rotation_distance`** — `4.637` (unverified placeholder) →
      `7.501`, via "measure and trim", converged over 3 iterative passes:
      `4.637` → 175.82mm actual for 100mm commanded → corrected to `8.153`
      → 92.0mm actual → corrected to `7.501` → 100.01mm actual, converged.
      Applied live via `SET_EXTRUDER_ROTATION_DISTANCE` between passes for
      validation before writing permanently to `printer.cfg`.
- [x] **Extruder PID** — `Kp=23.835 Ki=1.558 Kd=91.168` (`PID_CALIBRATE` at
      240°C, PETG target). Marlin's old values are auto-commented, not lost.
- [x] **Bed PID** — `Kp=71.219 Ki=1.547 Kd=819.913` (`PID_CALIBRATE` at
      80°C, PETG target).
- [ ] **Bed mesh** — no saved profile yet; run `BED_MESH_CALIBRATE` now that
      extruder rotation_distance is calibrated, then `SAVE_CONFIG`.
- [ ] **`[bed_screws]` corner coordinates** — still the generic Ender 3
      4-corner layout; verify against Hoverfly's actual screw positions via
      `BED_SCREWS_ADJUST`.
- [ ] **Firmware retraction** — starting guesses for the direct-drive Sprite
      Extruder Pro (`retract_length: 0.5`, etc.); tune against real
      oozing/stringing vs. clogging behavior.
- [ ] Remember: after **every** `SAVE_CONFIG`, the `printer.cfg` symlink
      breaks (Klipper's backup-via-rename clobbers it — this already
      happened once during this migration, see git history). Re-sync
      manually: copy the live `printer_data/config/printer.cfg` content
      back over `hoverfly/klipper/printer.cfg`, delete the stray real file,
      re-link, commit. Worth switching to a `[include]`-based split (tracked
      base config + untracked autosave file) if this gets tedious.

## 6. Loose ends to resolve (not blocking print-readiness)

- [x] The MCU `serial:` value and `screw_thread: CW-M3` removal (previously
      uncommitted edits from a concurrent trantor session) are now resolved
      and committed — turned out `screw_thread` is a hard config error in
      this Klipper version (confirmed by reproducing it on delicass), not a
      style choice, and the serial was verified correct via the actual
      hardware move.
- [x] Stray `klipper/printer.cfg.save` file deleted.
- [x] Trantor's fate decided: repurposed as a general-purpose compute/dev/
      analysis box. R will be installed for data analysis, but **not**
      RStudio Server — Positron remote/SSH development is the plan instead.
      Not urgent, tackle when there's a concrete need. `CLAUDE.md` rewritten
      on both machines: trantor's now describes its new role, delicass got
      its own `~/CLAUDE.md` (not tracked in this public repo) covering the
      full printer-host context.
- [ ] Clean up trantor's now-stale `trantor2.samuelkordik.com/mainsail`
      tunnel route in the Cloudflare dashboard (Mainsail moved to
      `mainsail.samuelkordik.com`/delicass; this route serves nothing now).
      Low priority, noted in trantor's `CLAUDE.md`.

## 7. Final verification

- [ ] First real test print on delicass-hosted Klipper, watched closely.
- [ ] Confirm timelapse capture works end-to-end during that print.
- [ ] Confirm Obico actually flags something (or correctly flags nothing)
      during/after that print.
