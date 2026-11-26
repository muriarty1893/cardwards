"""Caravan Master (Sunny Dunes, 6): a great armoured camel of the trade roads, a fringed and tasselled
caparison, a towering load of chests, rugs and amphorae, hanging lanterns and bells, a proud sneer."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(hide="c89a5a", hide2="a8784a", rug="b8202a", rug2="2a5aa8", tassel="ffcf3a", chest="6a3a1a",
              metal="d8b83a", jar="d86a3a", eye="1a1008", dark="1a1008", lamp="ffe08a", rope="8a6a4a")
    C.attack = "ram"
    kits.quad(C, "hide", hip=(0.36, 1.05), chest=(-0.28, 1.08), neck=(-0.56, 1.45), head=(-0.86, 1.48),
              r_hip=0.32, r_chest=0.36, r_waist=0.3, r_neck=0.12, r_head=0.14, r_snout=0.1, r_leg=0.075, r_paw=0.11,
              knee=0.5, leg_x=0.22, tail=((0.58, 0.95), (0.66, 0.7)), r_tail=0.04, muscle=1.15, head_drop=0.02, jaw=False)
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.09, -0.03, 0.03, mx), (0.03, 0.03, 0.02), "eye", "head")
        C.box(f"Lid{mx}", at("brow", 0.09, -0.04, 0.055, mx), (0.07, 0.05, 0.03), "hide2", "head", rot=(15, 0, 0), bevel=0.5)
        C.ellipsoid(f"Ear{mx}", at("cran", 0.1, 0.04, 0.06, mx), (0.03, 0.05, 0.07), "hide2", "head")
    C.ellipsoid("Lip", at("nose", 0, -0.03, -0.05), (0.08, 0.06, 0.04), "hide2", "head")
    # hump and caparison
    b = V(C.anch["back"])
    top = C.surf(0, 4, dir=(0, 0, -1), y=b.y)[0].z
    C.ellipsoid("Hump", (0, b.y, top), (0.24, 0.3, 0.2), "hide", "chest")
    C.ellipsoid("Rug", (0, b.y, top + 0.04), (0.42, 0.5, 0.1), "rug", "chest")
    for mx in (-1, 1):
        C.box(f"Drape{mx}", (0.36 * mx, b.y, top - 0.22), (0.04, 0.8, 0.38), "rug", "chest", bevel=0.2)
        C.box(f"DrapeBand{mx}", (0.38 * mx, b.y, top - 0.2), (0.04, 0.82, 0.08), "rug2", "chest", bevel=0.3)
        for k in range(6):
            C.cone(f"Tassel{mx}{k}", (0.38 * mx, b.y - 0.38 + 0.15 * k, top - 0.4), (0.39 * mx, b.y - 0.38 + 0.15 * k, top - 0.52),
                   0.03, "tassel", "chest", segs=5)
    # the load: chests, rolled rugs and jars
    z = top + 0.15
    C.box("Chest1", (0, b.y + 0.08, z + 0.12), (0.42, 0.34, 0.24), "chest", "chest", bevel=0.15)
    C.box("ChestBand", (0, b.y + 0.08, z + 0.12), (0.44, 0.06, 0.26), "metal", "chest", bevel=0.2)
    C.box("Chest2", (0.02, b.y + 0.05, z + 0.36), (0.3, 0.26, 0.2), "chest", "chest", rot=(0, 0, 12), bevel=0.15)
    C.tube("Roll", [V((-0.36, b.y - 0.2, z + 0.06)), V((0.36, b.y - 0.2, z + 0.06))], [0.08, 0.08], "rug2", "chest")
    for k, mx in enumerate((-1, 1)):
        p = V((0.32 * mx, b.y + 0.25, z - 0.02))
        C.lathe(f"Jar{k}", [(0.001, 0), (0.08, 0.02), (0.1, 0.12), (0.05, 0.22), (0.055, 0.26)], "jar", "chest", segs=12)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(p))
    # lantern swinging from a pole at the front
    pole_top = V((0.2, b.y - 0.35, z + 0.6))
    C.tube("Pole", [V((0.2, b.y - 0.2, z)), pole_top, pole_top + V((0, -0.18, 0))], [0.02, 0.02, 0.02], "rope", "chest")
    C.lathe("Lamp", [(0.04, -0.1), (0.07, -0.06), (0.07, 0.06), (0.04, 0.1)], "lamp", "chest", segs=10)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(pole_top + V((0, -0.18, -0.14))))
    # bell on the neck
    C.ellipsoid("Bell", at("neck", 0, -0.12, -0.08), (0.06, 0.06, 0.07), "metal", "neck")
    C.lathe("Collar", [(0.13, 0.0), (0.14, 0.05)], "rug", "neck", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(V(at("neck", 0, 0, 0))) @
                                  __import__("mathutils").Matrix.Rotation(0.9, 4, 'X'))
