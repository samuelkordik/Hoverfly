; SET_ACCEL.gcode - set & save acceleration limits. EDIT THE VALUES FIRST.
;
; Firmware default print accel is 500 (conservative). Raise gradually, only after a ringing
; test shows the machine stays clean (see Step 7 / Step 8). (You can also set accel from the
; LCD: Configuration > Advanced > Acceleration, then Store Settings.)
;
M201 X1000 Y1000     ; <-- EDIT max X/Y acceleration
M204 P1000           ; <-- EDIT print acceleration
M500                 ; save to EEPROM
