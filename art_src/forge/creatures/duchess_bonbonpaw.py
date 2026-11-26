"""Duchess Bonbonpaw (Candy Hills, 7, legend): an aristocratic cat noblewoman gliding across the ballroom.
Sculpted: a slender cat in a corseted gown whose skirt cascades in tiers of chocolate and pink ruffles, a
high lace collar, a proud feline head with full cheeks, a ginger patch over one eye and haughty
half-lidded eyes, a towering powdered wig of whipped cream topped with a cherry, a lace fan in one paw,
a box of bonbons in the other and a ringed tail curling from under the hem."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fur="f4e6d6", patch="d8843a", choc="5a2a18", cherry="e8102a", eye="3ad87a", dark="1a0a10",
              gold="ffd23a", nose="ff7aa0", fan="f8f0ff", pupil="0a1a0a")
    C.plan, C.attack, C.hover = "hover", "swipe", 0.12
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.02, 0.86), (0, 0.0, 1.1), "root")
    C.bone("chest", (0, 0.0, 1.1), (0, -0.02, 1.32), "hips")
    C.bone("neck", (0, -0.02, 1.32), (0, -0.03, 1.42), "chest")
    C.bone("head", (0, -0.03, 1.42), (0, -0.03, 1.72), "neck")
    C.bone("tail1", (0, 0.02, 0.86), (0, 0.06, 0.5), "hips")
    C.bone("tail2", (0, 0.06, 0.5), (0, 0.1, 0.12), "tail1")
    C.spine, C.neck, C.head, C.tail = ["hips", "chest"], ["neck"], "head", ["tail1", "tail2"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.18 * sx, 0.0, 1.3), (0.32 * sx, -0.02, 1.08), "chest")
        C.bone(f"forearm.{side}", (0.32 * sx, -0.02, 1.08), (0.4 * sx, -0.16, 0.92), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    C.bone("ctail1", (0, 0.36, 0.3), (0.06, 0.6, 0.5), "tail2")
    C.bone("ctail2", (0.06, 0.6, 0.5), (0.02, 0.62, 0.9), "ctail1")

    # ---- sculpted body: corseted gown with tiered ruffles
    cl = Clay(C, "Body", res=0.022)
    cl.add((0, 0.0, 1.2), (0.15, 0.12, 0.13), group="gown")                    # bodice
    cl.add((0, 0.0, 1.02), (0.1, 0.085, 0.1), group="gown")                    # corseted waist
    cl.mirror((0.14, 0.0, 1.3), (0.06, 0.06, 0.05), group="fur")               # shoulders
    cl.chain([(0, 0.02, 0.94), (0, 0.04, 0.6), (0, 0.06, 0.28), (0, 0.08, 0.06)],
             [(0.2, 0.18, 0.12), (0.32, 0.3, 0.2), (0.44, 0.4, 0.2), (0.5, 0.46, 0.06)], group="gown")
    for t, (z, r, g) in enumerate([(0.74, 0.3, "choc"), (0.48, 0.4, "ruffle"), (0.2, 0.5, "choc"),
                                   (0.06, 0.54, "ruffle")]):
        n = 14 + 4 * t
        for k in range(n):                                                     # scalloped ruffle tiers
            a = 2 * math.pi * k / n
            cl.add((math.cos(a) * r, 0.05 + math.sin(a) * r * 0.92, z), (0.075, 0.075, 0.05), group=g)
    for k in range(10):                                                        # lace collar
        a = 2 * math.pi * k / 10
        cl.add((math.cos(a) * 0.13, math.sin(a) * 0.11, 1.34), (0.06, 0.06, 0.04), rot=(0, 0, math.degrees(a)),
               group="lace")
    for sx in (-1, 1):
        cl.chain([(0.18 * sx, 0.0, 1.3), (0.32 * sx, -0.02, 1.08)], [(0.075, 0.075, 0.07), 0.045], group="gown")
        cl.chain([(0.32 * sx, -0.02, 1.08), (0.4 * sx, -0.16, 0.92)], [0.04, 0.035], group="fur")
        cl.add((0.41 * sx, -0.18, 0.9), (0.045, 0.045, 0.04), group="fur")    # paw
        cl.add((0.32 * sx, -0.03, 1.06), (0.07, 0.07, 0.04), group="lace")     # lace cuff
    # cat head: round skull, full cheeks, little muzzle, ears
    cl.add((0, -0.04, 1.54), (0.17, 0.15, 0.14), group="fur")
    cl.mirror((0.09, -0.1, 1.48), (0.09, 0.08, 0.07), group="fur")             # cheeks
    cl.mirror((0.03, -0.17, 1.47), (0.04, 0.035, 0.03), group="fur")          # whisker pads
    cl.add((0, -0.15, 1.44), (0.035, 0.03, 0.025), group="fur")                # chin
    cl.mirror((0.065, -0.16, 1.55), (0.035, 0.025, 0.022), group="fur", neg=True)    # eye sockets
    for sx in (-1, 1):
        cl.chain([(0.13 * sx, -0.06, 1.62), (0.21 * sx, -0.06, 1.73), (0.25 * sx, -0.06, 1.8)],
                 [(0.065, 0.03, 0.06), (0.05, 0.025, 0.05), (0.012, 0.012, 0.015)], group="patch" if sx > 0 else "fur")
    # towering whipped-cream wig
    for k, (x, y, z, s) in enumerate([(0, 0.1, 1.68, 0.16), (0.09, 0.12, 1.77, 0.11), (-0.09, 0.12, 1.77, 0.11),
                                      (0, 0.12, 1.84, 0.13), (0.06, 0.12, 1.96, 0.1), (-0.05, 0.12, 1.98, 0.1),
                                      (0, 0.12, 2.08, 0.09), (0, 0.12, 2.18, 0.06)]):
        cl.add((x, y, z), (s, s, s * 0.8), group="cream")
    body = cl.build({"gown": "7a2a4a", "choc": "5a2a18", "ruffle": "ffb0d0", "lace": "fff8f0", "fur": "f4e6d6",
                     "patch": "d8843a", "cream": "fff8f0"}, voxel=0.011, budget=12000, relax=3,
                    texture={"type": 'CLOUDS', "scale": 0.05, "strength": 0.006})
    # ginger patch over the right eye, gold lacing on the corset
    recolor(body, lambda p, n: smoothstep(0.1, 0.06, (p - V((0.08, -0.12, 1.57))).length), "d8843a")
    recolor(body, lambda p, n: (1.0 if p.y < -0.06 and 0.95 < p.z < 1.28 and abs(abs(p.x) - 0.03 - 0.02 * math.sin(p.z * 60))
                                < 0.012 else 0.0), "ffd23a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.065 * mx, -0.172, 1.555), (0.035, 0.014, 0.022), "eye", "head", rot=(0, 15 * mx, 0))
        C.ellipsoid(f"Pupil{mx}", (0.065 * mx, -0.185, 1.555), (0.006, 0.006, 0.018), "pupil", "head")
        C.ellipsoid(f"Lid{mx}", (0.065 * mx, -0.17, 1.575), (0.042, 0.022, 0.016), "patch" if mx > 0 else "fur", "head",
                    rot=(0, 15 * mx, 0))
        for k in (-1, 1):
            C.tube(f"Whisker{mx}{k}", [V((0.05 * mx, -0.2, 1.47 + 0.012 * k)), V((0.24 * mx, -0.14, 1.48 + 0.04 * k))],
                   [0.004, 0.002], "dark", "head")
    C.ellipsoid("Nose", (0, -0.2, 1.5), (0.022, 0.012, 0.015), "nose", "head")
    C.ellipsoid("Cherry", (0, 0.12, 2.27), (0.05, 0.05, 0.05), "cherry", "head")
    C.tube("CherryStem", [V((0, 0.12, 2.31)), V((0.03, 0.14, 2.41))], [0.008, 0.006], "choc", "head")
    hr = V((0.41, -0.2, 0.92))
    pts = [tuple(hr)] + [tuple(hr + V((math.cos(a) * 0.28, -0.05, math.sin(a) * 0.28)))
                         for a in [math.radians(d) for d in (20, 45, 70, 95, 120, 145)]]
    C.membrane("Fan", pts, "fan", "forearm.R", thick=0.01)
    for k in range(6):
        a = math.radians(20 + 25 * k)
        C.tube(f"FanRib{k}", [hr, hr + V((math.cos(a) * 0.28, -0.055, math.sin(a) * 0.28))], [0.006, 0.004], "gold",
               "forearm.R")
    hl = V((-0.41, -0.2, 0.92))
    C.box("Box", tuple(hl + V((0, -0.08, 0.04))), (0.22, 0.16, 0.06), "gold", "forearm.L", bevel=0.3)
    for k in range(3):
        C.ellipsoid(f"Bonbon{k}", tuple(hl + V((-0.06 + 0.06 * k, -0.08, 0.09))), (0.03, 0.03, 0.025), "choc",
                    "forearm.L")
    tl = [V((0, 0.36, 0.3)), V((0.06, 0.6, 0.5)), V((0.02, 0.62, 0.9)), V((-0.05, 0.54, 1.02))]
    C.tube("Tail", tl, [0.05, 0.045, 0.04, 0.03], "fur", None, allowed=["ctail1", "ctail2"])
    for k in range(4):
        C.ellipsoid(f"TailRing{k}", tuple(tl[1].lerp(tl[2], 0.2 * k) if k < 4 else tl[2]), (0.05, 0.05, 0.025),
                    "patch", "ctail2" if k > 1 else "ctail1")
