"""Alpaking, Thief King (Sunny Dunes, 7, legend): a towering alpaca king of thieves, a magnificent fluffy
coat, a crooked gold crown over his topknot, a velvet cape lined with stolen coins, gold hoops and a bandit
mask; a long neck held haughtily high."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(wool="f0e6d4", wool2="d8c8b0", face="c8a888", mask="1a1020", eye="ffd23a", cape="5a0a3a",
              lining="ffcf3a", gold="ffd23a", gem="3affb0", hoof="3a2a20", dark="1a1008")
    C.attack = "ram"
    C.relax = 0.8
    kits.quad(C, "wool", hip=(0.3, 0.95), chest=(-0.24, 1.0), neck=(-0.4, 1.6), head=(-0.66, 1.68),
              r_hip=0.34, r_chest=0.38, r_waist=0.34, r_neck=0.15, r_head=0.15, r_snout=0.1, r_leg=0.085, r_paw=0.1,
              knee=0.48, leg_x=0.22, tail=((0.55, 1.02),), r_tail=0.12, muscle=1.15, head_drop=0.02, jaw=False,
              head_m="face")
    at = C.at
    # fluffy wool tufts on the neck, chest and legs
    n0, n1 = V(C.anch["chest"]), V(C.anch["nb"])
    for k in range(5):
        p = n0.lerp(n1, 0.15 + 0.18 * k)
        C.ellipsoid(f"NeckFluff{k}", tuple(p + V((0, 0.02, 0))), (0.2 - 0.015 * k, 0.2 - 0.015 * k, 0.12), "wool", "neck")
    C.ellipsoid("Topknot", at("cran", 0, 0.0, 0.13), (0.14, 0.14, 0.11), "wool", "head")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            kn = C.bones[f"shin_{tag}.{side}"]["head"]
            C.ellipsoid(f"LegFluff{tag}{side}", tuple(kn), (0.13, 0.13, 0.16), "wool2", f"shin_{tag}.{side}")
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.ellipsoid(f"Hoof{tag}{side}", (paw.x, paw.y - 0.04, 0.04), (0.08, 0.1, 0.05), "hoof", f"shin_{tag}.{side}")
    # bandit mask and eyes, banana ears with gold hoops
    C.box("Mask", at("brow", 0, -0.08, 0.02), (0.26, 0.08, 0.07), "mask", "head", bevel=0.4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.075, -0.12, 0.02, mx), (0.03, 0.012, 0.02), "eye", "head")
        C.cone(f"Ear{mx}", at("cran", 0.09, 0.03, 0.08, mx), at("cran", 0.15, 0.0, 0.3, mx), 0.045, "face", "head", segs=6,
               smooth=True)
        C.lathe(f"Hoop{mx}", [(0.035, 0.0), (0.04, 0.005), (0.035, 0.01)], "gold", "head", segs=12)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(V(at("cran", 0.13, 0.02, 0.12, mx))) @
                                      __import__("mathutils").Matrix.Rotation(1.57, 4, 'Y'))
    C.box("Smirk", at("nose", 0.01, -0.07, -0.05), (0.06, 0.015, 0.01), "dark", "head", rot=(0, -10, 0), bevel=0.4)
    # crooked crown
    props.crown(C, at("cran", 0.02, 0.0, 0.24), 0.1, "gold", "head", points=5, height=0.1, m_gem="gem", tilt=-15)
    # velvet cape draped over the back, coin-lined
    b = V(C.anch["back"])
    top = C.surf(0, 4, dir=(0, 0, -1), y=b.y)[0].z
    C.ellipsoid("Cape", (0, b.y + 0.04, top - 0.02), (0.44, 0.5, 0.1), "cape", "chest")
    for mx in (-1, 1):
        C.box(f"CapeSide{mx}", (0.4 * mx, b.y + 0.04, top - 0.25), (0.04, 0.82, 0.42), "cape", "chest", bevel=0.2)
        C.box(f"CapeHem{mx}", (0.42 * mx, b.y + 0.04, top - 0.45), (0.04, 0.84, 0.05), "lining", "chest", bevel=0.3)
        for k in range(5):
            C.ellipsoid(f"Coin{mx}{k}", (0.43 * mx, b.y - 0.3 + 0.15 * k, top - 0.3), (0.012, 0.04, 0.04), "gold", "chest")
    C.ellipsoid("Clasp", at("neck", 0, -0.16, -0.1), (0.06, 0.03, 0.06), "gem", "neck")
