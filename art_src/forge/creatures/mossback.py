"""Mossback (Mushroom Forest, 2): a squat boulder-shelled tortoise. Sculpted: a high domed shell like a
little hill, its plates edged with stone and grown over with thick moss, ferns and a flower, stubby
armoured elephant legs, and a wrinkled beaked head that rarely comes far out. Glacier Tortoise reuses it
in ice (the palette decides the look)."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(skin="5a6a3a", shell="5a5040", rock="8a8a80", moss="4f8a2a", moss2="7ab83a", fern="2f6a2a", beak="c8b888",
              eye="ffd23a", dark="1a1408", flower="ff9ad8", pupil="0a0a08")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.24, 0.4), chest=(-0.2, 0.42), r_chest=(0.24, 0.22, 0.2), r_belly=(0.26, 0.26, 0.18),
                         r_hips=(0.22, 0.2, 0.18), leg_x=0.26, r_thigh=0.09, r_shin=0.085, r_paw=0.09, paw_len=1.0,
                         neck=((-0.38, 0.44),), r_neck=(0.09,), head=(-0.52, 0.48), r_head=(0.1, 0.12, 0.09),
                         snout=(-0.64, 0.44), r_snout=(0.06, 0.05), tail=((0.44, 0.32),), r_tail=(0.04, 0.02),
                         digi=False, group="skin")
    h = at["head"]
    cl.add((0, 0.02, 0.56), (0.42, 0.46, 0.34), group="shell")                    # domed shell
    cl.add((0, 0.02, 0.34), (0.44, 0.48, 0.08), group="rock")                     # shell rim
    for k in range(7):                                                            # moss cushions on the dome
        a = 2 * math.pi * k / 7
        cl.add((math.cos(a) * 0.2, 0.02 + math.sin(a) * 0.22, 0.82), (0.13, 0.13, 0.08), group="moss")
    cl.add((0, 0.02, 0.9), (0.16, 0.18, 0.08), group="moss2")
    cl.add(tuple(at["snout"] + V((0, -0.02, -0.01))), (0.055, 0.04, 0.045), group="beak")
    for k in range(3):                                                            # neck wrinkles
        cl.add((0, -0.32 - 0.04 * k, 0.44 + 0.01 * k), (0.1 - 0.01 * k, 0.02, 0.08), group="skin")
    body = cl.build({"skin": "skin", "shell": "shell", "rock": "rock", "moss": "moss", "moss2": "moss2", "beak": "beak"},
                    voxel=0.012, budget=9000, relax=2, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.015})
    recolor(body, lambda p, n: cracks(p, 0.14, 0.06, seed=53) * (1.0 if 0.36 < p.z < 0.75 else 0.0), "rock")
    skulpt.eyes(C, [(0.07, h.y - 0.08, h.z + 0.03)], 0.02, "eye", "pupil")
    rnd = random.Random(3)
    for k in range(7):
        a = rnd.uniform(0, 6.28)
        r = rnd.uniform(0.0, 0.26)
        b = V((math.cos(a) * r, 0.02 + math.sin(a) * r, 0.88 - r * 0.25))
        C.cone(f"Fern{k}", tuple(b), tuple(b + V((rnd.uniform(-0.08, 0.08), rnd.uniform(-0.08, 0.08), 0.16))), 0.035,
               "fern", "chest" if b.y < 0.02 else "hips", segs=4)
    C.ellipsoid("Flower", (0.08, -0.08, 0.92), (0.04, 0.04, 0.02), "flower", "chest")
    for k in range(3):
        C.ellipsoid(f"Stone{k}", (-0.18 + 0.18 * k, 0.36, 0.62 - 0.05 * (k % 2)), (0.06, 0.05, 0.05), "rock", "hips")
