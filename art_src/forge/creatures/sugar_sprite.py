"""Sugar Sprite (Candy Hills, 3): a ghostly sugar spirit, a body of drifting powdered sugar that tapers
to a wisp, a mask-like face of glazed icing, a crown of rock-candy crystals and hands trailing sugar dust."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(sugar="fff4fa", sugar2="ffd8ec", icing="ff8ac8", eye="3a0a5a", crystal="c8a8ff", crystal2="8af0ff",
              dust="ffe8f8")
    C.attack = "cast"
    C.relax = 0.6
    kits.biped(C, "sugar", hip=0.8, chest=1.12, neck=1.26, head_top=1.5, shoulder_x=0.2, hip_x=0.1,
               hand=(0.38, -0.12, 0.85), r_hip=0.17, r_waist=0.14, r_chest=0.2, r_neck=0.07, r_head=0.16,
               r_arm=0.05, r_hand=0.05, legs=False, hover=0.4)
    h = V(C.anch["head"])
    C.ellipsoid("Mask", tuple(h + V((0, -0.08, 0.0))), (0.15, 0.1, 0.16), "icing", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.055 * mx, -0.17, 0.03))), (0.035, 0.015, 0.025), "eye", "head",
                    rot=(0, 20 * mx, 0))
        C.box(f"Drip{mx}", tuple(h + V((0.06 * mx, -0.17, -0.06))), (0.02, 0.012, 0.06), "icing", "head", bevel=0.4)
    C.box("Mouth", tuple(h + V((0, -0.175, -0.08))), (0.05, 0.01, 0.012), "eye", "head", bevel=0.3)
    for k in range(5):
        a = math.pi * (0.15 + 0.7 * k / 4)
        b = h + V((math.cos(a) * 0.12, 0.02 - math.sin(a) * 0.03, 0.12))
        C.cone(f"Crystal{k}", tuple(b), tuple(b + V((math.cos(a) * 0.05, 0.02, 0.18 + 0.08 * (k == 2)))), 0.04,
               "crystal" if k % 2 else "crystal2", "head", segs=5)
    # sugar dust trailing from the hands and the wisp
    for side in ("L", "R"):
        hd = V(C.anch["hd" + side])
        for k in range(3):
            C.ellipsoid(f"Dust{side}{k}", tuple(hd + V((0.03 * k, 0.05 * k, -0.08 * k))), (0.04 - 0.008 * k,) * 3, "dust",
                        f"forearm.{side}")
    for k in range(5):
        a = 2 * math.pi * k / 5
        C.ellipsoid(f"Mote{k}", (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.45 + 0.1 * (k % 2)), (0.035,) * 3, "sugar2",
                    "tail1")
