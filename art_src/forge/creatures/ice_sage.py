"""Ice Sage (Frost Peaks, 3): a small, stooped frost hermit. Sculpted: a bent little figure buried in a
heavy hooded fur cloak with a thick white fur trim, a long beard frozen into icicles spilling from the
hood, two pale glints in the shadow, and a lantern of blue ice hung from a crooked staff."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(cloak="3a5a8a", fur="eef4fa", dark="0a1420", eye="aef8ff", beard="e8f4ff", ice="9ee8ff", wood="5a4030",
              lamp="cff8ff", trim="b8c8d8")
    C.plan, C.attack, C.hover = "hover", "cast", 0.12
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.04, 0.6), (0, -0.02, 0.86), "root")
    C.bone("chest", (0, -0.02, 0.86), (0, -0.1, 1.04), "hips")
    C.bone("neck", (0, -0.1, 1.04), (0, -0.16, 1.1), "chest")
    C.bone("head", (0, -0.16, 1.1), (0, -0.2, 1.3), "neck")
    C.bone("tail1", (0, 0.04, 0.6), (0, 0.08, 0.32), "hips")
    C.bone("tail2", (0, 0.08, 0.32), (0, 0.12, 0.06), "tail1")
    C.spine, C.neck, C.head, C.tail = ["hips", "chest"], ["neck"], "head", ["tail1", "tail2"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.2 * sx, -0.06, 1.0), (0.3 * sx, -0.14, 0.82), "chest")
        C.bone(f"forearm.{side}", (0.3 * sx, -0.14, 0.82), (0.34 * sx, -0.3, 0.74), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    cl = Clay(C, "Body", res=0.018)
    cl.add((0, -0.04, 0.9), (0.22, 0.2, 0.2), rot=(-20, 0, 0), group="cloak")       # hunched back
    cl.chain([(0, 0.0, 0.76), (0, 0.04, 0.4), (0, 0.08, 0.08)], [(0.24, 0.22, 0.2), (0.3, 0.28, 0.2),
                                                                   (0.34, 0.32, 0.08)], group="cloak")
    for k in range(9):
        a = 2 * math.pi * k / 9
        cl.add((math.cos(a) * 0.28, 0.06 + math.sin(a) * 0.25, 0.3), (0.045, 0.045, 0.2), rot=(0, 0, math.degrees(a)),
               group="cloak")
    for k in range(12):                                                         # fur trim at the hem
        a = 2 * math.pi * k / 12
        cl.add((math.cos(a) * 0.33, 0.08 + math.sin(a) * 0.31, 0.08), (0.07, 0.07, 0.06), group="fur")
    for sx in (-1, 1):
        cl.chain([(0.2 * sx, -0.06, 1.0), (0.3 * sx, -0.14, 0.82), (0.34 * sx, -0.28, 0.76)],
                 [0.07, 0.07, (0.1, 0.1, 0.07)], group="cloak")
        cl.add((0.34 * sx, -0.3, 0.75), (0.08, 0.04, 0.06), group="fur")          # fur cuffs
    cl.add((0, -0.14, 1.16), (0.16, 0.17, 0.17), group="cloak")                    # hood
    cl.add((0, -0.24, 1.12), (0.12, 0.1, 0.13), group="dark", neg=True)
    cl.add((0, -0.14, 1.12), (0.1, 0.1, 0.11), group="dark")
    for k in range(9):                                                         # fur trim around the hood
        a = 2 * math.pi * k / 9
        cl.add((math.cos(a) * 0.13, -0.27, 1.13 + math.sin(a) * 0.14), (0.05, 0.04, 0.05), group="fur")
    body = cl.build({"cloak": "cloak", "fur": "fur", "dark": "dark"}, voxel=0.009, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(0.5, 1.0, n.z) * 0.4 * (1.0 if p.z > 0.5 else 0.0), "trim")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, -0.235, 1.14), (0.016, 0.008, 0.01), "eye", "head")
    for k in range(6):
        x = -0.06 + 0.024 * k
        C.cone(f"Beard{k}", (x, -0.24, 1.07), (x * 0.6, -0.27, 0.86 - 0.06 * (k % 3)), 0.028, "beard", "head", segs=5)
    hr = V((0.35, -0.33, 0.74))
    C.tube("Staff", [hr + V((0, 0.04, -0.7)), hr, hr + V((0.04, -0.04, 0.4)), hr + V((0.14, -0.06, 0.52)),
                     hr + V((0.2, -0.06, 0.44))], [0.022, 0.022, 0.02, 0.016, 0.012], "wood", "forearm.R")
    C.tube("Chain", [hr + V((0.2, -0.06, 0.44)), hr + V((0.2, -0.06, 0.34))], [0.006, 0.006], "trim", "forearm.R")
    C.ellipsoid("Lantern", tuple(hr + V((0.2, -0.06, 0.27))), (0.06, 0.06, 0.08), "lamp", "forearm.R")
    for k in range(4):
        a = 2 * math.pi * k / 4
        C.cone(f"LampSpike{k}", tuple(hr + V((0.2, -0.06, 0.27))),
               tuple(hr + V((0.2 + math.cos(a) * 0.09, -0.06 + math.sin(a) * 0.09, 0.2))), 0.02, "ice", "forearm.R", segs=4)
