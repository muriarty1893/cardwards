"""Pain Shroom (Mushroom Forest, 3): a vicious little toadstool brute, its sickly purple cap bristling with
thorns, a scowling face, clawed root hands and a drip of venom from its thorny gills."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(stalk="c8b8a0", cap="6a2a7a", thorn="2a1a24", venom="aaff3a", eye="ffe23a", dark="120a10", root="5a3e28",
              gill="d8a8d8")
    C.attack = "swipe"
    kits.biped(C, "stalk", hip=0.42, chest=0.7, neck=0.82, head_top=1.0, shoulder_x=0.2, hip_x=0.1,
               hand=(0.36, -0.1, 0.36), r_hip=0.17, r_waist=0.17, r_chest=0.2, r_neck=0.13, r_head=0.14,
               r_arm=0.06, r_hand=0.07, r_leg=0.07, r_foot=0.08, lean=0.08)
    h = V(C.anch["head"])
    C.lathe("Cap", [(0.001, h.z + 0.02), (0.34, h.z - 0.02), (0.38, h.z + 0.06), (0.3, h.z + 0.2), (0.15, h.z + 0.3),
                    (0.001, h.z + 0.32)], "cap", "head", segs=24, wave=(7, 0.08, 0.3))
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y, 0)))
    C.lathe("Gill", [(0.12, h.z + 0.02), (0.36, h.z - 0.01)], "gill", "head", segs=24)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y, 0)))
    for k in range(10):
        a = 2 * math.pi * k / 10
        r = 0.2 + 0.1 * (k % 2)
        loc, nor = C.surf(math.cos(a) * r, h.z + 2, part="Cap", dir=(0, 0, -1), y=h.y + math.sin(a) * r)
        if loc is not None:
            C.cone(f"Thorn{k}", tuple(loc), tuple(loc + nor * 0.16), 0.035, "thorn", "head", segs=5)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.06 * mx, -0.13, -0.02))), (0.03, 0.012, 0.02), "eye", "head",
                    rot=(0, 15 * mx, 0))
        C.box(f"Brow{mx}", tuple(h + V((0.06 * mx, -0.13, 0.015))), (0.07, 0.02, 0.02), "dark", "head",
              rot=(0, -25 * mx, 0), bevel=0.3)
        for k in range(3):
            hd = V(C.anch["hdL" if mx < 0 else "hdR"])
            C.cone(f"Claw{mx}{k}", tuple(hd), tuple(hd + V((0.05 * (k - 1), -0.12, -0.08))), 0.022, "root",
                   "forearm.L" if mx < 0 else "forearm.R", segs=5)
    C.box("Scowl", tuple(h + V((0, -0.13, -0.08))), (0.08, 0.015, 0.015), "dark", "head", bevel=0.3)
    C.cone("Drip", tuple(h + V((0.2, -0.1, -0.02))), tuple(h + V((0.2, -0.1, -0.16))), 0.025, "venom", "head",
           segs=6, smooth=True)
