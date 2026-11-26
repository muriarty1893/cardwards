"""Ancient Hollowneck (Mushroom Forest, 10): a colossal moss sauropod whose neck is a hollow old trunk,
a small forest of pines and mushrooms growing on its back, bark-armoured legs and ember-gold eyes."""
import math
import random
from forge import kits


def build(C):
    C.palette(hide="3f4a34", bark="4a3524", moss="4f8a2e", pine="2a5a2a", trunk="3a2818", eye="ffc23a",
              dark="0e0c08", cap="c23a2a", spot="f0e8d0", belly="7a7a5a")
    C.attack = "ram"
    kits.quad(C, "hide", hip=(0.42, 1.0), chest=(-0.28, 1.12), neck=(-0.52, 2.05), head=(-0.82, 2.12),
              r_hip=0.5, r_chest=0.58, r_waist=0.52, r_neck=0.2, r_head=0.18, r_snout=0.12, r_leg=0.15, r_paw=0.17,
              knee=0.55, leg_x=0.38, tail=((0.85, 0.85), (1.15, 0.6), (1.35, 0.35)), r_tail=0.22, muscle=1.2,
              head_drop=0.05)
    at = C.at
    # the neck: a hollow bark trunk with a knot hole
    n0, n1 = C.anch["chest"], C.anch["nb"]
    C.tube("NeckBark", [(0, n0[1] - 0.05, n0[2] + 0.2), (0, (n0[1] + n1[1]) / 2 - 0.05, (n0[2] + n1[2]) / 2 + 0.05),
                        (0, n1[1], n1[2] - 0.05)], [0.27, 0.23, 0.2], "bark", None, allowed=["chest", "neck"])
    C.ellipsoid("KnotHole", (0, -0.62, 1.55), (0.09, 0.05, 0.13), "dark", "neck")
    for k in range(5):
        z = 1.3 + 0.16 * k
        y = n0[1] + (n1[1] - n0[1]) * (z - n0[2]) / (n1[2] - n0[2])
        C.ellipsoid(f"BarkRing{k}", (0, y + 0.02, z), (0.25, 0.25, 0.03), "trunk", "neck")
    # head: eyes, brow, mossy beard
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.11, -0.03, 0.02, mx), (0.04, 0.03, 0.025), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.1, -0.03, 0.07, mx), (0.1, 0.06, 0.03), "bark", "head", rot=(0, 20 * mx, 0),
              bevel=0.5)
    C.ellipsoid("Beard", at("snout", 0, 0.05, -0.12), (0.1, 0.14, 0.08), "moss", "head")
    # a forest on its back
    rnd = random.Random(11)
    spots = [(0.15, -0.15), (-0.18, 0.0), (0.05, 0.2), (-0.1, 0.38), (0.22, 0.32), (-0.25, -0.3)]
    for k, (x, y) in enumerate(spots):
        loc, nor = C.surf(x, 4, dir=(0, 0, -1), y=y)
        b = "chest" if y < 0.05 else "hips"
        h = 0.45 + rnd.uniform(0, 0.3)
        C.tube(f"Trunk{k}", [loc, loc + nor * 0.12 + __import__("mathutils").Vector((0, 0, 0.12))],
               [0.04, 0.035], "trunk", b)
        for t in range(3):
            base = loc + __import__("mathutils").Vector((0, 0, 0.1 + t * h * 0.22))
            C.cone(f"Pine{k}{t}", tuple(base), tuple(base + __import__("mathutils").Vector((0, 0, h * (0.55 - 0.1 * t)))),
                   0.2 - 0.05 * t, "pine", b, segs=7)
    for k in range(12):
        x, y = rnd.uniform(-0.4, 0.4), rnd.uniform(-0.45, 0.6)
        C.decal(f"Moss{k}", x, 4, (0.16, 0.14, 0.05), "moss", "chest" if y < 0.05 else "hips", dir=(0, 0, -1), y=y,
                spin=rnd.uniform(0, 180))
    for k, (x, y) in enumerate([(0.32, 0.1), (-0.3, 0.25), (0.0, 0.55)]):
        loc, nor = C.surf(x, 4, dir=(0, 0, -1), y=y)
        C.tube(f"ShroomStem{k}", [loc, loc + nor * 0.1], [0.03, 0.025], "spot", "hips")
        C.ellipsoid(f"Shroom{k}", tuple(loc + nor * 0.12), (0.08, 0.08, 0.04), "cap", "hips")
    # bark armour on the legs
    for side in ("L", "R"):
        for tag in ("f", "b"):
            kn = C.bones[f"shin_{tag}.{side}"]["head"]
            C.ellipsoid(f"LegBark{tag}{side}", (kn.x, kn.y - 0.03, kn.z - 0.12), (0.19, 0.19, 0.26), "bark",
                        f"shin_{tag}.{side}")
    C.decal("Belly", 0, 0.4, (0.45, 0.6, 0.06), "belly", "chest", dir=(0, 0, 1), y=0.0, spin=90)
