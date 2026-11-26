"""Bonbon Behemoth (Candy Hills, 6): a hulking chocolate rabbit brute. Sculpted: a hunched, muscular
chocolate rabbit with a huge chest and thick arms, its hollow shell cracked open on one side to show the
cream filling, gold and red foil wrapped over its shoulders like armour plates, long ears notched from
fights, an angry little face and fists studded with nut clusters."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep, cracks


def build(C):
    C.palette(choc="5a2a14", choc2="7a3a1a", cream="fff0d8", foil="ffcf3a", foil2="c81a3a", eye="ff3a7a", dark="1a0804",
              bonbon="3a1408", nut="c8904a")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.7, chest=1.16, head=1.42, lean=0.18, shoulder_x=0.38, hip_x=0.2,
                          r_chest=(0.36, 0.28, 0.3), r_waist=(0.3, 0.24, 0.2), r_hips=(0.28, 0.24, 0.18),
                          r_head=(0.16, 0.16, 0.15), r_arm=(0.13, 0.12), r_hand=0.12, r_leg=(0.15, 0.11),
                          r_foot=(0.11, 0.18, 0.07), arm_len=0.72, group="choc")
    h = at["head"]
    for sx in (-1, 1):
        cl.chain([(0.07 * sx, h.y + 0.02, h.z + 0.12), (0.12 * sx, h.y + 0.04, h.z + 0.34), (0.14 * sx, h.y + 0.06, h.z + 0.52)],
                 [(0.06, 0.03, 0.06), (0.065, 0.03, 0.06), (0.03, 0.02, 0.03)], group="choc")      # long ears
        cl.add((0.07 * sx, h.y - 0.1, h.z + 0.05), (0.06, 0.04, 0.025), rot=(0, 0, -20 * sx), group="choc2")
        cl.add((0.065 * sx, h.y - 0.12, h.z + 0.02), (0.025, 0.02, 0.02), group="choc", neg=True)
    cl.add((0.14, h.y + 0.04, h.z + 0.44), (0.03, 0.04, 0.04), group="choc", neg=True)                # notch
    cl.add((0, h.y - 0.13, h.z - 0.05), (0.07, 0.06, 0.05), group="choc2")                           # muzzle
    cl.add((0.18, -0.34, 1.0), (0.14, 0.1, 0.14), group="cream", neg=True)                           # cracked open
    cl.add((0.17, -0.22, 1.0), (0.12, 0.06, 0.12), group="cream")
    body = cl.build({"choc": "choc", "choc2": "choc2", "cream": "cream"}, voxel=0.014, budget=10000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(0.7, 1.0, n.z) * 0.35, "choc2")
    recolor(body, lambda p, n: cracks(p, 0.08, 0.06, seed=71) * smoothstep(0.2, 0.0, (p - V((0.18, -0.3, 1.0))).length),
            "cream")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.065 * mx, h.y - 0.14, h.z + 0.02), (0.022, 0.01, 0.016), "eye", "head")
        side = "L" if mx < 0 else "R"
        sh = at["sh" + side]
        for k in range(3):
            C.ellipsoid(f"Foil{side}{k}", tuple(sh + V((0.04 * mx, -0.02 + 0.06 * k, 0.12 - 0.07 * k))),
                        (0.17 - 0.02 * k, 0.15, 0.06), "foil" if k % 2 == 0 else "foil2", f"arm.{side}", rot=(0, -25 * mx, 0))
        hd = at["hd" + side]
        for k in range(4):
            a = 2 * math.pi * k / 4
            C.ellipsoid(f"Nut{side}{k}", tuple(hd + V((math.cos(a) * 0.1, -0.08, math.sin(a) * 0.08 - 0.05))), (0.035,) * 3,
                        "nut", f"forearm.{side}")
    C.cone("Tooth", (0, h.y - 0.17, h.z - 0.07), (0, h.y - 0.18, h.z - 0.13), 0.03, "cream", "head", segs=4)
