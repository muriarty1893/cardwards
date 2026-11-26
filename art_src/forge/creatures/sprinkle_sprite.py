"""Sprinkle Sprite (Candy Hills, 1): a mischievous sugar imp. Sculpted: a small wiry imp with a big head,
long pointed ears, a sharp wicked grin and a tuft of violet hair, wings of spun sugar, and a candy-cane
wand that flings sprinkles."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(skin="ff9ac8", hair="7a3aff", dark="2a1030", eye="3affd8", wing="bfefff", cane="ffffff", stripe="ff2a5a",
              spr1="ffe23a", spr2="3ad0ff", spr3="7aff5a")
    C.attack = "cast"
    cl, at = skulpt.biped(C, hip=0.32, chest=0.54, head=0.74, lean=0.06, shoulder_x=0.12, hip_x=0.06,
                          r_chest=(0.1, 0.08, 0.1), r_waist=(0.07, 0.06, 0.07), r_hips=(0.08, 0.07, 0.06),
                          r_head=(0.14, 0.13, 0.13), r_arm=(0.03, 0.025), r_hand=0.03, r_leg=(0.035, 0.03),
                          r_foot=(0.035, 0.06, 0.03), arm_len=0.24, group="skin", digi=True)
    h = at["head"]
    for sx in (-1, 1):
        cl.chain([(0.1 * sx, h.y, h.z + 0.04), (0.2 * sx, h.y + 0.04, h.z + 0.1), (0.27 * sx, h.y + 0.08, h.z + 0.14)],
                 [(0.04, 0.02, 0.035), (0.03, 0.015, 0.025), 0.005], group="skin")
    cl.add((0, h.y + 0.02, h.z + 0.13), (0.07, 0.07, 0.06), group="hair")
    cl.mirror((0.05, h.y - 0.11, h.z + 0.02), (0.025, 0.02, 0.02), group="dark", neg=True)
    cl.add((0, h.y - 0.12, h.z - 0.05), (0.06, 0.02, 0.012), group="dark", neg=True)
    body = cl.build({"skin": "skin", "hair": "hair", "dark": "skin"}, voxel=0.006, budget=5000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.004})
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.05 * mx, h.y - 0.12, h.z + 0.02), (0.02, 0.01, 0.016), "eye", "head", rot=(0, 15 * mx, 0))
    for k in range(5):
        x = -0.04 + 0.02 * k
        C.cone(f"Grin{k}", (x, h.y - 0.125, h.z - 0.045), (x, h.y - 0.13, h.z - 0.065), 0.006, "cane", "head", segs=4)
    for side, mx in (("L", -1), ("R", 1)):
        pts = [(0.04 * mx, 0.08, 0.6), (0.22 * mx, 0.14, 0.86), (0.3 * mx, 0.18, 0.7), (0.2 * mx, 0.16, 0.5),
               (0.06 * mx, 0.1, 0.52)]
        if mx < 0:
            pts = pts[::-1]
        C.membrane(f"Wing{side}", pts, "wing", "chest", thick=0.008)
    hr = at["hdR"]
    pts = [hr + V((0, 0.06, -0.12)), hr, hr + V((0, -0.06, 0.22)), hr + V((0.04, -0.1, 0.28)), hr + V((0.08, -0.08, 0.24))]
    C.tube("Cane", pts, [0.014] * 5, "cane", "forearm.R")
    for k in range(4):
        C.ellipsoid(f"CaneStripe{k}", tuple(V(pts[1]).lerp(V(pts[2]), 0.2 + 0.25 * k)), (0.016, 0.016, 0.008), "stripe",
                    "forearm.R")
    rnd = random.Random(37)
    for k in range(7):
        C.box(f"Sprinkle{k}", tuple(hr + V((rnd.uniform(-0.1, 0.1), rnd.uniform(-0.25, -0.1), rnd.uniform(0.25, 0.45)))),
              (0.01, 0.01, 0.035), ("spr1", "spr2", "spr3")[k % 3], "forearm.R",
              rot=(rnd.uniform(-60, 60), rnd.uniform(-60, 60), 0), bevel=0.5)
