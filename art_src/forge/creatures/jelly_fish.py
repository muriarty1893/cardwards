"""Jelly Fish (Candy Hills, 2): a drifting jelly-candy medusa, a glossy raspberry bell, a frill of sour-
sugar crystals and long licorice tentacles that sting."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(bell="ff5aa0", bell2="ffb8d8", frill="ffe8f4", tent="2a0a1a", tent2="c81a5a", eye="ffffff", pupil="1a0410",
              sugar="fff4fa")
    C.plan, C.attack, C.hover = "hover", "dive", 0.45
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("chest", (0, 0, 0.65), (0, 0, 1.05), "root")
    C.bone("head", (0, 0, 1.05), (0, -0.2, 1.05), "chest", deform=False)
    C.bone("tail1", (0, 0, 0.65), (0, 0.04, 0.35), "chest")
    C.bone("tail2", (0, 0.04, 0.35), (0, 0.1, 0.05), "tail1")
    C.spine, C.head, C.tail = ["chest"], "head", ["tail1", "tail2"]
    C.lathe("Bell", [(0.001, 1.1), (0.22, 1.08), (0.38, 0.96), (0.44, 0.8), (0.42, 0.68), (0.3, 0.7), (0.001, 0.72)],
            "bell", "chest", segs=28)
    C.lathe("Rim", [(0.4, 0.68), (0.47, 0.65), (0.44, 0.62)], "bell2", "chest", segs=28, wave=(10, 0.2, 0.3))
    for k in range(10):
        a = 2 * math.pi * k / 10
        C.cone(f"Frill{k}", (math.cos(a) * 0.44, math.sin(a) * 0.44, 0.66), (math.cos(a) * 0.5, math.sin(a) * 0.5, 0.56), 0.05,
               "frill", "chest", segs=4)
    for k in range(6):
        a = 2 * math.pi * k / 6 + 0.5
        C.decal(f"Spot{k}", math.cos(a) * 0.25, 2, (0.05, 0.05, 0.02), "bell2", "chest", part="Bell", dir=(0, 0, -1),
                y=math.sin(a) * 0.25)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.12 * mx, -0.38, 0.86), (0.05, 0.03, 0.05), "eye", "chest")
        C.ellipsoid(f"Pupil{mx}", (0.12 * mx, -0.41, 0.85), (0.02, 0.012, 0.035), "pupil", "chest")
        C.box(f"Brow{mx}", (0.12 * mx, -0.4, 0.93), (0.08, 0.02, 0.02), "tent", "chest", rot=(0, 25 * mx, 0), bevel=0.3)
    for k in range(8):
        a = 2 * math.pi * k / 8
        top = V((math.cos(a) * 0.25, math.sin(a) * 0.25, 0.68))
        pts = [top, top + V((math.cos(a) * 0.06, math.sin(a) * 0.06 + 0.04, -0.25)), top + V((0, 0.1, -0.5)),
               top + V((math.cos(a) * 0.08, 0.12, -0.62))]
        C.tube(f"Tentacle{k}", pts, [0.035, 0.03, 0.02, 0.005], "tent" if k % 2 else "tent2", None, allowed=["tail1", "tail2"])
