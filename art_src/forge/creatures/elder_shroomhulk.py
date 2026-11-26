"""Elder Shroomhulk (Mushroom Forest, 7): an ancient fungal giant, a vast red cap like a war-banner on its
shoulders, a body of packed white mycelium and moss, smaller mushrooms bursting from its back and arms,
and boulder-heavy fists of root."""
import math
import random
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(body="e8dcc8", body2="c8b898", cap="b8201a", spot="fff4e0", gill="e8c8a8", moss="4f8a2a", eye="ffcf3a",
              dark="120a08", root="5a3e28", cap2="d8782a")
    C.attack = "slam"
    kits.biped(C, "body", hip=0.85, chest=1.38, neck=1.52, head_top=1.75, shoulder_x=0.5, hip_x=0.22,
               hand=(0.7, -0.25, 0.42), r_hip=0.34, r_waist=0.36, r_chest=0.5, r_neck=0.2, r_head=0.18,
               r_arm=0.15, r_hand=0.15, r_leg=0.16, r_foot=0.16, lean=0.25, elbow_back=0.06)
    h = V(C.anch["head"])
    rnd = random.Random(4)
    # the great cap over head and shoulders
    C.lathe("Cap", [(0.001, h.z + 0.02), (0.7, h.z - 0.06), (0.78, h.z + 0.02), (0.68, h.z + 0.22), (0.4, h.z + 0.4),
                    (0.001, h.z + 0.45)], "cap", "head", segs=32, wave=(6, 0.1, 0.6))
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y + 0.05, 0)))
    C.lathe("Gill", [(0.2, h.z + 0.02), (0.74, h.z - 0.04)], "gill", "head", segs=32)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y + 0.05, 0)))
    for k in range(9):
        a = 2 * math.pi * k / 9
        r = 0.2 + 0.25 * (k % 2)
        C.decal(f"Spot{k}", math.cos(a) * r, h.z + 2, (0.09, 0.09, 0.03), "spot", "head", part="Cap", dir=(0, 0, -1),
                y=h.y + 0.05 + math.sin(a) * r)
    # face in the shadow under the cap
    C.ellipsoid("Face", tuple(h + V((0, -0.12, -0.04))), (0.16, 0.08, 0.12), "dark", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.07 * mx, -0.19, -0.02))), (0.035, 0.012, 0.025), "eye", "head")
    # mycelium strands and moss over the body
    for k in range(10):
        x, z = rnd.uniform(-0.4, 0.4), rnd.uniform(0.9, 1.5)
        C.decal(f"Moss{k}", x, z, (0.1, 0.08, 0.04), "moss" if k % 2 else "body2", "chest", dir=(0, 1 if k % 3 else -1, 0),
                spin=rnd.uniform(0, 180))
    # small mushrooms bursting from back and arms
    for k, (b, t, s) in enumerate([("chest", (0.25, 0.3, 1.45), 0.1), ("chest", (-0.3, 0.28, 1.35), 0.08),
                                   ("arm.L", None, 0.07), ("arm.R", None, 0.08), ("forearm.R", None, 0.06)]):
        if t is None:
            bb = C.bones[b]
            t = tuple(bb["head"].lerp(bb["tail"], 0.5) + V((0, 0.05, 0.12)))
        t = V(t)
        C.tube(f"MiniStem{k}", [t - V((0, 0, 0.06)), t + V((0, 0, s * 0.8))], [s * 0.3, s * 0.25], "body", b)
        C.ellipsoid(f"MiniCap{k}", tuple(t + V((0, 0, s * 0.9))), (s, s, s * 0.5), "cap2" if k % 2 else "cap", b)
    # root fists
    for side in ("L", "R"):
        hd = V(C.anch["hd" + side])
        C.ellipsoid(f"Fist{side}", tuple(hd), (0.2, 0.2, 0.18), "root", f"forearm.{side}")
        for k in range(3):
            C.cone(f"Knuckle{side}{k}", tuple(hd + V((0.08 * (k - 1), -0.12, 0.02))),
                   tuple(hd + V((0.09 * (k - 1), -0.22, -0.02))), 0.04, "root", f"forearm.{side}", segs=5)
