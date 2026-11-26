"""Lamp Djinn (Sunny Dunes, 6): a towering blue djinn rising out of a golden oil lamp on a tail of smoke,
broad-shouldered and bare-armed with gold bangles, a jewelled turban, a curling beard and eyes that glow
like coals."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="3a6ad8", skin2="2a4aa8", smoke="7a9ae8", gold="ffcf3a", gem="ff2a6a", turban="f0e8f8", beard="1a1a3a",
              eye="ffe23a", dark="0a0a1a", sash="b8202a", vest="7a1a8a")
    C.attack = "slam"
    kits.biped(C, "skin", hip=1.05, chest=1.55, neck=1.75, head_top=2.0, shoulder_x=0.48, hip_x=0.15,
               hand=(0.66, -0.15, 1.12), r_hip=0.24, r_waist=0.22, r_chest=0.42, r_neck=0.14, r_head=0.16,
               r_arm=0.13, r_hand=0.11, legs=False, hover=0.0, lean=0.05)
    h = V(C.anch["head"])
    # smoke tail down into the lamp
    for k in range(4):
        a = k * 1.5
        pts = [V((math.cos(a + j) * (0.2 - 0.03 * j), math.sin(a + j) * (0.2 - 0.03 * j) + 0.02 * j, 1.0 - 0.2 * j))
               for j in range(5)]
        C.tube(f"Smoke{k}", pts, [0.14, 0.12, 0.09, 0.07, 0.05], "smoke" if k % 2 else "skin2", None,
               allowed=["hips", "tail1", "tail2"])
    C.bone("lamp", (0, 0.05, 0.0), (0, 0.05, 0.2), None)
    C.lathe("Lamp", [(0.001, 0.0), (0.16, 0.02), (0.24, 0.1), (0.22, 0.18), (0.08, 0.22), (0.06, 0.26), (0.1, 0.28)],
            "gold", "lamp", segs=20)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Diagonal((1.0, 1.4, 1.0, 1)))
    C.tube("Spout", [V((0, -0.25, 0.14)), V((0, -0.42, 0.18)), V((0, -0.5, 0.28))], [0.05, 0.035, 0.03], "gold", "lamp")
    C.tube("Handle", [V((0, 0.28, 0.14)), V((0, 0.42, 0.22)), V((0, 0.34, 0.08))], [0.025, 0.025, 0.025], "gold", "lamp")
    # turban, face, beard
    C.ellipsoid("Turban", tuple(h + V((0, 0.02, 0.1))), (0.19, 0.19, 0.14), "turban", "head")
    C.ellipsoid("TurbanGem", tuple(h + V((0, -0.17, 0.12))), (0.04, 0.02, 0.05), "gem", "head")
    C.tube("Plume", [h + V((0, -0.15, 0.16)), h + V((0.04, -0.1, 0.34)), h + V((0.1, 0.0, 0.44))], [0.02, 0.025, 0.005],
           "gold", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.055 * mx, -0.15, 0.02))), (0.03, 0.012, 0.016), "eye", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.055 * mx, -0.15, 0.055))), (0.07, 0.02, 0.02), "dark", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        C.cone(f"Ear{mx}", tuple(h + V((0.15 * mx, 0, 0))), tuple(h + V((0.25 * mx, 0.04, 0.08))), 0.035, "skin", "head", segs=5)
    C.tube("Beard", [h + V((0, -0.12, -0.1)), h + V((0, -0.16, -0.24)), h + V((0.03, -0.12, -0.36)), h + V((0.08, -0.1, -0.32))],
           [0.05, 0.04, 0.025, 0.008], "beard", "head")
    # open vest, sash, gold bangles
    c = V(C.anch["chest"])
    for mx in (-1, 1):
        C.box(f"Vest{mx}", tuple(c + V((0.24 * mx, -0.1, -0.05))), (0.18, 0.3, 0.4), "vest", "chest", rot=(0, 0, 15 * mx),
              bevel=0.3)
    C.lathe("Sash", [(0.26, 0.0), (0.27, 0.12)], "sash", "hips", segs=20)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0, 1.02)))
    for side in ("L", "R"):
        fa = C.bones[f"forearm.{side}"]
        for t in (0.55, 0.72):
            p = fa["head"].lerp(fa["tail"], t)
            d = (fa["tail"] - fa["head"]).normalized()
            C.lathe(f"Bangle{side}{t}", [(0.125, -0.02), (0.135, 0.0), (0.125, 0.02)], "gold", f"forearm.{side}", segs=16)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(p) @
                                          V((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4())
        C.ellipsoid(f"Fist{side}", C.anch["hd" + side], (0.12, 0.12, 0.11), "skin", f"forearm.{side}")
