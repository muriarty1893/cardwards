"""Snowdrift Sage (Frost Peaks, 3): an old yeti hermit, a shaggy white mane and a long braided beard,
frost-blue face paint, a fur mantle with rune charms and a staff topped with a floating snow crystal."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(fur="eef4fa", shade="b8c8d8", face="7a9ab8", paint="3ad8ff", eye="ffffff", dark="0e1a2a",
              wood="5a4030", crystal="aef4ff", charm="ffcf5a", horn="d8cfb8")
    C.attack = "cast"
    kits.biped(C, "fur", hip=0.72, chest=1.18, neck=1.36, head_top=1.68, shoulder_x=0.38, hip_x=0.18,
               hand=(0.5, -0.12, 0.7), r_hip=0.3, r_waist=0.32, r_chest=0.42, r_neck=0.16, r_head=0.22,
               r_arm=0.12, r_hand=0.1, r_leg=0.13, r_foot=0.13, lean=0.22)
    h = V(C.anch["head"])
    C.ellipsoid("Face", tuple(h + V((0, -0.14, -0.02))), (0.14, 0.1, 0.13), "face", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.06 * mx, -0.235, 0.02))), (0.03, 0.012, 0.02), "eye", "head")
        C.box(f"Paint{mx}", tuple(h + V((0.07 * mx, -0.235, -0.04))), (0.02, 0.01, 0.07), "paint", "head", bevel=0.3)
        C.box(f"Brow{mx}", tuple(h + V((0.07 * mx, -0.23, 0.06))), (0.11, 0.05, 0.04), "fur", "head", rot=(0, 20 * mx, 0),
              bevel=0.5)
        C.tube(f"Horn{mx}", [h + V((0.16 * mx, 0.0, 0.1)), h + V((0.3 * mx, 0.08, 0.16)), h + V((0.34 * mx, -0.02, 0.3))],
               [0.04, 0.03, 0.005], "horn", "head")
    # shaggy mane and braided beard
    for k in range(9):
        a = math.pi * k / 8
        C.cone(f"Mane{k}", tuple(h + V((math.cos(a) * 0.2, 0.05, 0.08 + math.sin(a) * 0.12))),
               tuple(h + V((math.cos(a) * 0.36, 0.2, math.sin(a) * 0.25 - 0.05))), 0.08, "fur", "head", segs=5)
    beard = [h + V((0, -0.2, -0.12)), h + V((0, -0.26, -0.35)), h + V((0, -0.22, -0.6))]
    C.tube("Beard", beard, [0.09, 0.07, 0.03], "fur", None, allowed=["head", "neck"])
    for k in range(3):
        C.ellipsoid(f"BeardBand{k}", tuple(V(beard[1]).lerp(V(beard[2]), 0.2 + 0.3 * k)), (0.06, 0.06, 0.02), "charm",
                    "head")
    # fur mantle with rune charms
    c = V(C.anch["chest"])
    for k in range(10):
        a = 2 * math.pi * k / 10
        C.cone(f"Mantle{k}", tuple(c + V((math.cos(a) * 0.36, math.sin(a) * 0.3, 0.12))),
               tuple(c + V((math.cos(a) * 0.48, math.sin(a) * 0.42, -0.22))), 0.13, "shade", "chest", segs=5)
    for k, x in enumerate((-0.15, 0.0, 0.15)):
        C.box(f"Charm{k}", tuple(c + V((x, -0.42, -0.05 - 0.04 * abs(x) * 5))), (0.06, 0.02, 0.08), "charm", "chest",
              bevel=0.3)
    # staff with a floating snow crystal
    top = props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=1.5, up=0.85, top=None)
    C.cone("Crystal", tuple(top + V((0, 0, 0.12))), tuple(top + V((0, 0, 0.45))), 0.09, "crystal", "forearm.R", segs=6)
    C.cone("Crystal2", tuple(top + V((0, 0, 0.14))), tuple(top + V((0, 0, -0.05))), 0.08, "crystal", "forearm.R", segs=6)
    for k in range(3):
        a = 2 * math.pi * k / 3
        C.ellipsoid(f"Flake{k}", tuple(top + V((math.cos(a) * 0.18, math.sin(a) * 0.18, 0.2))), (0.03, 0.03, 0.03),
                    "crystal", "forearm.R")
