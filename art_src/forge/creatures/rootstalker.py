"""Rootstalker (Mushroom Forest, 4): a gaunt hunter of twisted roots, long-limbed and hunched, a hollow
knotted face with two lantern-green eyes deep inside, finger-roots like claws and moss hanging off its frame."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(root="4a3220", root2="6a4a2a", moss="4f8a2a", eye="b8ff5a", dark="0c0804", bark="3a2618", shroom="d8c8a8")
    C.attack = "swipe"
    kits.biped(C, "root", hip=0.9, chest=1.38, neck=1.55, head_top=1.82, shoulder_x=0.3, hip_x=0.14,
               hand=(0.48, -0.25, 0.4), r_hip=0.16, r_waist=0.12, r_chest=0.2, r_neck=0.07, r_head=0.15,
               r_arm=0.06, r_hand=0.05, r_leg=0.07, r_foot=0.07, lean=0.32, knee_fwd=0.06)
    h = V(C.anch["head"])
    C.ellipsoid("Hollow", tuple(h + V((0, -0.11, -0.02))), (0.11, 0.06, 0.13), "dark", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.045 * mx, -0.14, 0.02))), (0.022, 0.012, 0.022), "eye", "head")
        C.tube(f"Branch{mx}", [h + V((0.08 * mx, 0.02, 0.1)), h + V((0.2 * mx, 0.08, 0.3)), h + V((0.3 * mx, 0.02, 0.44))],
               [0.03, 0.02, 0.005], "bark", "head")
    # twisted root strands wrapping the limbs and torso
    for side, mx in (("L", -1), ("R", 1)):
        for b in (f"arm.{side}", f"forearm.{side}", f"leg.{side}", f"shin.{side}"):
            bb = C.bones[b]
            for k in range(2):
                a, d = bb["head"], bb["tail"]
                off = V((0.03 * (1 if k else -1), 0.03, 0))
                C.tube(f"Strand{b}{k}", [a + off, (a + d) / 2 - off, d + off], [0.025, 0.03, 0.02], "root2", b)
        hd = V(C.anch["hd" + side])
        for k in range(4):
            C.cone(f"Finger{side}{k}", tuple(hd), tuple(hd + V((0.04 * (k - 1.5), -0.06, -0.2))), 0.018, "bark",
                   f"forearm.{side}", segs=5)
    c = V(C.anch["chest"])
    for k in range(4):
        C.tube(f"Rib{k}", [c + V((-0.18, -0.12, 0.1 - 0.1 * k)), c + V((0, -0.22, 0.08 - 0.1 * k)), c + V((0.18, -0.12, 0.1 - 0.1 * k))],
               [0.02, 0.025, 0.02], "root2", "chest")
    for k in range(5):
        a = math.pi * (0.2 + 0.6 * k / 4)
        C.cone(f"Moss{k}", tuple(c + V((math.cos(a) * 0.2, 0.05, 0.18))), tuple(c + V((math.cos(a) * 0.25, 0.1, -0.2))), 0.05,
               "moss", "chest", segs=4)
    C.ellipsoid("Shroom", tuple(c + V((0.18, 0.1, 0.2))), (0.07, 0.07, 0.03), "shroom", "chest")
