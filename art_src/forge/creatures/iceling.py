"""Iceling (Frost Peaks, 2): a small fierce elemental grown from shards of blue ice. Sculpted: a squat,
wide-shouldered little brute of faceted ice with long arms, a hunched faceted head with glowing white eyes
under a jagged brow, crystal shards for shoulders and a crown, and claws of clear ice."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep, cracks


def build(C):
    C.palette(ice="5aa8e8", ice2="aee8ff", clear="e8faff", eye="ffffff", dark="0a2a4a")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.42, chest=0.76, head=0.98, lean=0.12, shoulder_x=0.26, hip_x=0.12,
                          r_chest=(0.24, 0.18, 0.2), r_waist=(0.15, 0.12, 0.12), r_hips=(0.16, 0.12, 0.1),
                          r_head=(0.13, 0.13, 0.12), r_arm=(0.08, 0.07), r_hand=0.08, r_leg=(0.09, 0.07),
                          r_foot=(0.07, 0.09, 0.05), arm_len=0.52, group="ice")
    h = at["head"]
    cl.add((0, h.y - 0.1, h.z + 0.05), (0.12, 0.05, 0.035), rot=(-10, 0, 0), group="dark")
    cl.mirror((0.05, h.y - 0.11, h.z + 0.0), (0.03, 0.025, 0.02), group="ice", neg=True)
    body = cl.build({"ice": "ice", "dark": "ice"}, voxel=0.009, budget=8000, relax=1,
                    texture={"type": 'VORONOI', "scale": 0.06, "strength": 0.025})
    recolor(body, lambda p, n: cracks(p, 0.08, 0.06, seed=43) * 0.8, "clear")
    recolor(body, lambda p, n: smoothstep(0.5, 1.0, n.z) * 0.5, "ice2")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.05 * mx, h.y - 0.125, h.z), (0.025, 0.01, 0.014), "eye", "head", rot=(0, -15 * mx, 0))
        side = "L" if mx < 0 else "R"
        sh = at["sh" + side]
        for k in range(3):
            a = math.radians(-30 + 30 * k)
            C.cone(f"Shoulder{side}{k}", tuple(sh), tuple(sh + V((0.12 * mx + math.sin(a) * 0.08 * mx, math.sin(a) * 0.1, 0.22 - 0.04 * k))),
                   0.05, "ice2", f"arm.{side}", segs=4)
        hd = at["hd" + side]
        for k in (-1, 0, 1):
            C.cone(f"Claw{side}{k}", tuple(hd + V((0.03 * k, -0.04, -0.06))), tuple(hd + V((0.04 * k, -0.1, -0.18))), 0.018,
                   "clear", f"forearm.{side}", segs=4)
    for k in range(5):
        a = math.pi * (0.15 + 0.7 * k / 4)
        b = h + V((math.cos(a) * 0.09, 0.02 - math.sin(a) * 0.04, 0.08))
        C.cone(f"Crown{k}", tuple(b), tuple(b + V((math.cos(a) * 0.05, 0.02, 0.12 + 0.06 * (k == 2)))), 0.03, "clear", "head",
               segs=4)
