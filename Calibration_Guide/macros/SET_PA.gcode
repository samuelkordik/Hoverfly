; SET_PA.gcode - set & save Linear Advance K (pressure advance). EDIT THE VALUE FIRST.
;
; Direct-drive Sprite K is small (~0.02-0.06). Use the value from Orca's Pressure Advance
; calibration test. Use EITHER this (Marlin K) OR Orca pressure advance - never both.
; If you run Orca's PA test it already writes M900 into the print, so you may not need this.
;
M900 K0.04           ; <-- EDIT 0.04 to your tuned value
M500                 ; save to EEPROM
