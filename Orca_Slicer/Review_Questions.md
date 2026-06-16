# Orca Slicer Guide — Review Questions & Notes

My read-through of [`orca-slicer-guide.md`](orca-slicer-guide.md) / [`index.html`](index.html) before I
build the printer profile. Comfortable with the config logic; new to slicer conventions.

## Questions

1. **Bed 210 vs the 220 plate — RESOLVED: keep 210.** The guide sets the Orca bed to **210 × 210** to
   match firmware (`X/Y_BED_SIZE 210`), accepting a ~10 mm dead border on the physical 220 plate. The
   `Ender 3 S1 Pro buildplate 220x220.stl` and `Grid Texture 220x220.png` in the repo root are **not**
   the target — treat them as unused/cosmetic, don't wire them into the Orca bed model (a 220 texture
   under a 210 bed shape would mismatch). No guide change needed. *(Decision confirmed 2026-06-16.)*

2. **Does Orca's jerk setting do anything here?** §2 lists "Jerk X/Y ~8 (advisory)" and notes classic
   jerk is **off** (firmware uses Junction Deviation 0.08). If firmware ignores jerk in favor of JD,
   then the Orca jerk field is cosmetic, right? If so, say "leave default / ignored" so I don't waste
   time tuning a number that has no effect. If it *does* get emitted as `M205 J`/`M566`, clarify.

3. **Temperature numbers don't quite agree across sections.** The filament table (§3) says nozzle
   **200–210 °C** (first layer +5). The Speed profile (§4) says **210–215**, Quality says **200–205**.
   I assume the intent is "Speed runs hotter for throughput, Quality cooler for detail, all within the
   200–215 envelope," but as written the §3 ceiling (210) is below the §4 Speed value (215). Is 215 OK
   for this Elegoo PLA, or should Speed cap at 210? The temp tower (Cal §5) presumably settles this, but
   I want the starting profile to not contradict itself.

4. **Max volumetric speed ~11 mm³/s — where does that come from and how do I verify it?** §3 lists it
   and §6 names a "Max volumetric speed" calibration as the last step, but there's no STL or macro for
   it in the Calibration guide's step list (Cal has no dedicated MVS step). Is the plan to use Orca's
   built-in MVS test? If so, a pointer would help; right now 11 reads as an unverified default.

5. **Start G-code `M420 S1 Z10` with no stored mesh.** §5 says start G-code loads a *stored* mesh
   instead of probing each print. What happens on the very first print, or after an EEPROM reset, when
   no mesh is stored yet — does it silently print with no compensation (possible nozzle crash / bad
   first layer)? Should the start G-code guard for "mesh valid" or should I just run `G29`+`M500`
   (Cal §9) **before** ever using this start block? Spelling out the prerequisite would prevent a
   first-print faceplant.

6. **First layer height 0.28 mm on the Speed profile.** That's 70% of a 0.4 nozzle for the *first*
   layer. Is that intentional for draft speed, and is bed adhesion still reliable at 0.28 first layer,
   or should first layer stay ≤0.24 even in Speed? New-to-printing question — I don't have intuition for
   how aggressive a first layer can be.

## Confusing

7. **"Pressure advance OFF if using Marlin K."** Clear in principle (pick one). Confirming the
   mechanics: in Orca I literally set Pressure Advance to disabled/0 in the filament profile, and rely
   on the firmware `M900 K` value. If I instead tune PA in Orca, I must make sure firmware
   `ADVANCE_K`/`M900 K` is **0**. Both guides say "pick one" — I just want to confirm there's no Orca
   toggle that silently re-emits `M900` and double-applies.

8. **Machine max accel 500 in Orca vs print accel 1500–2000 in the Speed profile.** §2 mirrors firmware
   max accel at 500, but the Speed profile (§4) lists print accel 1500–2000 "(needs firmware)." So out
   of the box, Orca will clamp my 1500 print accel down to the 500 machine-limit until I raise the
   firmware ceiling (Cal §7) **and** the Orca machine-limit. Two places to change, in order. Worth a
   one-liner that the Orca machine limit also has to be raised, not just firmware.

## Notes to self

- The retraction-speed clamp (25 mm/s firmware E max feedrate) is called out here and matches the
  firmware review and Cal guide — tune retraction **distance**, not speed. Consistent. Good.
- Direct-drive short retraction (0.6–0.8 mm) — don't carry over any Bowden-sized numbers.
- Per-profile detail lives in `profiles/SPEED.md`, `profiles/QUALITY.md`, `profiles/printer-settings.md`
  — read those before locking presets.
- Action: build the printer profile at firmware-true limits first (210 bed, 500 accel), get a clean
  first layer, *then* raise accel after Cal §7. Don't start from the aspirational Speed numbers.
</content>
