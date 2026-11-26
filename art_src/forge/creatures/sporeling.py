"""Sporeling (Mushroom Forest, 2): a small fungal sprout-warrior, a speckled red toadstool cap pulled low
over glowing eyes, a stalk body wrapped in a leaf cloak, carrying a thorn spear and a pouch of healing spores."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(stalk="efe2c8", cap="c8282a", spot="fff4e0", gill="e8c8a8", eye="9dff5a", dark="140c0a", leaf="3a8a2a",
              thorn="5a3a20", pouch="8a6a3a", glow="c8ff8a")
    C.attack = "stab"
    kits.biped(C, "stalk", hip=0.5, chest=0.8, neck=0.92, head_top=1.1, shoulder_x=0.16, hip_x=0.08,
               hand=(0.28, -0.08, 0.5), r_hip=0.15, r_waist=0.14, r_chest=0.16, r_neck=0.1, r_head=0.13,
               r_arm=0.045, r_hand=0.045, r_leg=0.06, r_foot=0.07)
    h = V(C.anch["head"])
    C.lathe("Cap", [(0.001, h.z + 0.02), (0.3, h.z - 0.02), (0.34, h.z + 0.04), (0.28, h.z + 0.16), (0.14, h.z + 0.25),
                    (0.001, h.z + 0.27)], "cap", "head", segs=24, wave=(5, 0.06, 0.28))
    C.lathe("Gill", [(0.1, h.z + 0.02), (0.32, h.z - 0.01)], "gill", "head", segs=24)
    for k, (x, y) in enumerate([(0.12, -0.12), (-0.15, -0.05), (0.0, 0.15), (0.18, 0.1), (-0.08, -0.2)]):
        C.decal(f"Spot{k}", x, h.z + 1, (0.045, 0.045, 0.02), "spot", "head", part="Cap", dir=(0, 0, -1), y=y)
    C.ellipsoid("Shadow", tuple(h + V((0, -0.1, -0.04))), (0.11, 0.06, 0.06), "dark", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.15, -0.03))), (0.025, 0.012, 0.018), "eye", "head",
                    rot=(0, 15 * mx, 0))
    # leaf cloak
    c = V(C.anch["chest"])
    for k in range(5):
        import math
        a = math.pi * (0.1 + 0.8 * k / 4)
        C.ellipsoid(f"Leaf{k}", tuple(c + V((math.cos(a) * 0.14, 0.08 + math.sin(a) * 0.06, -0.08))), (0.08, 0.04, 0.18),
                    "leaf", "chest", rot=(10, 0, (k - 2) * 25))
    # thorn spear and spore pouch
    hr = V(C.anch["hdR"])
    C.tube("Spear", [hr + V((0, 0.1, -0.35)), hr, hr + V((0, -0.12, 0.45))], [0.018, 0.018, 0.016], "thorn", "forearm.R")
    C.cone("SpearTip", tuple(hr + V((0, -0.12, 0.45))), tuple(hr + V((0, -0.16, 0.6))), 0.035, "glow", "forearm.R", segs=5)
    C.ellipsoid("Pouch", (0.13, -0.08, 0.46), (0.06, 0.05, 0.07), "pouch", "hips")
    C.ellipsoid("PouchGlow", (0.13, -0.12, 0.5), (0.03, 0.02, 0.02), "glow", "hips")
