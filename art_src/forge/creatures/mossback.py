"""Mossback (Mushroom Forest, 2): a squat boulder-shelled tortoise, its domed shell a hill of moss, stones
and tiny ferns, stubby armoured legs and a beaked head that rarely comes out."""
import math
import random
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(skin="5a6a3a", shell="5a5040", rock="8a8a80", moss="4f8a2a", moss2="7ab83a", fern="2f6a2a",
              beak="c8b888", eye="ffd23a", dark="1a1408", flower="ff9ad8")
    C.attack = "ram"
    kits.quad(C, "skin", hip=(0.22, 0.42), chest=(-0.2, 0.44), neck=(-0.42, 0.42), head=(-0.62, 0.42),
              r_hip=0.3, r_chest=0.3, r_waist=0.32, r_neck=0.11, r_head=0.12, r_snout=0.08, r_leg=0.1, r_paw=0.11,
              knee=0.2, leg_x=0.33, tail=((0.45, 0.32),), r_tail=0.06, jaw=False)
    at = C.at
    rnd = random.Random(21)
    # domed shell with plates, rocks, moss and ferns
    C.lathe("Shell", [(0.56, 0.32), (0.58, 0.42), (0.52, 0.6), (0.38, 0.76), (0.18, 0.84), (0.001, 0.86)], "shell", None,
            segs=24, allowed=["hips", "chest"])
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0.0, 0)) @
                                  __import__("mathutils").Matrix.Diagonal((1.0, 1.15, 1.0, 1)))
    C.lathe("Rim", [(0.58, 0.3), (0.62, 0.34), (0.6, 0.38)], "rock", None, segs=24, allowed=["hips", "chest"])
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Diagonal((1.0, 1.15, 1.0, 1)))
    for k in range(9):
        a = 2 * math.pi * k / 9
        r = rnd.uniform(0.15, 0.42)
        x, y = math.cos(a) * r, math.sin(a) * r * 1.1
        loc, nor = C.surf(x, 3, part="Shell", dir=(0, 0, -1), y=y)
        if loc is None:
            continue
        b = "chest" if y < 0 else "hips"
        if k % 3 == 0:
            C.ellipsoid(f"Rock{k}", tuple(loc), (0.1, 0.09, 0.07), "rock", b, rot=(0, 0, 40 * k))
        else:
            C.ellipsoid(f"Moss{k}", tuple(loc), (0.15, 0.13, 0.05), "moss" if k % 2 else "moss2", b, rot=(0, 0, 30 * k))
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        base = V((math.cos(a) * 0.15, math.sin(a) * 0.15, 0.84))
        for j in range(3):
            C.cone(f"Fern{k}{j}", tuple(base), tuple(base + V((math.cos(a + j - 1) * 0.12, math.sin(a + j - 1) * 0.12, 0.22))),
                   0.03, "fern", "hips", segs=4)
    C.ellipsoid("Flower", (0.1, -0.05, 0.9), (0.04, 0.04, 0.025), "flower", "chest")
    # beaked head
    C.cone("Beak", at("snout", 0, 0.0, 0.0), at("snout", 0, -0.1, -0.04), 0.06, "beak", "head", segs=8, smooth=True)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.02, 0.03, mx), (0.025, 0.02, 0.02), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.07, -0.03, 0.06, mx), (0.06, 0.03, 0.02), "shell", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
    for side in ("L", "R"):
        for tag in ("f", "b"):
            kn = C.bones[f"shin_{tag}.{side}"]["head"]
            C.ellipsoid(f"Scale{tag}{side}", tuple(kn), (0.13, 0.13, 0.11), "rock", f"shin_{tag}.{side}")
