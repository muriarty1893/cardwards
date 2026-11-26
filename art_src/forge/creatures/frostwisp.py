"""Frostwisp (Frost Peaks, 2): a drifting spirit of the blizzard. Sculpted: a faceted core of blue ice
crystal with two cold slit eyes, wrapped in swirling streamers of snow that spiral down into a tail of
mist, with frost crystals orbiting it."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(ice="7ad8ff", ice2="e0faff", core="ffffff", mist="cfeaff", eye="0a2a4a", crystal="aef4ff")
    C.plan, C.attack, C.hover = "hover", "cast", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.5), (0, 0, 0.8), "root")
    C.bone("head", (0, 0, 0.8), (0, 0, 1.1), "hips")
    C.bone("tail1", (0, 0, 0.5), (0.05, 0.05, 0.25), "hips")
    C.bone("tail2", (0.05, 0.05, 0.25), (-0.04, 0.08, 0.05), "tail1")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1", "tail2"]
    cl = Clay(C, "Body", res=0.018)
    for k in range(18):                                                         # spiral streamers
        t = k / 17
        a = t * 4 * math.pi
        r = 0.28 * (1 - t * 0.7)
        cl.add((math.cos(a) * r, math.sin(a) * r, 0.95 - 0.85 * t), (0.08 - 0.03 * t, 0.08 - 0.03 * t, 0.05),
               rot=(0, 0, math.degrees(a)), group="mist")
    cl.add((0, 0, 0.82), (0.17, 0.17, 0.2), group="ice")                         # crystal core
    cl.mirror((0.06, -0.15, 0.86), (0.04, 0.03, 0.012), rot=(0, 0, -20), group="ice", neg=True)
    body = cl.build({"mist": "mist", "ice": "ice"}, voxel=0.01, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.5, 0.1, p.z) * 0.6, "ice2")
    for k in range(5):                                                          # facets on the core
        a = 2 * math.pi * k / 5
        C.cone(f"Facet{k}", (math.cos(a) * 0.08, math.sin(a) * 0.08, 0.86), (math.cos(a) * 0.22, math.sin(a) * 0.2, 1.08),
               0.05, "crystal", "head", segs=4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, -0.165, 0.86), (0.035, 0.01, 0.01), "eye", "head", rot=(0, 20 * mx, 0))
    C.bone("orbit", (0, 0, 0.7), (0, 0, 0.9), "root")
    for k in range(5):
        a = 2 * math.pi * k / 5
        p = V((math.cos(a) * 0.42, math.sin(a) * 0.42, 0.7 + 0.1 * math.sin(3 * a)))
        C.cone(f"Shard{k}", tuple(p - V((0, 0, 0.07))), tuple(p + V((0, 0, 0.09))), 0.04, "ice2", "orbit", segs=4)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 72 * t))
