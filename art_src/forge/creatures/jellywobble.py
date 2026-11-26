"""Jellywobble (Candy Hills, 4): a quivering golem of layered gelatin in three flavours, stacked like a
dessert mould, candies and fruit suspended inside, a cross face pressed into the top layer and two
jelly fists that slosh when they swing."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(j1="ff3a6a", j2="ffd23a", j3="3ad87a", cream="fff8f0", eye="1a0a10", c1="7a3aff", c2="3ad8ff", cherry="c8102a")
    C.attack = "slam"
    C.relax = 1.0
    kits.biped(C, "j1", hip=0.45, chest=0.85, neck=1.0, head_top=1.2, shoulder_x=0.42, hip_x=0.15,
               hand=(0.56, -0.12, 0.42), r_hip=0.34, r_waist=0.36, r_chest=0.36, r_neck=0.3, r_head=0.24,
               r_arm=0.1, r_hand=0.14, r_leg=0.1, r_foot=0.13, skin_head=False)
    # stacked mould layers
    for k, (z0, z1, r0, r1, m) in enumerate([(0.12, 0.55, 0.42, 0.38, "j3"), (0.55, 0.9, 0.38, 0.33, "j2"),
                                             (0.9, 1.22, 0.33, 0.22, "j1")]):
        C.lathe(f"Layer{k}", [(0.001, z0), (r0, z0), (r0 * 1.02, (z0 + z1) / 2), (r1, z1), (0.001, z1 + 0.01)], m,
                None, segs=24, wave=(8, 0.03, r1 * 0.9), allowed=["hips", "chest", "neck", "head"])
    C.lathe("Cream", [(0.2, 1.2), (0.24, 1.24), (0.15, 1.3), (0.001, 1.32)], "cream", "head", segs=16, wave=(6, 0.1, 0.15))
    C.ellipsoid("Cherry", (0, 0, 1.36), (0.06, 0.06, 0.06), "cherry", "head")
    for k, (x, z, m) in enumerate([(0.2, 0.3, "c1"), (-0.22, 0.42, "c2"), (0.05, 0.7, "c1"), (-0.15, 0.75, "cherry")]):
        C.ellipsoid(f"Suspended{k}", (x, -0.28, z), (0.06, 0.04, 0.05), m, "hips" if z < 0.55 else "chest",
                    rot=(0, 30 * k, 0))
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.09 * mx, -0.25, 1.05), (0.035, 0.015, 0.03), "eye", "head")
        C.box(f"Brow{mx}", (0.09 * mx, -0.26, 1.1), (0.08, 0.02, 0.02), "eye", "head", rot=(0, 25 * mx, 0), bevel=0.3)
        hd = V(C.anch["hdL" if mx < 0 else "hdR"])
        C.ellipsoid(f"Fist{mx}", tuple(hd), (0.14, 0.14, 0.13), "j2" if mx < 0 else "j3", "forearm.L" if mx < 0 else "forearm.R")
    C.box("Mouth", (0, -0.27, 0.97), (0.1, 0.015, 0.015), "eye", "head", bevel=0.3)
