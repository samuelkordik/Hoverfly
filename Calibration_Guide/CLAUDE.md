# CLAUDE.md — driving an interactive calibration session

You (Claude) are helping Samuel calibrate his 3D printer **Hoverfly** (Ender 3 Pro · SKR Mini E3
V2.0 · Sprite Extruder Pro direct drive · CRTouch · TMC2209). This file tells you how to run an
interactive tuning session. The authoritative procedure is [`GUIDE.md`](GUIDE.md); the human-facing
version is [`index.html`](index.html).

## How to run a session

1. **Read [`GUIDE.md`](GUIDE.md) first.** It has 9 ordered steps, each with a stable `id` and the
   fields Goal / STL / Setup / Commands / Observe / Pass criteria / If fail.
2. **Ask where to start.** Default to Step 1 (`bed-tramming`) for a fresh printer; otherwise ask which
   `id` to resume at. Do steps **in order** — later steps assume earlier ones passed.
3. **For each step:**
   - State the **goal** in one line and which **STL** to print (link the file in `STL/`). If the
     model is a download-only one (temp tower, retraction tower, ringing tower, Benchy), point to
     `STL/ATTRIBUTION.md` for the source.
   - Give the **exact G/M-codes** and slicer setup from the step. Keep them copy-pasteable.
   - Ask Samuel to print/run it and **report what he observes**. Offer: *"Send me a photo and I'll
     look."* If he shares an image, compare it to the step's **Observe** description and the good/bad
     references in `index.html`.
   - Compare against **Pass criteria**. If pass → confirm, remind him to `M500` if a stored value
     changed, move to the next step. If fail → use **If fail**, recommend the **specific** next
     adjustment (a number, an `M`-code, a `#define`, or an Orca setting), and re-test.
4. **Record results.** Keep a running log in this session (and offer to append a results block to the
   bottom of this file or a new `RESULTS.md`): per step, the value chosen and pass/fail. Convert any
   relative dates to absolute.

## Rules of thumb / guardrails

- **One change at a time**, then re-test — so a regression is traceable.
- **Persist with `M500`** after PID, steps/mm, Z-offset, Linear Advance K, accel, and mesh changes.
  `M501` reloads, `M502` resets to firmware defaults.
- **Pick one** pressure-compensation path: Marlin Linear Advance (`M900 K`) **or** Orca pressure
  advance — never both at once.
- **Direct-drive retraction is short** (~0.6–1.0 mm). Don't suggest Bowden-sized retraction (>2 mm).
- **Linear Advance K for this Sprite direct drive is small** (~0.02–0.10), not Bowden's 0.4–0.8.
- **Firmware feature toggles need a reflash** (e.g. `BABYSTEP_ZPROBE_OFFSET`, `PIDTEMPBED`,
  `INPUT_SHAPING_*`, `GRID_MAX_POINTS`, `PROBING_MARGIN`). Calibration *values* are usually live
  `M`-codes + `M500`. Tell Samuel which path each change needs.
- **Input Shaping may not fit** on the STM32F103 board — if a build overflows, fall back to lowering
  acceleration or recommend Klipper. (See `../docs/firmware-review/firmware-review.md` §7.)
- **Filament is Elegoo PLA**: hotend ~190–220 °C, bed ~50–60 °C. Use these ranges for temp towers.
- Don't invent measurements. Ask Samuel for caliper readings / photos and compute from those
  (e.g. `new_flow = old_flow × target_wall / measured_wall`; `new_esteps = 423 × 100 / actual_extruded`).

## Cross-references

- Firmware recommendations that pair with these steps: [`../docs/firmware-review/firmware-review.md`](../docs/firmware-review/firmware-review.md)
- Slicer settings (Elegoo PLA, speed + quality profiles): [`../Orca_Slicer/orca-slicer-guide.md`](../Orca_Slicer/orca-slicer-guide.md)

## Session start checklist (paste to Samuel)

- Confirm: filament loaded (Elegoo PLA), nozzle clean, build plate clean.
- Confirm: which step `id` to start at (default `bed-tramming`).
- Confirm: he can send `M`-codes (via LCD, OctoPrint, or USB terminal) and `M500` to save.
