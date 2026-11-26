"""Snowman (Frost Peaks, 1): a snowman that came to life angry. Sculpted: three lumpy, packed snowballs
leaning into a brawl, coal eyes glowing ice-blue under a furious brow, a jagged grin of icicles, a carrot
of ice for a nose, twig arms ending in icicle claws, a tattered red scarf and a dented bucket helm."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(snow="f4f8ff", snow2="d8e4f0", coal="10141a", glow="5ad8ff", ice="cff4ff", twig="4a3424", bucket="5a6a7a",
              rust="8a5a3a", scarf="c81a2a")
    C.plan, C.attack = "biped", "swipe"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.3), (0, -0.03, 0.62), "root")
    C.bone("chest", (0, -0.03, 0.62), (0, -0.08, 0.86), "hips")
    C.bone("head", (0, -0.08, 0.86), (0, -0.1, 1.18), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.18 * sx, -0.05, 0.72), (0.36 * sx, -0.08, 0.84), "chest")
        C.bone(f"forearm.{side}", (0.36 * sx, -0.08, 0.84), (0.48 * sx, -0.14, 0.98), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    cl = Clay(C, "Body", res=0.018)
    cl.add((0, 0, 0.26), (0.3, 0.28, 0.25), group="snow")
    cl.add((0, -0.04, 0.62), (0.22, 0.2, 0.19), group="snow")
    cl.add((0, -0.09, 0.94), (0.16, 0.15, 0.15), group="snow")
    for k in range(10):                                                         # lumps
        a = k * 2.4
        z = 0.2 + 0.08 * k
        r = 0.27 if z < 0.45 else 0.2 if z < 0.8 else 0.15
        cl.add((math.cos(a) * r * 0.85, -0.04 + math.sin(a) * r * 0.85, z), (0.08, 0.08, 0.07), group="snow")
    cl.add((0, -0.2, 0.99), (0.12, 0.05, 0.03), rot=(-10, 0, 0), group="snow2")  # furious brow
    cl.mirror((0.06, -0.22, 0.96), (0.035, 0.03, 0.03), group="snow", neg=True)
    cl.add((0, -0.23, 0.86), (0.09, 0.04, 0.03), group="coal", neg=True)           # grin
    body = cl.build({"snow": "snow", "snow2": "snow2", "coal": "snow2"}, voxel=0.01, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.02})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.6, "snow2")
    for mx in (-1, 1):
        C.ellipsoid(f"Coal{mx}", (0.06 * mx, -0.225, 0.96), (0.028, 0.015, 0.028), "coal", "head")
        C.ellipsoid(f"Glow{mx}", (0.06 * mx, -0.24, 0.96), (0.012, 0.006, 0.012), "glow", "head")
        side = "L" if mx < 0 else "R"
        C.tube(f"Arm{side}", [V((0.18 * mx, -0.05, 0.72)), V((0.36 * mx, -0.08, 0.84)), V((0.48 * mx, -0.14, 0.98))],
               [0.02, 0.016, 0.012], "twig", None, allowed=[f"arm.{side}", f"forearm.{side}"])
        for k in (-1, 0, 1):
            C.cone(f"Claw{side}{k}", (0.48 * mx, -0.14, 0.98), (0.52 * mx + 0.03 * k, -0.2, 1.08 + 0.03 * k), 0.012, "ice",
                   f"forearm.{side}", segs=4)
    for k in range(6):
        x = -0.06 + 0.024 * k
        C.cone(f"Grin{k}", (x, -0.235, 0.88), (x, -0.24, 0.83 - 0.02 * (k % 2)), 0.012, "ice", "head", segs=4)
    C.cone("Nose", (0, -0.24, 0.92), (0.02, -0.38, 0.9), 0.025, "glow", "head", segs=6)
    C.lathe("Bucket", [(0.13, 0.0), (0.12, 0.1), (0.1, 0.16)], "bucket", "head", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, -0.09, 1.04)) @
                                  __import__("mathutils").Matrix.Rotation(-0.25, 4, 'Y'))
    C.ellipsoid("Rust", (0.06, -0.18, 1.12), (0.03, 0.02, 0.025), "rust", "head")
    C.ellipsoid("Scarf", (0, -0.07, 0.79), (0.17, 0.16, 0.05), "scarf", "chest")
    C.box("ScarfTail", (0.08, -0.2, 0.68), (0.06, 0.02, 0.2), "scarf", "chest", rot=(10, 0, 10), bevel=0.3)
