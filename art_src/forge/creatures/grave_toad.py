"""Grave Toad (Mushroom Forest, 4): a bloated graveyard toad. Sculpted: a huge sagging warty body, a wide
grim downturned mouth, heavy-lidded acid-green eyes, cracked moss-covered headstones grown right into its
back, and glowing toxin sacs swelling from its throat and flanks."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(skin="4a5a3a", wart="6b7a4a", belly="c2b98a", stone="8a8f94", moss="4f8a2a", toxin="9dff3a", eye="c8ff3a",
              pupil="0c0f08", mouth="2a1418", lid="3a4a2a")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.24, 0.46), chest=(-0.16, 0.54), r_chest=(0.34, 0.28, 0.3), r_belly=(0.38, 0.34, 0.3),
                         r_hips=(0.32, 0.26, 0.26), leg_x=0.32, r_thigh=0.13, r_shin=0.07, r_paw=0.1, paw_len=1.2,
                         neck=((-0.3, 0.62),), r_neck=(0.26,), head=(-0.42, 0.68), r_head=(0.3, 0.22, 0.18),
                         snout=(-0.6, 0.62), r_snout=(0.2, 0.12), tail=((0.46, 0.38),), r_tail=(0.06, 0.03),
                         digi=False, group="skin", belly_group="belly", jaw=True)
    h = at["head"]
    cl.mirror((0.32, 0.26, 0.28), (0.15, 0.25, 0.17), group="skin")
    cl.add((0, -0.5, 0.58), (0.28, 0.18, 0.025), rot=(0, 0, 0), group="mouth", neg=True)
    for sx in (-1, 1):
        cl.add((0.16 * sx, h.y - 0.04, h.z + 0.14), (0.09, 0.09, 0.08), group="skin")
    rnd = random.Random(9)
    for k in range(22):
        a, b = rnd.uniform(0, 6.28), rnd.uniform(0.3, 1.3)
        cl.add((math.cos(a) * 0.36 * math.sin(b), 0.05 + math.sin(a) * 0.36 * math.sin(b), 0.52 + 0.3 * math.cos(b)),
               (0.04, 0.04, 0.035), group="wart")
    body = cl.build({"skin": "skin", "wart": "wart", "belly": "belly", "mouth": "mouth"}, voxel=0.013, budget=9500,
                    relax=2, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.014})
    skulpt.eyes(C, [(0.16, h.y - 0.13, h.z + 0.16)], 0.05, "eye", "pupil", slit=True)
    for mx in (-1, 1):
        pass
        C.ellipsoid(f"Sac{mx}", (0.34 * mx, -0.12, 0.42), (0.09, 0.1, 0.09), "toxin", "chest")
    C.ellipsoid("ThroatSac", (0, -0.48, 0.42), (0.14, 0.1, 0.09), "toxin", "head")
    pts = []
    for k in range(9):                                                         # wide grim downturned mouth
        x = -0.26 + 0.065 * k
        z = h.z - 0.1 - 0.06 * (abs(x) / 0.26) ** 2
        hit, _ = C.surf(x, z)
        if hit is not None:
            pts.append(hit + V((0, 0.005, 0)))
    if len(pts) > 2:
        C.tube("Mouth", pts, [0.012] * len(pts), "mouth", "head")
    for k, (x, y, rz) in enumerate([(-0.14, 0.02, 12), (0.12, 0.16, -8), (0.0, -0.12, 4)]):
        C.box(f"Stone{k}", (x, y, 0.96 + 0.04 * (k == 2)), (0.16, 0.06, 0.26), "stone", "hips" if y > 0.05 else "chest",
              rot=(0, rz, rz), bevel=0.35)
        C.ellipsoid(f"StoneMoss{k}", (x, y, 0.84), (0.1, 0.06, 0.05), "moss", "hips" if y > 0.05 else "chest")
