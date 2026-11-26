"""Glacier Shark (Frost Peaks, 5): a great shark carved from blue ice, jagged glacier fins and a crest
of frozen spikes, a cavernous jaw of icicle teeth and cold white eyes."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(ice="3a7ab8", belly="d8f0ff", crystal="aef0ff", dark="0a1a2a", tooth="ffffff", eye="f0ffff",
              gum="1a3a5a")
    C.attack = "bite"
    kits.fish(C, "ice", [(-1.0, 0.0, 0.08), (-0.78, 0.02, 0.2, 0.18), (-0.4, 0.04, 0.3, 0.28), (0.0, 0.05, 0.3, 0.28),
                         (0.4, 0.07, 0.2, 0.18), (0.75, 0.1, 0.1), (0.98, 0.14, 0.05)], mid=3, hover=0.55)
    # pale belly
    for k in range(7):
        y = -0.65 + 0.17 * k
        C.decal(f"Belly{k}", 0, -1, (0.2 - 0.015 * abs(k - 3), 0.12, 0.05), "belly", "chest" if y < 0.0 else "hips",
                dir=(0, 0, 1), y=y)
    # jaw with icicle teeth
    C.ellipsoid("Jaw", (0, -0.72, -0.14), (0.17, 0.24, 0.06), "belly", "jaw")
    C.ellipsoid("Gum", (0, -0.75, -0.08), (0.16, 0.2, 0.03), "gum", "jaw")
    for k, x in enumerate((-0.13, -0.08, -0.03, 0.03, 0.08, 0.13)):
        C.cone(f"ToothU{k}", (x, -0.86 + abs(x) * 0.8, -0.04), (x, -0.87 + abs(x) * 0.8, -0.13), 0.022, "tooth", "head", segs=4)
        C.cone(f"ToothL{k}", (x * 0.9, -0.83 + abs(x) * 0.8, -0.12), (x * 0.9, -0.84 + abs(x) * 0.8, -0.04), 0.02, "tooth",
               "jaw", segs=4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.13 * mx, -0.7, 0.1), (0.035, 0.04, 0.03), "eye", "head")
        C.box(f"Brow{mx}", (0.12 * mx, -0.7, 0.15), (0.08, 0.1, 0.025), "dark", "head", rot=(0, 25 * mx, 0), bevel=0.4)
        for k in range(3):
            C.box(f"Gill{mx}{k}", (0.25 * mx, -0.42 + 0.07 * k, 0.04), (0.012, 0.02, 0.14), "dark", "chest", bevel=0.3)
        # pectoral fins of ice
        C.membrane(f"Pec{mx}", [(0.25 * mx, -0.35, -0.08), (0.62 * mx, -0.15, -0.3), (0.5 * mx, -0.08, -0.25),
                                (0.25 * mx, -0.15, -0.1)][::(1 if mx > 0 else -1)], "crystal", "chest", thick=0.04)
    # jagged dorsal glacier fin + crest
    C.membrane("Dorsal", [(0, -0.2, 0.3), (0, 0.0, 0.85), (0, 0.12, 0.7), (0, 0.22, 0.32)], "crystal", "hips", thick=0.06)
    for k in range(4):
        y = -0.6 + 0.12 * k
        C.cone(f"Crest{k}", (0, y, 0.22 + 0.04 * k), (0, y + 0.1, 0.42 + 0.03 * k), 0.04, "crystal", "chest", segs=4)
    # tail fin
    C.membrane("TailFin", [(0, 0.9, 0.12), (0, 1.25, 0.6), (0, 1.12, 0.14), (0, 1.25, -0.35)], "crystal", "tail3",
               thick=0.05)
    C.membrane("Pelvic", [(0, 0.35, -0.12), (0, 0.5, -0.38), (0, 0.6, -0.12)], "crystal", "tail1", thick=0.04)
