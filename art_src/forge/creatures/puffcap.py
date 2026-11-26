"""Puffcap (Mushroom Forest, 3): a waddling puffball mushroom, round and bulging, venting clouds of healing
spores from a crater on its crown; stubby root legs, grumpy heavy-lidded eyes."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(puff="e8dcc0", puff2="c8b890", crater="6a5a3a", spore="c8ff8a", eye="1a1408", lid="b8a880", root="6a4a2a",
              wart="d8c8a8")
    C.attack = "slam"
    C.relax = 0.8
    kits.biped(C, "puff", hip=0.42, chest=0.6, neck=0.75, head_top=0.95, shoulder_x=0.3, hip_x=0.14,
               hand=(0.42, -0.08, 0.36), r_hip=0.3, r_waist=0.38, r_chest=0.4, r_neck=0.3, r_head=0.26,
               r_arm=0.06, r_hand=0.06, r_leg=0.07, r_foot=0.09, skin_head=True)
    h = V(C.anch["head"])
    top = C.surf(0, 5, dir=(0, 0, -1), y=h.y)[0]
    h = V((h.x, h.y, top.z - 0.25))      # smoothing settles the body; anchor the crown on the real top
    C.lathe("Crater", [(0.12, h.z + 0.2), (0.16, h.z + 0.26), (0.09, h.z + 0.24)], "crater", "head", segs=16)
    C.bone("puff", (0, 0, h.z + 0.25), (0, 0, h.z + 0.55), "head")
    for k in range(5):
        a = 2 * math.pi * k / 5
        C.ellipsoid(f"Spore{k}", (math.cos(a) * 0.12, math.sin(a) * 0.12, h.z + 0.27 + 0.06 * (k % 2)), (0.09, 0.09, 0.08),
                    "spore", "puff")
    C.ellipsoid("SporeTop", (0, 0, h.z + 0.38), (0.1, 0.1, 0.09), "spore", "puff")
    C.extra_idle.append(lambda P, t: P.s("puff", 0.85 + 0.25 * abs(math.sin(math.pi * 2 * t))))
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.36, 0.72), (0.04, 0.02, 0.03), "eye", "head")
        C.box(f"Lid{mx}", (0.1 * mx, -0.36, 0.75), (0.1, 0.04, 0.03), "lid", "head", rot=(0, 15 * mx, 0), bevel=0.5)
    import random
    rnd = random.Random(3)
    for k in range(14):
        x, z = rnd.uniform(-0.3, 0.3), rnd.uniform(0.3, 0.9)
        C.decal(f"Wart{k}", x, z, (0.035, 0.035, 0.03), "wart" if k % 2 else "puff2", "chest", dir=(0, 1 if k % 3 else -1, 0))
    for side in ("L", "R"):
        ft = C.bones[f"shin.{side}"]["tail"]
        for k in (-1, 0, 1):
            C.cone(f"Root{side}{k}", (ft.x, ft.y - 0.04, 0.06), (ft.x + 0.08 * k, ft.y - 0.14, 0.0), 0.03, "root",
                   f"shin.{side}", segs=5)
