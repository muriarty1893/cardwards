"""Cotton Sheep (Candy Hills, 4): a burly battering ram whose fleece is spun cotton candy in pink and
blue, heavy spiral candy-stick horns and a dark stubborn face."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(face="3a2a3a", fleece="ffb8e0", fleece2="b8d8ff", horn="fff0f4", stripe="ff3a6a", eye="ffe23a",
              hoof="2a1a2a")
    C.attack = "ram"
    kits.quad(C, "face", hip=(0.28, 0.62), chest=(-0.22, 0.66), neck=(-0.4, 0.74), head=(-0.66, 0.66),
              r_hip=0.22, r_chest=0.24, r_waist=0.22, r_neck=0.14, r_head=0.15, r_snout=0.09, r_leg=0.055, r_paw=0.06,
              knee=0.3, leg_x=0.18, tail=((0.42, 0.66),), r_tail=0.05, head_drop=0.04, jaw=False)
    at = C.at
    import random
    rnd = random.Random(14)
    for k in range(18):
        y = rnd.uniform(-0.35, 0.4)
        a = rnd.uniform(-1.2, 1.2) + math.pi / 2
        r = 0.27
        p = V((math.cos(a) * r, y, 0.66 + math.sin(a) * r * 0.9))
        C.ellipsoid(f"Fleece{k}", tuple(p), (0.17, 0.16, 0.15), "fleece" if k % 3 else "fleece2",
                    "chest" if y < 0.03 else "hips")
    C.ellipsoid("Forelock", at("cran", 0, 0.0, 0.1), (0.13, 0.12, 0.09), "fleece", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.09, -0.05, 0.02, mx), (0.025, 0.02, 0.018), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.09, -0.06, 0.05, mx), (0.07, 0.04, 0.02), "face", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        base = V(at("cran", 0.1, 0.0, 0.06, mx))
        pts = []
        for k in range(9):
            a = k * 0.75
            r = 0.17 - k * 0.012
            pts.append(base + V((0.08 * mx + 0.03 * k * mx, math.cos(a) * r - 0.0, math.sin(a) * r * 0.9 - 0.02 * k)))
        C.tube(f"Horn{mx}", pts, [0.07 - 0.006 * k for k in range(9)], "horn", "head")
        for k in range(0, 9, 2):
            C.ellipsoid(f"HornStripe{mx}{k}", tuple(pts[k]), (0.075 - 0.006 * k,) * 2 + (0.02,), "stripe", "head")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.ellipsoid(f"Hoof{tag}{side}", (paw.x, paw.y - 0.04, 0.04), (0.065, 0.075, 0.05), "hoof", f"shin_{tag}.{side}")
