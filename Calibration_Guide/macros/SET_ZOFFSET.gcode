; SET_ZOFFSET.gcode - set & save the probe Z-offset. EDIT THE VALUE FIRST.
;
; PREFER the live LCD method: start a print, double-click the encoder -> Babystep Z to dial the
; first layer by feel, then Configuration > Store Settings. Use this macro only to set a known
; number. More negative = nozzle closer to the bed. Firmware nominal is -3.49.
; (Live babysteps only persist to the probe offset if BABYSTEP_ZPROBE_OFFSET is enabled in
; firmware - see firmware review section 3. Until then, set the number here.)
;
M851 Z-3.49          ; <-- EDIT to your value
M500                 ; save to EEPROM
