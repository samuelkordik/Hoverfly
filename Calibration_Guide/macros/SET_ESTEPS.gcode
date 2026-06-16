; SET_ESTEPS.gcode - set & save extruder steps/mm. EDIT THE VALUE FIRST.
;
; Compute from ESTEPS_TEST.gcode:  new = 423 * 100 / (actual mm extruded).
; Stock Sprite Extruder Pro is ~423. (You can also set this from the LCD:
; Configuration > Advanced > Steps/mm > E, then Store Settings.)
;
M92 E423             ; <-- EDIT 423 to your measured value
M500                 ; save to EEPROM
