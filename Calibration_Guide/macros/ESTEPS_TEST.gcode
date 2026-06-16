; ESTEPS_TEST.gcode - extrude exactly 100 mm to verify extruder steps/mm (E=423 for the Sprite)
;
; BEFORE RUNNING: load filament, then with a marker make a mark on the filament
;                 120 mm above the extruder inlet (use a ruler).
; HOW TO RUN: copy to SD, LCD: Print > ESTEPS_TEST.gcode.
; AFTER: measure the remaining distance from the inlet to your mark. 120 - remaining = mm extruded.
;        If it is not 100 mm:  new_esteps = 423 * 100 / (mm actually extruded)
;        Set the new value with SET_ESTEPS.gcode (or the LCD Steps/mm menu), then Store Settings.
;
M104 S205            ; heat hotend
M109 S205            ; wait for temperature
M83                  ; relative extrusion mode
G1 E100 F60          ; extrude 100 mm slowly (1 mm/s)
M104 S0              ; hotend off
