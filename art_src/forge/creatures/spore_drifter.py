"""Spore Drifter (Mushroom Forest, 1): a drifting fungal jelly. Sculpted: a ragged, lumpy toxic cap like a
jellyfish bell with a scalloped rim, glowing gills underneath, a single slit eye glaring from the front,
and long barbed spore tendrils trailing below."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(cap="3b2a52", rim="6b3f8a", gill="9cff6a", eye="d4ff3a", pupil="10140c", tendril="4c3a5e", barb="b6ff5a")
    C.plan, C.attack, C.hover = "hover", "dive", 0.35
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.6), (0, 0, 0.82), "root")
    C.bone("head", (0, 0, 0.82), (0, -0.05, 1.0), "hips")
    C.bone("tail1", (0, 0, 0.6), (0, 0.03, 0.35), "hips")
    C.bone("tail2", (0, 0.03, 0.35), (0, 0.06, 0.1), "tail1")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1", "tail2"]
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, 0, 0.78), (0.3, 0.3, 0.2), group="cap")
    for k in range(10):                                                         # scalloped rim
        a = 2 * math.pi * k / 10
        cl.add((math.cos(a) * 0.28, math.sin(a) * 0.28, 0.64), (0.08, 0.08, 0.06), group="rim")
    cl.add((0, 0, 0.62), (0.24, 0.24, 0.06), group="gill")
    cl.add((0, -0.28, 0.78), (0.07, 0.03, 0.02), group="cap", neg=True)
    body = cl.build({"cap": "cap", "rim": "rim", "gill": "gill"}, voxel=0.009, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.02})
    recolor(body, lambda p, n: smoothstep(-0.3, -0.8, n.z), "gill")
    C.ellipsoid("Eye", (0, -0.285, 0.78), (0.06, 0.012, 0.022), "eye", "head")
    C.ellipsoid("Pupil", (0, -0.295, 0.78), (0.012, 0.008, 0.018), "pupil", "head")
    for k in range(6):
        a = 2 * math.pi * k / 6
        b = V((math.cos(a) * 0.16, math.sin(a) * 0.16, 0.6))
        pts = [b, b + V((math.cos(a) * 0.04, math.sin(a) * 0.04, -0.2)), b + V((-math.cos(a) * 0.02, 0.03, -0.38)),
               b + V((math.cos(a) * 0.03, 0.06, -0.54))]
        C.tube(f"Tendril{k}", pts, [0.025, 0.02, 0.014, 0.004], "tendril", None, allowed=["tail1", "tail2"])
        for j in range(2):
            C.ellipsoid(f"Barb{k}{j}", tuple(V(pts[j + 1]) + V((0, 0, 0.0))), (0.018,) * 3, "barb", "tail1" if j == 0 else "tail2")
