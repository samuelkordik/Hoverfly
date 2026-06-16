; PID_HOTEND.gcode - Hotend PID autotune for Hoverfly (Sprite Extruder Pro)
;
; HOW TO RUN: copy this file to the SD card, then on the printer LCD choose
;             Print > PID_HOTEND.gcode.
; WHAT IT DOES: heats to 205 C and autotunes the hotend PID over 8 cycles with the
;               part fan ON (so the tune matches real printing), applies the result,
;               and saves it to EEPROM.
; TIME: ~5-10 minutes. The hotend will reach 205 C.
; NOTE: re-run at your most-used print temperature if you change it.
;
M106 S255            ; part fan ON - tune under print-like cooling
M303 E0 S205 C8 U1   ; autotune hotend @205C, 8 cycles, apply result (U1)
M107                 ; part fan off
M500                 ; save PID to EEPROM
M104 S0              ; hotend off
