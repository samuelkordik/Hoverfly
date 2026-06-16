# Firmware Review — Review Questions & Notes

My read-through of [`firmware-review.md`](firmware-review.md) / [`index.html`](index.html) as the
person who'll actually flash this board. I'm comfortable with the firmware/electronics side but new to
3D-printing-specific conventions, so my questions skew toward "does this match what's *actually* in the
config" and "how do I do this with no serial console."

## Things to verify against the real config (highest value)

1. **S-curve vs Linear Advance — does the current firmware even build?** §2/§8 say
   `S_CURVE_ACCELERATION` and `LIN_ADVANCE` are *both* enabled, and that Marlin's sanity check
   `#error`s on that pair unless `EXPERIMENTAL_SCURVE` is forced. But this firmware is presumably
   compiling and running today. So one of three things is true and I want to know which **before** I
   touch anything:
   - `S_CURVE_ACCELERATION` isn't actually enabled (then there's nothing to fix), or
   - `EXPERIMENTAL_SCURVE` is defined (masking the error), or
   - `LIN_ADVANCE` isn't actually compiled in.
   **Action:** grep `Configuration_adv.h` for all three before writing the §2b fix. The recommendation
   is sound, but the premise should be confirmed, not assumed.

2. **`LEVELING_BED_TEMP` — is it even defined?** §6 and Cal §9 both say "check it, set it to 60."
   Is this currently set, unset (defaulting to what?), or commented out in our config? A one-line grep
   answers it and turns "check this" into a concrete edit.

3. **`PROBING_MARGIN 25` with a 40 mm probe Y-offset.** §5 wants margin dropped 50→25, but the probe
   sits 30 mm left / **40 mm front** of the nozzle. With a 25 mm margin, does the probe physically clear
   the bed at the front-row points, or does Marlin shift them inward automatically? I'd like the *math*
   for the smallest safe margin given a {-30,-40} offset, rather than "lower it and watch G29, raise if
   it deploys off the bed." Trial-and-error off a hot bed is the thing I most want to avoid.

## No-terminal gaps (the workflow says "no G-code console")

4. **How do I raise the Z driver current without a serial console?** §1 says if dual-Z parallel lacks
   torque, raise `Z UART_CURRENT_MA` to ~800–1000 mA. Is that a `#define` (reflash) or a live `M906 Z…`
   + `M500`? If it's `M906`, there's **no SD macro for it** in `macros/` — the others (PID, esteps, PA,
   shaper, accel, zoffset, mesh) all have one. Should we add a `SET_ZCURRENT.gcode`? And what's the
   stock Z current we'd be raising *from*?

5. **Bed PID** (§4) — `PID_BED.gcode` exists, good. But confirming the path: `PIDTEMPBED` is a compile
   flag (reflash), *then* the macro autotunes. The guide is clear, just confirming I read the
   two-step (reflash → macro) correctly.

## Confusing / possibly inconsistent

6. **F103 RAM figure contradicts itself.** §7 says the STM32F103 has "**20 KB RAM**," but the "Making
   it fit" paragraph and the code comment both say "**48 KB SRAM**." The SKR Mini E3 V2.0's part is the
   STM32F103RC (48 KB). The "20 KB" looks like a stray wrong number — worth fixing so the Input Shaping
   feasibility call is based on the right budget.

7. **`FAN_MIN_PWM 75` vs the slicer's "0% on layer 1."** §Fans adds `FAN_MIN_PWM 75` (~30% floor) so
   the 5015s don't stall, and the Orca profiles run the part fan at 0% for layer 1. Does `FAN_MIN_PWM`
   force the fan to 30% even when the slicer commands 0 — i.e. will my first layer always have airflow?
   My understanding is the floor only applies to *non-zero* commands (0 = off), but I'd like that stated
   explicitly, because layer-1 cooling actively hurts PLA bed adhesion.

8. **`FAN_KICKSTART_TIME 150` / `FAN_MIN_PWM 75` units.** Confirm `75` is out of 255 (≈29%), not a
   percent, and `150` is ms. The comments imply it but I want to be sure before I trust the floor value.

9. **Dual-Z current split, mechanically.** §1 says two motors "split" the one driver's current. For
   two steppers wired in **parallel**, the driver's set current is shared but not necessarily evenly
   (depends on each motor's back-EMF / position). Is the practical assumption "each sees ~half"? That
   affects how high I should push `UART_CURRENT_MA` before worrying about the ~1.4 A RMS driver ceiling.

## Notes to self

- The only firmware change actually committed is E-steps 93→423 (and it's currently an *uncommitted*
  working-tree edit in the submodule per the README). **Everything else in this review is a reflash I
  haven't done yet.** Plan: branch the submodule, do **one** toggle per build, flash, verify, `M500`.
- Priority order I'm taking from this: (1) §2b disable S_CURVE — but only after confirming item #1
  above; (2) §2 calibrate Linear Advance K via Cal §6; (3) §3 `BABYSTEP_ZPROBE_OFFSET` so my live
  Z-offset actually persists (this one bites in Cal Step 4 — see that guide's questions). Bed PID,
  probe margin, mesh density, Input Shaping are all "nice to have."
- `M48`, `M503`, `M420 V` are serial-only → deferred to the planned Klipper move. Accepted.
- The retraction-speed clamp (E max feedrate = 25 mm/s) shows up in all three guides consistently —
  good, no contradiction there.
</content>
</invoke>
