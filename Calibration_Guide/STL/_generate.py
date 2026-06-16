#!/usr/bin/env python3
"""Generate simple, watertight ASCII STL calibration models for the Hoverfly guide.

All models are axis-aligned box unions, which slice cleanly. Run: python3 _generate.py
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def box_facets(x0, y0, z0, x1, y1, z1):
    """Return 12 triangles (with outward normals) for an axis-aligned box."""
    # 8 corners
    v = {
        0: (x0, y0, z0), 1: (x1, y0, z0), 2: (x1, y1, z0), 3: (x0, y1, z0),
        4: (x0, y0, z1), 5: (x1, y0, z1), 6: (x1, y1, z1), 7: (x0, y1, z1),
    }
    # (normal, (a,b,c)) winding CCW seen from outside
    faces = [
        ((0, 0, -1), (0, 3, 2)), ((0, 0, -1), (0, 2, 1)),   # bottom
        ((0, 0, 1),  (4, 5, 6)), ((0, 0, 1),  (4, 6, 7)),   # top
        ((0, -1, 0), (0, 1, 5)), ((0, -1, 0), (0, 5, 4)),   # front (-Y)
        ((0, 1, 0),  (3, 7, 6)), ((0, 1, 0),  (3, 6, 2)),   # back (+Y)
        ((-1, 0, 0), (0, 4, 7)), ((-1, 0, 0), (0, 7, 3)),   # left (-X)
        ((1, 0, 0),  (1, 2, 6)), ((1, 0, 0),  (1, 6, 5)),   # right (+X)
    ]
    out = []
    for n, (a, b, c) in faces:
        out.append((n, v[a], v[b], v[c]))
    return out


def write_stl(name, facets):
    path = os.path.join(HERE, name)
    with open(path, "w") as f:
        solid = name.replace(".stl", "")
        f.write(f"solid {solid}\n")
        for n, a, b, c in facets:
            f.write(f"  facet normal {n[0]:.6e} {n[1]:.6e} {n[2]:.6e}\n")
            f.write("    outer loop\n")
            for p in (a, b, c):
                f.write(f"      vertex {p[0]:.6e} {p[1]:.6e} {p[2]:.6e}\n")
            f.write("    endloop\n")
            f.write("  endfacet\n")
        f.write(f"endsolid {solid}\n")
    return path, len(facets)


models = {}

# 1) 20mm XYZ calibration / dimensional-accuracy cube
models["calibration_cube_20mm.stl"] = box_facets(0, 0, 0, 20, 20, 20)

# 2) Single-wall flow / extrusion-multiplier test: 25x25x20 hollow-able box.
#    Print with 0 top/bottom layers, 1 perimeter, 0% infill, spiral/vase optional.
models["single_wall_flow_25mm.stl"] = box_facets(0, 0, 0, 25, 25, 20)

# 3) First-layer / Z-offset test patch: 60x60x0.30 thin square.
models["firstlayer_patch_60mm.stl"] = box_facets(0, 0, 0, 60, 60, 0.30)

# 4) Bridge test: two 10x40x10 feet with a 60x40x2 deck spanning a 40mm gap.
bridge = []
bridge += box_facets(0, 0, 0, 10, 40, 10)     # left foot
bridge += box_facets(50, 0, 0, 60, 40, 10)    # right foot
bridge += box_facets(0, 0, 9, 60, 40, 12)     # deck spanning the 40mm gap (overlaps feet 1mm)
models["bridge_test_40mm.stl"] = bridge

# 5) Temperature tower: 7 bands x 10mm (70mm tall). Change nozzle temp per band in the
#    slicer (height-based modifier / temp tower script), e.g. 220 C at the bottom down to
#    190 C at the top. Each band carries a -Y overhang fin so temperature-dependent overhang
#    and bridging quality is visible band to band. Simplified procedural stand-in for the
#    community "smart" temp towers (which carry text labels + stringing pegs).
temp = []
temp += box_facets(0, 0, 0, 25, 22, 70)                  # single column body (one watertight box)
for i in range(7):
    z0 = i * 10
    temp += box_facets(0, -8, z0 + 7, 25, 2, z0 + 10)    # cantilevered overhang fin (-Y), overlaps body
models["temp_tower_70mm.stl"] = temp

# 6) Retraction test: two 8x8 posts 50mm tall on a shared 1mm base, separated by a 32mm gap.
#    The nozzle travels across the gap every layer; poor retraction leaves strings between the
#    posts. Tune retraction distance/speed until the gap is clean.
retr = []
retr += box_facets(0, 0, 0, 48, 8, 1)     # shared base for adhesion
retr += box_facets(0, 0, 0, 8, 8, 50)     # post A
retr += box_facets(40, 0, 0, 48, 8, 50)   # post B
models["retraction_test_50mm.stl"] = retr

# 7) Ringing / ghosting tower: a 15x15 column 60mm tall with a 5mm nub protruding every 10mm.
#    Each nub forces a sharp direction change; the wall printed just after it echoes the
#    machine's resonance as ghosting. Used to judge acceleration limits and Input Shaping.
ring = []
ring += box_facets(0, 0, 0, 15, 15, 60)               # column
for i in range(6):
    zc = 5 + i * 10
    ring += box_facets(13, 5, zc, 20, 10, zc + 6)     # +X nub (overlaps column by 2mm)
models["ringing_tower_60mm.stl"] = ring

for fname, facets in models.items():
    path, n = write_stl(fname, facets)
    print(f"wrote {fname}: {n} facets")
