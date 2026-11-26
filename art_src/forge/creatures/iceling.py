"""Iceling (Frost Peaks, 2): a small fierce elemental grown from shards of blue ice, jagged crystals for
shoulders and a crown, glowing white eyes in a faceted head and claws of clear ice."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(ice="5aa8e8", ice2="aee8ff", clear="e8faff", eye="ffffff", dark="0a2a4a")
    C.attack = "swipe"
    C.relax = 0.0
    kits.biped(C, "ice", hip=0.45, chest=0.72, neck=0.84, head_top=1.04, shoulder_x=0.18, hip_x=0.09,
               hand=(0.3, -0.1, 0.42), r_hip=0.13, r_waist=0.11, r_chest=0.17, r_neck=0.06, r_head=0.13,
               r_arm=0.05, r_hand=0.05, r_leg=0.06, r_foot=0.065, subdiv=1)
    h = V(C.anch["head"])
    C.ellipsoid("Facet", tuple(h + V((0, -0.06, 0))), (0.13, 0.1, 0.13), "ice2", "head", segs=6, rings=4, smooth=False)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.15, 0.01))), (0.03, 0.012, 0.016), "eye", "head",
                    rot=(0, -20 * mx, 0))
        sh = V(C.anch["shL" if mx < 0 else "shR"])
        for k in range(3):
            C.cone(f"Shoulder{mx}{k}", tuple(sh), tuple(sh + V((0.12 * mx * (k + 1) * 0.6, 0.04 * k, 0.18 - 0.03 * k))), 0.05,
                   "clear", "arm.L" if mx < 0 else "arm.R", segs=4)
        hd = V(C.anch["hdL" if mx < 0 else "hdR"])
        for k in range(3):
            C.cone(f"Claw{mx}{k}", tuple(hd), tuple(hd + V((0.035 * (k - 1), -0.08, -0.1))), 0.018, "clear",
                   "forearm.L" if mx < 0 else "forearm.R", segs=4)
    for k in range(5):
        a = math.pi * (0.15 + 0.7 * k / 4)
        C.cone(f"Crown{k}", tuple(h + V((math.cos(a) * 0.1, 0.02, 0.08))),
               tuple(h + V((math.cos(a) * 0.16, 0.04, 0.24 + 0.06 * (k == 2)))), 0.035, "clear", "head", segs=4)
    c = V(C.anch["chest"])
    for k in range(4):
        C.cone(f"Back{k}", tuple(c + V((0.08 * (k - 1.5), 0.12, 0.0))), tuple(c + V((0.12 * (k - 1.5), 0.3, 0.12))), 0.04,
               "ice2", "chest", segs=4)
