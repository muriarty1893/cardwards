"""Gummy Cub (Candy Hills, 1): a scrappy gummy-bear cub, translucent cherry-red jelly with sugar crystals
stuck to it, a torn ear, rock-candy fangs and a gumball clenched in one fist like a rock."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(gummy="e81a3a", gummy2="ff6a7a", sugar="fff0f4", eye="1a0408", fang="fff8fa", ball="3ad8ff", nose="8a0a1a")
    C.attack = "swipe"
    C.relax = 0.0
    kits.biped(C, "gummy", hip=0.42, chest=0.68, neck=0.8, head_top=1.08, shoulder_x=0.2, hip_x=0.11,
               hand=(0.3, -0.1, 0.4), r_hip=0.2, r_waist=0.2, r_chest=0.23, r_neck=0.14, r_head=0.18,
               r_arm=0.08, r_hand=0.08, r_leg=0.09, r_foot=0.09)
    h = V(C.anch["head"])
    C.ellipsoid("Muzzle", tuple(h + V((0, -0.15, -0.05))), (0.09, 0.07, 0.07), "gummy2", "head")
    C.ellipsoid("Nose", tuple(h + V((0, -0.22, -0.02))), (0.03, 0.02, 0.025), "nose", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.07 * mx, -0.16, 0.05))), (0.025, 0.012, 0.022), "eye", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.07 * mx, -0.16, 0.09))), (0.07, 0.03, 0.02), "gummy2", "head",
              rot=(0, 25 * mx, 0), bevel=0.4)
        C.ellipsoid(f"Ear{mx}", tuple(h + V((0.12 * mx, 0.02, 0.09))), (0.065, 0.045, 0.065), "gummy", "head")
        C.cone(f"Fang{mx}", tuple(h + V((0.035 * mx, -0.2, -0.08))), tuple(h + V((0.035 * mx, -0.21, -0.14))), 0.014, "fang",
               "head", segs=4)
    C.box("EarTear", tuple(h + V((0.14, 0.0, 0.14))), (0.05, 0.05, 0.03), "sugar", "head", rot=(0, 30, 0), bevel=0.3)
    import random
    rnd = random.Random(12)
    for k in range(16):
        x, z = rnd.uniform(-0.22, 0.22), rnd.uniform(0.35, 1.0)
        C.decal(f"Sugar{k}", x, z, (0.018, 0.018, 0.015), "sugar", "chest", dir=(0, 1 if k % 2 else -1, 0))
    C.decal("Belly", 0, 0.58, (0.13, 0.16, 0.04), "gummy2", "chest")
    C.ellipsoid("Gumball", tuple(V(C.anch["hdR"]) + V((0, -0.06, 0.02))), (0.07, 0.07, 0.07), "ball", "forearm.R")
