"""Gumdrop (Candy Hills, 2): a hulking sugar-crusted gumdrop slime, one big suspicious eye, a wide frown,
and the half-dissolved candies it has swallowed floating inside its lime jelly."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(gum="5ad83a", gum2="a8ff7a", sugar="f4fff0", eye="ffffff", pupil="1a2a0a", mouth="1a3a0a", c1="ff4a8a",
              c2="ffd23a", c3="7a5aff")
    C.plan, C.attack, C.hover = "hover", "slam", 0.0
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.05), (0, 0, 0.45), "root")
    C.bone("chest", (0, 0, 0.45), (0, 0, 0.85), "hips")
    C.bone("head", (0, 0, 0.85), (0, -0.2, 0.9), "chest", deform=False)
    C.spine, C.head = ["hips", "chest"], "head"
    C.lathe("Body", [(0.001, 0.0), (0.42, 0.02), (0.48, 0.12), (0.42, 0.4), (0.28, 0.68), (0.12, 0.86), (0.001, 0.9)],
            "gum", None, segs=28)
    C.extra_idle.append(lambda P, t: (P.s("chest", 1.0 + 0.04 * math.sin(6.283 * t)), P.r("chest", 'Y', 3 * math.sin(6.283 * t))))
    import random
    rnd = random.Random(5)
    for k in range(26):
        a = rnd.uniform(0, 2 * math.pi)
        z = rnd.uniform(0.1, 0.8)
        r = 0.46 - 0.4 * max(0, z - 0.15) / 0.75
        C.decal(f"Sugar{k}", math.cos(a) * r, z, (0.02, 0.02, 0.018), "sugar", "chest" if z > 0.45 else "hips",
                dir=(-math.cos(a), -math.sin(a), 0), y=math.sin(a) * r)
    C.ellipsoid("Eye", (0, -0.36, 0.5), (0.13, 0.06, 0.12), "eye", "chest")
    C.ellipsoid("Pupil", (0.02, -0.41, 0.48), (0.05, 0.02, 0.055), "pupil", "chest")
    C.box("Lid", (0, -0.39, 0.6), (0.3, 0.06, 0.05), "gum2", "chest", rot=(0, -10, 0), bevel=0.5)
    C.box("Frown", (0, -0.43, 0.3), (0.2, 0.02, 0.03), "mouth", "hips", bevel=0.4)
    for k, (x, z, m) in enumerate([(0.18, 0.25, "c1"), (-0.2, 0.32, "c2"), (0.05, 0.15, "c3")]):
        C.ellipsoid(f"Swallowed{k}", (x, -0.38, z), (0.05, 0.03, 0.05), m, "hips", rot=(0, 30 * k, 0))
