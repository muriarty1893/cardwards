"""Gummy Cub (Candy Hills, 1): a scrappy gummy-bear cub. Sculpted: a chunky little bear in cherry-red
jelly, a big round head with a torn ear and a scowl, rock-candy fangs, sugar crystals stuck all over it,
stubby legs, and a gumball clenched in one fist like a rock ready to throw."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(gummy="e81a3a", gummy2="ff6a7a", sugar="fff0f4", eye="1a0408", fang="fff8fa", ball="3ad8ff", nose="8a0a1a")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.3, chest=0.56, head=0.76, lean=0.06, shoulder_x=0.18, hip_x=0.1,
                          r_chest=(0.18, 0.16, 0.17), r_waist=(0.17, 0.15, 0.12), r_hips=(0.17, 0.15, 0.1),
                          r_head=(0.16, 0.15, 0.15), r_arm=(0.06, 0.055), r_hand=0.06, r_leg=(0.075, 0.07),
                          r_foot=(0.07, 0.09, 0.045), arm_len=0.3, group="gummy")
    h = at["head"]
    cl.add((0, h.y - 0.12, h.z - 0.04), (0.08, 0.07, 0.06), group="gummy2")          # muzzle
    cl.add((0, h.y - 0.13, h.z + 0.06), (0.1, 0.04, 0.025), rot=(-15, 0, 0), group="gummy")
    for sx in (-1, 1):
        cl.add((0.12 * sx, h.y + 0.02, h.z + 0.13), (0.06, 0.04, 0.06), group="gummy")    # ears
    cl.add((0.15, h.y + 0.02, h.z + 0.18), (0.04, 0.05, 0.035), group="gummy", neg=True) # torn ear
    cl.mirror((0.06, h.y - 0.13, h.z + 0.02), (0.025, 0.02, 0.02), group="gummy", neg=True)
    body = cl.build({"gummy": "gummy", "gummy2": "gummy2"}, voxel=0.007, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.004})
    recolor(body, lambda p, n: smoothstep(0.75, 1.0, n.z) * 0.6, "gummy2")
    rnd = random.Random(31)
    sp = [V((rnd.uniform(-0.2, 0.2), rnd.uniform(-0.2, 0.2), rnd.uniform(0.2, 0.9))) for _ in range(40)]
    recolor(body, lambda p, n: max(smoothstep(0.03, 0.012, (p - q).length) for q in sp), "sugar")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, h.y - 0.145, h.z + 0.02), (0.022, 0.012, 0.022), "eye", "head")
        C.cone(f"Fang{mx}", (0.03 * mx, h.y - 0.19, h.z - 0.06), (0.03 * mx, h.y - 0.19, h.z - 0.11), 0.014, "fang", "head",
               segs=4)
    C.ellipsoid("Nose", (0, h.y - 0.2, h.z - 0.02), (0.025, 0.015, 0.018), "nose", "head")
    C.ellipsoid("Gumball", tuple(at["hdR"] + V((0, -0.04, 0.0))), (0.07, 0.07, 0.07), "ball", "forearm.R")
