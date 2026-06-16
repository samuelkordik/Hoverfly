; SET_SHAPER.gcode - set & save Input Shaping frequencies. EDIT THE VALUES FIRST.
;
; ONLY works if INPUT_SHAPING_X/Y were compiled in AND the build fit on the STM32F103
; (see firmware review section 7). Otherwise these commands are ignored.
; Get the frequencies from the ringing-tower sweep (Step 8). Damping (D / zeta) ~0.15 to start.
;
M593 X F40           ; <-- EDIT X resonant frequency (Hz)
M593 Y F38           ; <-- EDIT Y resonant frequency (Hz)
M593 X D0.15 Y D0.15 ; damping (zeta); refine in 0.05 steps if needed
M500                 ; save to EEPROM
