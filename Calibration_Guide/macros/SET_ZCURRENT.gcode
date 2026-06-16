; SET_ZCURRENT.gcode - set & save Z TMC2209 run current (mA). EDIT THE VALUE FIRST.
;
; Stock Z current is 580 mA (firmware Z_CURRENT). Both dual-Z motors run in PARALLEL off
; this one driver and share its current, so raise this only if Z lacks torque or skips.
; Keep at or below ~1000 mA (TMC2209 ~1.4 A RMS ceiling) and check the driver isn't hot.
; UART mode makes this live-settable; no reflash needed.
;
M906 Z800            ; <-- EDIT 800 to your chosen Z run current in mA (stock 580)
M500                 ; save to EEPROM
