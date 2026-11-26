"""Jelly Fish (Candy Hills, 2): a drifting jelly-candy medusa. Sculpted: a glossy raspberry bell with a
lighter crown, a frilled skirt of sour-sugar crystals around the rim, two glaring eyes on the front, and
long trailing licorice tentacles that sting, banded red."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(bell="ff5aa0", bell2="ffb8d8", frill="ffe8f4", tent="2a0a1a", tent2="c81a5a", eye="ffffff", pupil="1a0410",
              sugar="fff4fa")
    C.plan, C.attack, C.hover = "hover", "dive", 0.45
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.62), (0, 0, 0.86), "root")
    C.bone("head", (0, 0, 0.86), (0, -0.05, 1.06), "hips")
    C.bone("tail1", (0, 0, 0.62), (0, 0.03, 0.36), "hips")
    C.bone("tail2", (0, 0.03, 0.36), (0, 0.06, 0.08), "tail1")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1", "tail2"]
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, 0, 0.82), (0.3, 0.3, 0.24), group="bell")
    cl.add((0, 0, 0.98), (0.16, 0.16, 0.1), group="bell2")
    for k in range(14):
        a = 2 * math.pi * k / 14
        cl.add((math.cos(a) * 0.29, math.sin(a) * 0.29, 0.62), (0.07, 0.07, 0.06), group="frill")
    body = cl.build({"bell": "bell", "bell2": "bell2", "frill": "frill"}, voxel=0.009, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.005})
    recolor(body, lambda p, n: smoothstep(0.85, 1.0, n.z) * 0.5, "sugar")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.08 * mx, -0.27, 0.8), (0.04, 0.02, 0.04), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", (0.08 * mx, -0.29, 0.79), (0.015, 0.012, 0.02), "pupil", "head")
    for k in range(8):
        a = 2 * math.pi * k / 8
        b = V((math.cos(a) * 0.18, math.sin(a) * 0.18, 0.6))
        pts = [b, b + V((math.cos(a) * 0.05, 0, -0.22)), b + V((-math.cos(a) * 0.03, 0.04, -0.42)), b + V((math.cos(a) * 0.04, 0.06, -0.6))]
        C.tube(f"Tentacle{k}", pts, [0.03, 0.024, 0.016, 0.004], "tent", None, allowed=["tail1", "tail2"])
        for j in range(3):
            C.ellipsoid(f"Band{k}{j}", tuple(V(pts[0]).lerp(V(pts[3]), 0.2 + 0.25 * j)), (0.03 - 0.006 * j,) * 2 + (0.012,),
                        "tent2", "tail1" if j < 2 else "tail2")
