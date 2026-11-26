"""Glacial Archmage (Frost Peaks, 7, legend): a towering ice sorcerer drifting above the snow. Sculpted: broad
shoulders under layered frost robes with deep folds that freeze into icicles at the hem, wide sleeves, a
deep hood around a face of darkness with two cold lights, a crown of jagged ice spires, crystal pauldrons,
a ring of orbiting ice shards and a crystal staff."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(trim="cfe8ff", dark="03060c", eye="aef8ff", ice="9ee8ff", ice2="e8faff", silver="b8c8d8",
              wood="2a3a4a", frost="d8f4ff")
    C.plan, C.attack, C.hover = "hover", "cast", 0.3
    # ---- skeleton
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.02, 1.02), (0, 0.0, 1.36), "root")
    C.bone("chest", (0, 0.0, 1.36), (0, -0.04, 1.68), "hips")
    C.bone("neck", (0, -0.04, 1.68), (0, -0.06, 1.8), "chest")
    C.bone("head", (0, -0.06, 1.8), (0, -0.06, 2.1), "neck")
    C.bone("tail1", (0, 0.02, 1.02), (0, 0.08, 0.6), "hips")
    C.bone("tail2", (0, 0.08, 0.6), (0, 0.16, 0.18), "tail1")
    C.spine, C.neck, C.head, C.tail = ["hips", "chest"], ["neck"], "head", ["tail1", "tail2"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.36 * sx, 0.0, 1.66), (0.52 * sx, -0.04, 1.36), "chest")
        C.bone(f"forearm.{side}", (0.52 * sx, -0.04, 1.36), (0.56 * sx, -0.22, 1.12), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.026)
    cl.add((0, 0.0, 1.5), (0.27, 0.18, 0.24), group="robe")                    # broad chest
    cl.mirror((0.3, 0.0, 1.64), (0.13, 0.14, 0.11), group="robe")              # shoulders
    cl.add((0, 0.02, 1.24), (0.19, 0.15, 0.14), group="robe")                  # waist
    cl.chain([(0, 0.02, 1.16), (0, 0.06, 0.8), (0, 0.1, 0.46), (0, 0.16, 0.16)],
             [(0.22, 0.18, 0.2), (0.3, 0.25, 0.2), (0.38, 0.32, 0.2), (0.46, 0.4, 0.12)], group="robe")
    for k in range(12):                                                        # folds
        a = 2 * math.pi * k / 12
        for j, (z, r) in enumerate([(0.98, 0.23), (0.66, 0.31), (0.34, 0.4)]):
            cl.add((math.cos(a) * r, 0.08 + 0.05 * j + math.sin(a) * r * 0.85, z), (0.05, 0.05, 0.2),
                   rot=(0, 0, math.degrees(a)), group="robe")
    # overrobe panel down the front, slightly paler
    cl.add((0, -0.2, 1.0), (0.14, 0.06, 0.36), rot=(-8, 0, 0), group="panel")
    cl.add((0, -0.28, 0.5), (0.18, 0.06, 0.28), rot=(-12, 0, 0), group="panel")
    # frost collar standing up behind the head
    for k in range(7):
        a = math.pi * (0.1 + 0.8 * k / 6)
        cl.add((math.cos(a) * 0.23, 0.08 + math.sin(a) * 0.06, 1.86), (0.06, 0.03, 0.2),
               rot=(-18, -math.degrees(math.cos(a)) * 0.6, 0), group="frost")
    for sx in (-1, 1):                                                         # wide sleeves
        cl.chain([(0.36 * sx, 0.0, 1.64), (0.52 * sx, -0.04, 1.36), (0.56 * sx, -0.18, 1.16)],
                 [0.09, 0.09, (0.15, 0.15, 0.09)], group="robe")
        cl.add((0.57 * sx, -0.2, 1.13), (0.09, 0.09, 0.07), group="robe", neg=True)
        cl.add((0.57 * sx, -0.22, 1.1), (0.045, 0.05, 0.05), group="frost")             # hand
    cl.add((0, 0.02, 1.92), (0.2, 0.2, 0.22), group="robe")                    # hood
    cl.add((0, 0.06, 2.12), (0.08, 0.1, 0.1), rot=(-30, 0, 0), group="robe")   # hood peak
    cl.add((0, -0.14, 1.9), (0.15, 0.12, 0.17), group="void", neg=True)        # hood opening
    cl.add((0, -0.02, 1.9), (0.13, 0.13, 0.15), group="void")                  # the darkness within
    body = cl.build({"robe": "1e3a6a", "panel": "2a5a9a", "frost": "cfe8ff", "void": "03060c"}, voxel=0.013,
                    budget=12000, relax=3, texture={"type": 'CLOUDS', "scale": 0.08, "strength": 0.008})
    # frost creeping up from the hem in fractured ice, silver embroidery on the panel
    recolor(body, lambda p, n: smoothstep(0.55, 0.15, p.z) * 0.85, "b8e4ff")
    recolor(body, lambda p, n: cracks(p, 0.09, 0.05, seed=5) * smoothstep(0.75, 0.35, p.z), "f0fbff")
    recolor(body, lambda p, n: (1.0 if abs(abs(p.x) - 0.12) < 0.022 and p.y < -0.18 and p.z < 1.3 else 0.0),
            "d8e8f8")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.055 * mx, -0.15, 1.92), (0.03, 0.012, 0.018), "eye", "head", rot=(0, -12 * mx, 0))
    for k in range(5):                                                         # crown of ice spires
        a = math.pi * (0.15 + 0.7 * k / 4)
        b = V((math.cos(a) * 0.16, -0.02 - math.sin(a) * 0.08, 2.08))
        C.cone(f"Spire{k}", tuple(b), tuple(b + V((math.cos(a) * 0.1, 0.02, 0.26 + 0.14 * (k == 2)))), 0.05, "ice",
               "head", segs=5)
    C.ellipsoid("Circlet", (0, -0.03, 2.06), (0.19, 0.17, 0.03), "silver", "head")
    for side, mx in (("L", -1), ("R", 1)):                                     # crystal pauldrons
        for k in range(3):
            b = V((0.3 * mx + 0.05 * mx * k, 0.02 - 0.06 * (k - 1), 1.7))
            C.cone(f"PSpike{side}{k}", tuple(b), tuple(b + V((0.12 * mx, 0.02 * (k - 1), 0.24 - 0.05 * abs(k - 1)))),
                   0.055, "ice", f"arm.{side}", segs=5)
        C.ellipsoid(f"Pauldron{side}", (0.34 * mx, 0.0, 1.69), (0.14, 0.15, 0.07), "silver", f"arm.{side}",
                    rot=(0, -20 * mx, 0))
    for k in range(14):                                                        # icicles hanging from the hem
        a = 2 * math.pi * k / 14
        top = V((math.cos(a) * 0.44, 0.16 + math.sin(a) * 0.38, 0.1))
        C.cone(f"Icicle{k}", tuple(top), tuple(top + V((0, 0, -0.12 - 0.07 * (k % 3)))), 0.035, "ice2", "tail2",
               segs=4)
    C.bone("orbit", (0, 0, 1.15), (0, 0, 1.4), "root")
    for k in range(5):
        a = 2 * math.pi * k / 5
        p = V((math.cos(a) * 0.66, math.sin(a) * 0.62, 1.2 + 0.12 * math.sin(3 * a)))
        C.cone(f"Shard{k}", tuple(p - V((0, 0, 0.13))), tuple(p + V((0, 0, 0.15))), 0.06, "ice2", "orbit", segs=4)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 72 * t))
    props.staff(C, (0.57, -0.23, 1.1), "wood", "forearm.R", length=1.9, up=1.0, top="crystal", m_top="ice",
                top_r=0.12)
    hl = V((-0.57, -0.23, 1.1))
    for k in range(5):
        a = 2 * math.pi * k / 5
        C.cone(f"Frost{k}", tuple(hl + V((0, -0.1, 0.1))),
               tuple(hl + V((math.cos(a) * 0.13, -0.1, 0.1 + math.sin(a) * 0.13))), 0.025, "ice2", "forearm.L", segs=4)
