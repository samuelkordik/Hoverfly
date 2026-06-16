; PID_BED.gcode - Bed PID autotune (ONLY if you enabled PIDTEMPBED in firmware)
;
; Hoverfly ships with the bed on bang-bang control (PIDTEMPBED off), which is fine
; for PLA. This macro only does something if you compiled bed PID into the firmware.
; HOW TO RUN: copy to SD, LCD: Print > PID_BED.gcode.
;
M303 E-1 S60 C8 U1   ; autotune bed (E-1) @60C, 8 cycles, apply result (U1)
M500                 ; save to EEPROM
M140 S0              ; bed off
