"""Grave Toad (Mushroom Forest, 4): a bloated graveyard toad, cracked headstones grown into its back,
glowing toxin sacs, a wide grim mouth and heavy-lidded acid-green eyes."""
from forge import kits


def build(C):
    C.palette(skin="4a5a3a", wart="6b7a4a", belly="c2b98a", stone="8a8f94", moss="4f8a2a", toxin="9dff3a",
              eye="c8ff3a", pupil="0c0f08", mouth="2a1418")
    C.attack = "bite"
    kits.quad(C, "skin", hip=(0.3, 0.6), chest=(-0.18, 0.7), neck=(-0.36, 0.78), head=(-0.68, 0.72),
              r_hip=0.4, r_chest=0.46, r_waist=0.44, r_neck=0.34, r_head=0.34, r_snout=0.24, r_leg=0.1, r_paw=0.13,
              knee=0.3, leg_x=0.38, tail=((0.55, 0.55),), r_tail=0.15, muscle=1.4)
    at = C.at
    C.ellipsoid("Lip", at("snout", 0, -0.04, -0.08), (0.36, 0.22, 0.035), "mouth", "head")
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.15), (0.33, 0.26, 0.1), "belly", "jaw")
    C.decal("Belly", 0, 0.3, (0.42, 0.5, 0.07), "belly", "chest", dir=(0, 0, 1), y=-0.05, spin=90)
    for mx in (-1, 1):
        C.ellipsoid(f"EyeBump{mx}", at("cran", 0.2, -0.08, 0.2, mx), (0.13, 0.13, 0.11), "skin", "head")
        C.ellipsoid(f"Eye{mx}", at("cran", 0.21, -0.17, 0.22, mx), (0.08, 0.06, 0.06), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("cran", 0.21, -0.22, 0.22, mx), (0.05, 0.012, 0.014), "pupil", "head")
        C.box(f"Lid{mx}", at("cran", 0.21, -0.17, 0.28, mx), (0.19, 0.12, 0.05), "wart", "head", rot=(-15, 20 * mx, 0),
              bevel=0.5)
        # toxin sacs bulging from the cheeks
        C.ellipsoid(f"Sac{mx}", at("snout", 0.3, 0.1, -0.02, mx), (0.1, 0.1, 0.1), "toxin", "head")
    # headstones grown into the back
    for k, (x, y, rz, h) in enumerate([(0.0, 0.05, 0, 0.42), (-0.22, 0.25, 15, 0.3), (0.24, -0.12, -12, 0.32),
                                       (0.1, 0.38, 8, 0.24)]):
        loc, nor = C.surf(x, 2.0, dir=(0, 0, -1), y=y)
        C.box(f"Stone{k}", (x, y, loc.z + h * 0.3), (0.26, 0.08, h), "stone", "hips" if y > 0.1 else "chest",
              rot=(8, rz, rz), bevel=0.4, taper=(0.9, 0.9))
        C.ellipsoid(f"StoneMoss{k}", (x, y, loc.z + h * 0.78), (0.12, 0.06, 0.05), "moss", "hips" if y > 0.1 else "chest")
    # warts
    import random
    rnd = random.Random(4)
    for k in range(14):
        x, y = rnd.uniform(-0.38, 0.38), rnd.uniform(-0.4, 0.45)
        C.decal(f"Wart{k}", x, 2.0, (0.05, 0.05, 0.035), "wart" if k % 3 else "toxin",
                "chest" if y < 0.05 else "hips", dir=(0, 0, -1), y=y)
