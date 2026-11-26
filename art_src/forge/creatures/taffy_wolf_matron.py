"""Taffy Wolf Matron (Candy Hills, 6): a big alpha she-wolf of pulled caramel taffy, a shaggy mane of
hardened sugar shards, rock-candy fangs and claws, glowing cherry eyes."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(taffy="d8843a", cream="ffe2b0", shard="ff6aa0", shard2="ffd0e8", fang="fff6fa", eye="ff1a3a",
              dark="2a120a", nose="3a1a10")
    C.attack = "bite"
    kits.quad(C, "taffy", hip=(0.36, 0.78), chest=(-0.28, 0.9), neck=(-0.52, 1.12), head=(-0.98, 1.02),
              r_hip=0.27, r_chest=0.38, r_waist=0.24, r_neck=0.17, r_head=0.19, r_snout=0.1, r_leg=0.09, r_paw=0.1,
              knee=0.4, leg_x=0.24, tail=((0.62, 0.92), (0.85, 0.98), (1.02, 1.1)), r_tail=0.1, muscle=1.25,
              head_drop=0.04)
    at = C.at
    # cream chest and muzzle
    C.decal("ChestCream", 0, 0.8, (0.22, 0.28, 0.05), "cream", "chest", dir=(0, 1, 0))
    C.ellipsoid("Muzzle", at("snout", 0, -0.02, -0.03), (0.09, 0.14, 0.07), "cream", "head")
    C.ellipsoid("Nose", at("nose", 0, -0.07, 0.03), (0.045, 0.035, 0.035), "nose", "head")
    C.ellipsoid("Jaw", at("snout", 0, 0.0, -0.1), (0.08, 0.15, 0.04), "cream", "jaw")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.09, -0.06, 0.03, mx), (0.035, 0.025, 0.02), "eye", "head", rot=(0, 0, 25 * mx))
        C.box(f"Brow{mx}", at("brow", 0.085, -0.06, 0.07, mx), (0.1, 0.06, 0.03), "dark", "head", rot=(0, 25 * mx, -20 * mx),
              bevel=0.4)
        C.cone(f"Ear{mx}", at("cran", 0.1, 0.04, 0.12, mx), at("cran", 0.15, 0.1, 0.34, mx), 0.07, "taffy", "head",
               segs=6, smooth=True)
        C.cone(f"Fang{mx}", at("snout", 0.05, -0.08, -0.04, mx), at("snout", 0.05, -0.09, -0.14, mx), 0.022, "fang",
               "head", segs=5)
    # mane of hard-candy shards around the neck and shoulders
    import math
    n = V(C.anch["neck"])
    for k in range(12):
        a = math.pi * (k / 11) * 1.4 - 0.2 * math.pi
        d = V((math.cos(a), 0.3, math.sin(a)))
        b = n + V((math.cos(a) * 0.16, 0.05, math.sin(a) * 0.14 + 0.02))
        C.cone(f"Shard{k}", tuple(b), tuple(b + d * (0.24 + 0.06 * (k % 3))), 0.06, "shard" if k % 2 else "shard2",
               "neck" if k < 6 else "chest", segs=4)
    for k in range(5):
        y = -0.2 + 0.15 * k
        loc, nor = C.surf(0, 3, dir=(0, 0, -1), y=y)
        if loc is not None:
            C.cone(f"BackShard{k}", tuple(loc), tuple(loc + V((0, 0.12, 0.2 - 0.02 * k))), 0.05, "shard",
                   "chest" if y < 0.05 else "hips", segs=4)
