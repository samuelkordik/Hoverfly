# Calibration Guide — Review Questions & Notes

My read-through of [`GUIDE.md`](GUIDE.md) / [`index.html`](index.html) (and the `macros/` + `STL/`
they reference) before I sit down to actually run the 9 steps. I checked the macros against the steps;
mostly they line up well. Questions below are real ambiguities or ordering issues I hit.

## Ordering / dependency questions

1. **Step 4 (zoffset) depends on Step 9 (bed-mesh) — forward reference.** Step 4's Setup says "mesh
   exists (or run Step 9 first time)." So on a *fresh* printer I apparently need to build the mesh
   (Step 9) before I can set Z-offset (Step 4), but the numbering puts mesh last. What's the actual
   first-run order? My guess: Step 1 (tram) → Step 9 (build a first mesh) → Step 4 (zoffset) → then the
   rest. If so, can the guide say that explicitly for the first pass, since the linear 1→9 order is
   self-contradictory here?

2. **The live Z-offset method in Step 4 won't persist until the firmware reflash.** Step 4's **Run**
   leads with the LCD live-babystep method ("dial by feel → Store Settings"). But babysteps only save
   into the probe offset if `BABYSTEP_ZPROBE_OFFSET` is enabled — which is currently **off** and needs a
   reflash (firmware review §3). The macro note and the "If fail" both mention this, but the **Run**
   line still puts the live method first. As written, a first-time reader will dial it in by feel, hit
   Store Settings, and **lose it on reboot**. Until I do that reflash, should I just use
   `SET_ZOFFSET.gcode` with a measured number? I'd promote that caveat to the top of the step.

3. **PID (Step 2) is tuned at 205 °C, but the temp tower (Step 5) might pick 200.** I autotune the
   hotend at 205 in Step 2, then three steps later possibly settle on 200 or 210 from the tower. Do I
   need to re-run `PID_HOTEND.gcode` at my final chosen temp? The macro header says "re-run at your
   most-used print temperature" — so I think yes, but the step order doesn't loop back. Should Step 5
   (or "Done/save order") explicitly say "if your chosen temp differs from 205 by more than ~10°, re-run
   Step 2"? Minor, but it's the kind of thing I'd forget.

## How-do-I-know-it-worked questions (no terminal)

4. **Confirming a macro actually applied, with no console.** After I print e.g. `SET_ESTEPS.gcode` or
   `BUILD_MESH.gcode`, how do I verify the value took without `M503`? For E-steps I assume LCD →
   Steps/mm shows the stored value; for the mesh, the LCD mesh viewer. Can the guide list, per macro,
   "where on the LCD to look to confirm it saved"? That closes the loop for a no-terminal workflow.

5. **`M500` and the SKR Mini E3 V2.0's emulated EEPROM.** This board has no real EEPROM (it's flash-
   emulated). The macros all end in `M500` — confirming that's fully reliable here and survives reflash
   *except* when the EEPROM layout changes (which a firmware update can invalidate, silently resetting
   to defaults). Worth a note: after any reflash, re-verify stored values rather than assuming they
   carried over.

## Smaller questions

6. **Step 3 E-steps measurement precision.** Extruding 100 mm at 1 mm/s and measuring against a 120 mm
   mark with calipers/ruler — a 1 mm read error is a 1% e-step error. Is one run enough, or should I
   average two or three? Also: the macro heats to 205 and extrudes; it does **not** retract/cool the
   filament back, so I'll have a 100 mm string hanging — fine, just confirming that's expected and I
   snip it after.

7. **Step 8 (Input Shaping) is gated on a reflash that may fail to fit.** The step is clear that IS only
   runs "if compiled AND it fit on the F103," else it degrades to "lower acceleration." Just flagging
   for myself: don't spend time on the ringing-tower frequency sweep until I've confirmed the IS build
   doesn't overflow RAM (firmware review §7, and note the 20 KB / 48 KB discrepancy I raised there).

8. **Step 1 tramming with `M211 S0` (soft endstops off).** Disabling soft endstops to reach corners is
   fine, but is it re-enabled afterward? If the macro/LCD flow leaves `M211 S0` set, later moves could
   drive past limits. Confirm soft endstops get turned back on (or that this is LCD-jog only and `M211`
   is just reference).

## Notes to self

- Macros are well-built: `ESTEPS_TEST` and `BUILD_MESH` correctly heat before extruding/probing, PID
  macros run with the part fan on, and the `SET_*` files clearly say "EDIT FIRST." No complaints there.
- The "no terminal → Orca test / LCD menu / SD macro" framing is consistent across all three guides and
  the `CLAUDE.md` driver. I like that each step's **Run** line names the exact path.
- `CLAUDE.md` is set up to drive this interactively (read GUIDE, ask which `id` to start, one change at
  a time, log results). When I'm ready, I can run the session that way and have it append a `RESULTS.md`.
- Filament is Elegoo PLA (≈190–220 °C / 50–60 °C bed) — all temp/flow numbers assume that spool.
- The retraction 25 mm/s clamp is consistent with the other two guides. Good.
</content>
