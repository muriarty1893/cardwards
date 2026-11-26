"""Bog Toad (Mushroom Forest, 3): a hulking marsh toad, slick dark-green skin with poison-yellow streaks,
a crown of cattail reeds, a lily pad slung over its back and a sticky tongue curled in its wide mouth."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(skin="2f5a2a", streak="d8e03a", belly="c8c890", eye="ff8a1a", pupil="0a0a08", mouth="3a1418",
              tongue="e85a7a", reed="7a5a2a", reedtop="4a2a14", pad="3a8a3a")
    C.attack = "bite"
    C.relax = 0.7
    kits.quad(C, "skin", hip=(0.26, 0.52), chest=(-0.14, 0.6), neck=(-0.3, 0.66), head=(-0.56, 0.6),
              r_hip=0.32, r_chest=0.36, r_waist=0.36, r_neck=0.28, r_head=0.28, r_snout=0.2, r_leg=0.09, r_paw=0.11,
              knee=0.26, leg_x=0.32, tail=((0.45, 0.48),), r_tail=0.1, muscle=1.35)
    at = C.at
    C.ellipsoid("Lip", at("snout", 0, -0.03, -0.07), (0.3, 0.18, 0.03), "mouth", "head")
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.13), (0.27, 0.22, 0.08), "belly", "jaw")
    C.ellipsoid("Tongue", at("snout", 0, -0.12, -0.08), (0.08, 0.06, 0.04), "tongue", "jaw")
    C.decal("Belly", 0, 0.3, (0.34, 0.42, 0.06), "belly", "chest", dir=(0, 0, 1), y=-0.05, spin=90)
    for mx in (-1, 1):
        C.ellipsoid(f"EyeBump{mx}", at("cran", 0.17, -0.06, 0.17, mx), (0.11, 0.11, 0.09), "skin", "head")
        C.ellipsoid(f"Eye{mx}", at("cran", 0.18, -0.13, 0.19, mx), (0.07, 0.05, 0.055), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("cran", 0.18, -0.175, 0.19, mx), (0.045, 0.01, 0.015), "pupil", "head")
        for k in range(3):
            C.decal(f"Streak{mx}{k}", 0, 0.62, (0.025, 0.14, 0.02), "streak", "chest" if k < 2 else "hips",
                    dir=(-mx, 0, 0), y=-0.15 + 0.2 * k, spin=10)
    # cattail crown and lily pad
    for k, x in enumerate((-0.08, 0.0, 0.08)):
        b = V(at("cran", x, 0.02, 0.22))
        C.tube(f"Reed{k}", [b, b + V((x * 0.5, 0.03, 0.22 + 0.05 * (k == 1)))], [0.012, 0.01], "reed", "head")
        C.ellipsoid(f"Cattail{k}", tuple(b + V((x * 0.5, 0.03, 0.24 + 0.05 * (k == 1)))), (0.025, 0.025, 0.06), "reedtop",
                    "head")
    loc = C.surf(0, 3, dir=(0, 0, -1), y=0.12)[0]
    C.ellipsoid("Pad", tuple(loc + V((0.05, 0, 0.02))), (0.26, 0.24, 0.02), "pad", "hips", rot=(8, -6, 0))
