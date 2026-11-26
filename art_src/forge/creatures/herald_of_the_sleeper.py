"""Herald of the Sleeper (Dark Moon, 3): a floating cultist of something vast beneath the sea, a hooded
robe of deep teal, a single huge eye where a face should be, tentacles trailing from the hem and a bell
on a crooked staff that rings the faithful awake."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(robe="10303a", trim="3affd0", eye="f4f0c8", pupil="1a0a20", tent="4a2a6a", sucker="c8a0ff",
              bell="c8a03a", wood="2a2018", dark="05080a")
    C.attack = "cast"
    kits.biped(C, "robe", hip=0.9, chest=1.3, neck=1.48, head_top=1.78, shoulder_x=0.24, hip_x=0.12,
               hand=(0.42, -0.14, 0.9), r_hip=0.22, r_waist=0.2, r_chest=0.26, r_neck=0.1, r_head=0.18,
               r_arm=0.07, r_hand=0.06, legs=False, hover=0.35)
    h = V(C.anch["head"])
    C.lathe("Robe", [(0.15, 0.25), (0.34, 0.45), (0.3, 0.8), (0.24, 1.0)], "robe", None, segs=24,
            wave=(7, 0.07, 0.2), allowed=["hips", "tail1", "tail2"])
    C.ellipsoid("Hood", tuple(h + V((0, 0.04, 0.05))), (0.22, 0.22, 0.24), "robe", "head")
    C.cone("HoodTip", tuple(h + V((0, 0.12, 0.2))), tuple(h + V((0, 0.36, 0.34))), 0.1, "robe", "head", segs=8, smooth=True)
    C.ellipsoid("Face", tuple(h + V((0, -0.14, -0.01))), (0.16, 0.08, 0.17), "dark", "head")
    C.ellipsoid("Eye", tuple(h + V((0, -0.18, 0.0))), (0.11, 0.06, 0.11), "eye", "head")
    C.ellipsoid("Pupil", tuple(h + V((0, -0.235, 0.0))), (0.03, 0.02, 0.08), "pupil", "head")
    # glyph trim
    for k in range(3):
        C.decal(f"Glyph{k}", 0, 1.15 - 0.15 * k, (0.05, 0.05, 0.02), "trim", "chest", spin=45)
    C.lathe("Hem", [(0.33, 0.44), (0.35, 0.49)], "trim", None, segs=24, allowed=["hips", "tail1", "tail2"])
    # tentacles from under the robe
    for k in range(6):
        a = 2 * math.pi * k / 6 + 0.3
        top = V((math.cos(a) * 0.22, math.sin(a) * 0.22, 0.42))
        pts = [top, top + V((math.cos(a) * 0.12, math.sin(a) * 0.12, -0.2)), top + V((math.cos(a) * 0.08, math.sin(a) * 0.08 + 0.06, -0.42)),
               top + V((math.cos(a) * 0.18, math.sin(a) * 0.18 + 0.05, -0.5))]
        C.tube(f"Tentacle{k}", pts, [0.06, 0.045, 0.025, 0.008], "tent", None, allowed=["tail1", "tail2"])
        C.ellipsoid(f"Sucker{k}", tuple(pts[1] - V((math.cos(a), math.sin(a), 0)) * 0.03), (0.02, 0.02, 0.02), "sucker",
                    None, allowed=["tail1", "tail2"])
    # bell staff
    top = props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=1.3, up=0.75, top="hook")
    C.lathe("Bell", [(0.001, 0.0), (0.08, 0.02), (0.07, 0.1), (0.04, 0.16), (0.001, 0.17)], "bell", "forearm.R", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(top + V((0, -0.26, -0.22))))
    for side in ("L", "R"):
        hd = V(C.anch["hd" + side])
        for k in range(3):
            C.cone(f"Finger{side}{k}", tuple(hd), tuple(hd + V((0.04 * (k - 1), -0.1, -0.1))), 0.02, "tent", f"forearm.{side}",
                   segs=5, smooth=True)
