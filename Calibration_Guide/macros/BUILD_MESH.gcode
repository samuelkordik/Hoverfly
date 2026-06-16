; BUILD_MESH.gcode - heat, home, probe the bed mesh, save it, and enable it.
;
; HOW TO RUN: copy to SD, LCD: Print > BUILD_MESH.gcode. Takes a few minutes (probes the grid).
; Probes at print BED temp so the mesh matches printing conditions (an aluminum bed warps when hot).
; AFTER: view the stored mesh on the LCD (Info / Bed Leveling > View Mesh). The serial-only
;        report M420 V is not visible without a console - use the LCD viewer instead.
;
M140 S60             ; bed to 60C (print temp - the bed warps when hot)
M104 S150            ; warm nozzle (clean, low ooze; the CRTouch probes, not the nozzle)
M190 S60             ; wait for bed
M109 S150            ; wait for nozzle
G28                  ; home all
G29                  ; probe the bilinear mesh
M500                 ; store the mesh to EEPROM
M420 S1 Z10          ; enable leveling + fade height 10mm
M104 S0              ; nozzle off
M140 S0              ; bed off
