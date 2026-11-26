"""Bog Toad (Mushroom Forest, 3): a hulking marsh toad. Sculpted: a heavy, warty body squatting on thick
folded hind legs, a broad flat head with a huge wide mouth and a sticky tongue curled inside, bulging
orange eyes, slick dark-green skin with poison-yellow streaks, a crown of cattail reeds and a lily pad
slung over its back."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(skin="2f5a2a", streak="d8e03a", belly="c8c890", eye="ff8a1a", pupil="0a0a08", mouth="3a1418", tongue="e85a7a",
              reed="7a5a2a", reedtop="4a2a14", pad="3a8a3a")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.24, 0.42), chest=(-0.16, 0.52), r_chest=(0.3, 0.26, 0.26), r_belly=(0.32, 0.3, 0.24),
                         r_hips=(0.3, 0.24, 0.22), leg_x=0.3, r_thigh=0.12, r_shin=0.06, r_paw=0.09, paw_len=1.2,
                         neck=((-0.3, 0.6),), r_neck=(0.24,), head=(-0.4, 0.66), r_head=(0.28, 0.22, 0.17),
                         snout=(-0.6, 0.6), r_snout=(0.2, 0.12), tail=((0.44, 0.36),), r_tail=(0.06, 0.03),
                         digi=False, group="skin", belly_group="belly", jaw=True)
    h = at["head"]
    cl.mirror((0.3, 0.26, 0.26), (0.14, 0.24, 0.16), group="skin")                 # folded hind legs
    cl.add((0, -0.48, 0.56), (0.26, 0.18, 0.03), group="mouth", neg=True)            # wide mouth
    for sx in (-1, 1):
        cl.add((0.15 * sx, h.y - 0.04, h.z + 0.14), (0.09, 0.09, 0.09), group="skin")
    rnd = random.Random(7)
    for k in range(18):                                                              # warts
        a, b = rnd.uniform(0, 6.28), rnd.uniform(0.4, 1.3)
        cl.add((math.cos(a) * 0.3 * math.sin(b), 0.05 + math.sin(a) * 0.32 * math.sin(b), 0.5 + 0.26 * math.cos(b)),
               (0.035, 0.035, 0.03), group="skin")
    body = cl.build({"skin": "skin", "belly": "belly", "mouth": "mouth"}, voxel=0.012, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.75, 0.95, math.sin(p.y * 16 + abs(p.x) * 5)) * smoothstep(0.2, 0.7, n.z),
            "streak")
    skulpt.eyes(C, [(0.15, h.y - 0.13, h.z + 0.18)], 0.055, "eye", "pupil")
    C.tube("Tongue", [V((0, -0.4, 0.55)), V((0, -0.56, 0.55)), V((0.04, -0.6, 0.6)), V((0.02, -0.56, 0.63))],
           [0.04, 0.035, 0.03, 0.02], "tongue", "jaw")
    for k in range(5):
        a = math.pi * (0.2 + 0.6 * k / 4)
        b = V((math.cos(a) * 0.14, h.y + 0.08 - math.sin(a) * 0.04, h.z + 0.14))
        top = b + V((math.cos(a) * 0.06, 0.04, 0.32 + 0.06 * (k % 2)))
        C.tube(f"Reed{k}", [b, top], [0.012, 0.008], "reed", "head")
        C.ellipsoid(f"ReedTop{k}", tuple(top - V((0, 0, 0.06))), (0.025, 0.025, 0.07), "reedtop", "head")
    C.lathe("Pad", [(0.001, 0.0), (0.24, 0.0), (0.25, 0.015)], "pad", "hips", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0.06, 0.16, 0.74)) @
                                  __import__("mathutils").Matrix.Rotation(0.3, 4, 'Y'))
