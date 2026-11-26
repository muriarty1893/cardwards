"""Sprinkle Sprite (Candy Hills, 1): a mischievous sugar imp, pointed ears and a sharp grin, wings of
spun sugar, a candy-cane wand that flings sprinkles."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="ff9ac8", hair="7a3aff", dark="2a1030", eye="3affd8", wing="bfefff", cane="ffffff",
              stripe="ff2a5a", spr1="ffe23a", spr2="3ad0ff", spr3="7aff5a")
    C.attack = "cast"
    kits.biped(C, "skin", hip=0.62, chest=0.98, neck=1.12, head_top=1.5, shoulder_x=0.16, hip_x=0.08,
               hand=(0.3, -0.08, 0.68), r_hip=0.12, r_waist=0.1, r_chest=0.14, r_neck=0.05, r_head=0.22,
               r_arm=0.04, r_hand=0.04, r_leg=0.05, r_foot=0.045, legs=False, hover=0.45)
    h = V(C.anch["head"])
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.085 * mx, -0.19, 0.02))), (0.055, 0.03, 0.045), "eye", "head",
                    rot=(0, 0, -15 * mx))
        C.ellipsoid(f"Pupil{mx}", tuple(h + V((0.09 * mx, -0.215, 0.02))), (0.015, 0.01, 0.035), "dark", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.08 * mx, -0.2, 0.085))), (0.09, 0.03, 0.022), "hair", "head",
              rot=(0, 25 * mx, 0), bevel=0.4)
        C.cone(f"Ear{mx}", tuple(h + V((0.18 * mx, 0, 0.04))), tuple(h + V((0.42 * mx, 0.06, 0.2))), 0.06, "skin", "head",
               segs=6, smooth=True)
    C.box("Grin", tuple(h + V((0, -0.205, -0.08))), (0.12, 0.02, 0.025), "dark", "head", rot=(0, 0, 0), bevel=0.4)
    for k in range(4):
        C.cone(f"Tooth{k}", tuple(h + V((-0.045 + 0.03 * k, -0.215, -0.07))), tuple(h + V((-0.045 + 0.03 * k, -0.215, -0.1))),
               0.012, "cane", "head", segs=4)
    # spiky sugar-glass hair
    for k in range(7):
        a = (k - 3) * 0.28
        C.cone(f"Hair{k}", tuple(h + V((a * 0.4, 0.04, 0.16))), tuple(h + V((a * 0.75, 0.2, 0.42 - abs(a) * 0.18))),
               0.07, "hair", "head", segs=5)
    # sugar wings
    kits.wings(C, "wing", "wing", shoulder=(0.08, 0.1, 0.98), span=0.6, up=0.35, sweep=0.2, r=0.015, droop=0.3,
               fingers=2, thick=0.01)
    # candy cane wand with a sprinkle burst
    hr = V(C.anch["hdR"])
    C.tube("Cane", [hr + V((0, 0, -0.15)), hr + V((0, 0, 0.3)), hr + V((0, -0.1, 0.42)), hr + V((0, -0.16, 0.33))],
           [0.025, 0.025, 0.025, 0.025], "cane", "forearm.R")
    for k in range(4):
        C.ellipsoid(f"CaneStripe{k}", tuple(hr + V((0, 0, -0.1 + 0.11 * k))), (0.029, 0.029, 0.014), "stripe",
                    "forearm.R", rot=(20, 0, 0))
    for k, m in enumerate(("spr1", "spr2", "spr3", "spr1", "spr2")):
        p = hr + V((0.06 * (k - 2), -0.2 - 0.03 * (k % 2), 0.4 + 0.05 * (k % 3)))
        C.ellipsoid(f"Sprinkle{k}", tuple(p), (0.015, 0.015, 0.04), m, "forearm.R", rot=(30 * k, 20 * k, 0))
    C.ellipsoid("Skirt", (0, 0, 0.6), (0.15, 0.14, 0.08), "hair", "hips")
