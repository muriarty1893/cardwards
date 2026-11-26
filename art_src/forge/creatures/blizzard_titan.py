"""Blizzard Titan (Frost Peaks, 7): a towering storm-yeti, shaggy blue-white fur, a glacier grown over its
shoulders and back in jagged crystal plates, a long icicle beard, eyes like pale stars and a club of solid
glacier ice dragged behind it."""
import math
import random
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(fur="dfe8f2", fur2="a8bcd0", skin="5a7a9a", ice="7ad8ff", ice2="cff4ff", eye="ffffff", dark="0a1a2a",
              horn="c8d8e8")
    C.attack = "slam"
    kits.biped(C, "fur", hip=0.85, chest=1.4, neck=1.58, head_top=1.85, shoulder_x=0.5, hip_x=0.22,
               hand=(0.68, -0.2, 0.4), r_hip=0.34, r_waist=0.36, r_chest=0.5, r_neck=0.2, r_head=0.2,
               r_arm=0.15, r_hand=0.14, r_leg=0.16, r_foot=0.16, lean=0.26, elbow_back=0.06)
    h = V(C.anch["head"])
    rnd = random.Random(9)
    C.ellipsoid("Face", tuple(h + V((0, -0.14, -0.02))), (0.14, 0.08, 0.13), "skin", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.06 * mx, -0.21, 0.03))), (0.03, 0.012, 0.018), "eye", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.07 * mx, -0.2, 0.08))), (0.1, 0.05, 0.04), "fur", "head", rot=(0, 25 * mx, 0),
              bevel=0.5)
        C.tube(f"Horn{mx}", [h + V((0.14 * mx, 0, 0.1)), h + V((0.3 * mx, 0.06, 0.12)), h + V((0.36 * mx, -0.04, 0.3))],
               [0.06, 0.04, 0.005], "horn", "head")
    for k in range(5):
        x = -0.08 + 0.04 * k
        C.cone(f"Beard{k}", tuple(h + V((x, -0.18, -0.1))), tuple(h + V((x * 1.2, -0.2, -0.4 + 0.08 * abs(k - 2)))), 0.035,
               "ice2", "head", segs=4)
    # shaggy fur clumps
    for k in range(14):
        x, z = rnd.uniform(-0.45, 0.45), rnd.uniform(0.8, 1.5)
        C.decal(f"Shag{k}", x, z, (0.1, 0.12, 0.05), "fur2", "chest", dir=(0, 1 if k % 2 else -1, 0), spin=rnd.uniform(-20, 20))
    # glacier over shoulders and back
    c = V(C.anch["chest"])
    for k in range(9):
        a = math.pi * (0.1 + 0.8 * k / 8)
        b = c + V((math.cos(a) * 0.42, 0.12 + math.sin(a) * 0.05, 0.22))
        C.cone(f"Glacier{k}", tuple(b), tuple(b + V((math.cos(a) * 0.15, 0.12, 0.3 + 0.15 * (k % 2)))), 0.1,
               "ice" if k % 2 else "ice2", "chest", segs=5)
    for side, mx in (("L", -1), ("R", 1)):
        sh = V(C.anch["sh" + side])
        C.cone(f"ShoulderIce{side}", tuple(sh + V((0.05 * mx, 0, 0.1))), tuple(sh + V((0.2 * mx, 0.05, 0.42))), 0.11, "ice",
               f"arm.{side}", segs=5)
    # glacier club in the right hand
    hd = V(C.anch["hdR"])
    C.tube("Grip", [hd + V((0, 0, 0.12)), hd, hd + V((0, 0.05, -0.2))], [0.05, 0.05, 0.06], "ice", "forearm.R")
    C.cone("Club", tuple(hd + V((0, 0.05, -0.15))), tuple(hd + V((0, 0.12, -0.42))), 0.2, "ice2", "forearm.R", segs=6)
    C.ellipsoid("FistL", C.anch["hdL"], (0.17, 0.17, 0.15), "skin", "forearm.L")
