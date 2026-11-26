"""Moon Guppy (Dark Moon, 2): a little deep-night fish that swims through the air, a lantern lure dangling
over a toothy underbite, big moon-silver eyes and a flowing veil tail that glows at the edges."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(body="2a3a7a", belly="8ab0e8", glow="aef4ff", eye="f0f4ff", pupil="0a0a1a", tooth="ffffff",
              fin="5a7ad8", stalk="1a2a5a")
    C.attack = "bite"
    kits.fish(C, "body", [(-0.55, 0.32, 0.12), (-0.42, 0.32, 0.3), (-0.12, 0.34, 0.34), (0.15, 0.36, 0.26),
                          (0.38, 0.38, 0.14), (0.52, 0.4, 0.07)], mid=3, hover=0.35)
    for k in range(4):
        y = -0.35 + 0.18 * k
        C.decal(f"Belly{k}", 0, -1, (0.18, 0.12, 0.04), "belly", "chest" if y < 0.0 else "hips", dir=(0, 0, 1), y=y)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.2 * mx, -0.4, 0.42), (0.09, 0.07, 0.09), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", (0.24 * mx, -0.45, 0.42), (0.04, 0.03, 0.05), "pupil", "head")
        C.membrane(f"Pec{mx}", [(0.25 * mx, -0.15, 0.3), (0.45 * mx, -0.05, 0.18), (0.42 * mx, 0.05, 0.3)][::(1 if mx > 0 else -1)],
                   "fin", "chest", thick=0.02)
    # underbite of needle teeth
    C.ellipsoid("Jaw", (0, -0.48, 0.24), (0.15, 0.14, 0.06), "belly", "jaw")
    for k, x in enumerate((-0.1, -0.05, 0.0, 0.05, 0.1)):
        C.cone(f"Tooth{k}", (x, -0.58 + abs(x) * 0.5, 0.26), (x, -0.59 + abs(x) * 0.5, 0.36), 0.015, "tooth", "jaw", segs=4)
    # lantern lure
    C.tube("Stalk", [V((0, -0.3, 0.62)), V((0, -0.42, 0.85)), V((0, -0.65, 0.8))], [0.02, 0.015, 0.012], "stalk", "head")
    C.ellipsoid("Lure", (0, -0.68, 0.72), (0.07, 0.07, 0.08), "glow", "head")
    # veil tail and dorsal fin
    C.membrane("Veil", [(0, 0.45, 0.42), (-0.32, 0.85, 0.75), (-0.1, 0.95, 0.4), (0, 0.9, 0.36), (0.1, 0.95, 0.4),
                        (0.32, 0.85, 0.75)], "fin", "tail2", thick=0.02)
    C.membrane("VeilLow", [(0, 0.45, 0.38), (-0.25, 0.8, 0.05), (0, 0.75, 0.22), (0.25, 0.8, 0.05)], "glow", "tail2",
               thick=0.025)
    C.membrane("Dorsal", [(0, -0.2, 0.62), (0, 0.05, 0.82), (0, 0.2, 0.58)], "fin", "hips", thick=0.02)
