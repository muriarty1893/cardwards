"""Cotton Puff (Candy Hills, 2): a sour little storm cloud of spun cotton candy, a scowling face in the
fluff, sugar-crystal lightning forking from its underside and sprinkles raining down."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(puff="ffb8e0", puff2="b8d8ff", puff3="e8c8ff", eye="2a0a2a", bolt="fff47a", spr1="ff4a8a", spr2="3ad8ff",
              stick="ffffff")
    C.plan, C.attack, C.hover = "hover", "dive", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.55), (0, 0, 0.8), "root")
    C.bone("chest", (0, 0, 0.8), (0, 0, 1.05), "hips")
    C.bone("head", (0, 0, 1.05), (0, -0.2, 1.05), "chest", deform=False)
    C.bone("tail1", (0, 0, 0.55), (0, 0, 0.25), "hips")
    C.spine, C.head, C.tail = ["hips", "chest"], "head", ["tail1"]
    for k, (x, y, z, r, m) in enumerate([(0, 0, 0.85, 0.3, "puff"), (0.24, 0.05, 0.78, 0.22, "puff2"),
                                         (-0.24, 0.05, 0.78, 0.22, "puff3"), (0.12, 0.12, 1.02, 0.2, "puff3"),
                                         (-0.14, 0.1, 1.0, 0.2, "puff2"), (0.0, 0.2, 0.78, 0.24, "puff"),
                                         (0.34, 0.1, 0.92, 0.15, "puff"), (-0.34, 0.1, 0.92, 0.15, "puff")]):
        C.ellipsoid(f"Puff{k}", (x, y, z), (r, r, r * 0.85), m, "chest" if z > 0.88 else "hips")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.09 * mx, -0.28, 0.9), (0.035, 0.015, 0.03), "eye", "chest")
        C.box(f"Brow{mx}", (0.09 * mx, -0.28, 0.95), (0.08, 0.02, 0.02), "eye", "chest", rot=(0, 25 * mx, 0), bevel=0.3)
    C.box("Frown", (0, -0.29, 0.8), (0.09, 0.015, 0.015), "eye", "chest", bevel=0.3)
    # sugar lightning and sprinkle rain
    for k, x in enumerate((-0.12, 0.15)):
        pts = [(x, 0.0, 0.6), (x + 0.08, -0.04, 0.45), (x - 0.04, -0.02, 0.38), (x + 0.05, -0.05, 0.2)]
        for j in range(3):
            C.tube(f"Bolt{k}{j}", [V(pts[j]), V(pts[j + 1])], [0.03, 0.02], "bolt", "tail1")
    for k in range(6):
        a = 2 * math.pi * k / 6
        C.ellipsoid(f"Sprinkle{k}", (math.cos(a) * 0.2, math.sin(a) * 0.15, 0.4 - 0.05 * (k % 3)), (0.012, 0.012, 0.035),
                    "spr1" if k % 2 else "spr2", "tail1")
