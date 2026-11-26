"""Oasis Alpaca (Sunny Dunes, 4): a hardy desert alpaca that carries water to the wounded, a thick cream
fleece, a woven saddle-blanket with clay water jugs, a sprig of palm on its head and calm knowing eyes."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(wool="f4ead8", wool2="e0d0b8", face="d8b890", eye="1a1008", blanket="2a8a8a", blanket2="ffcf3a",
              jug="c8683a", water="3ad8ff", palm="3a8a2a", hoof="3a2a20", rope="8a6a4a")
    C.attack = "ram"
    C.relax = 0.8
    kits.quad(C, "wool", hip=(0.28, 0.85), chest=(-0.22, 0.9), neck=(-0.38, 1.4), head=(-0.6, 1.46),
              r_hip=0.3, r_chest=0.33, r_waist=0.3, r_neck=0.13, r_head=0.13, r_snout=0.09, r_leg=0.075, r_paw=0.09,
              knee=0.42, leg_x=0.2, tail=((0.5, 0.92),), r_tail=0.1, muscle=1.1, head_drop=0.02, jaw=False, head_m="face")
    at = C.at
    n0, n1 = V(C.anch["chest"]), V(C.anch["nb"])
    for k in range(4):
        C.ellipsoid(f"NeckFluff{k}", tuple(n0.lerp(n1, 0.2 + 0.2 * k)), (0.17, 0.17, 0.11), "wool", "neck")
    C.ellipsoid("Topknot", at("cran", 0, 0, 0.11), (0.11, 0.11, 0.09), "wool", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.08, 0.02, mx), (0.025, 0.012, 0.02), "eye", "head")
        C.cone(f"Ear{mx}", at("cran", 0.08, 0.03, 0.07, mx), at("cran", 0.13, 0.0, 0.25, mx), 0.04, "face", "head", segs=6,
               smooth=True)
    for k in range(3):
        C.cone(f"Palm{k}", at("cran", 0.0, 0.0, 0.17), at("cran", 0.12 * (k - 1), 0.1, 0.35), 0.03, "palm", "head", segs=4)
    # woven blanket with water jugs
    b = V(C.anch["back"])
    top = C.surf(0, 4, dir=(0, 0, -1), y=b.y)[0].z
    C.ellipsoid("Blanket", (0, b.y, top - 0.02), (0.38, 0.4, 0.08), "blanket", "chest")
    for mx in (-1, 1):
        C.box(f"BlanketSide{mx}", (0.33 * mx, b.y, top - 0.2), (0.04, 0.62, 0.32), "blanket", "chest", bevel=0.2)
        C.box(f"BlanketBand{mx}", (0.35 * mx, b.y, top - 0.14), (0.04, 0.64, 0.06), "blanket2", "chest", bevel=0.3)
        p = V((0.42 * mx, b.y, top - 0.3))
        C.lathe(f"Jug{mx}", [(0.001, 0.0), (0.09, 0.02), (0.11, 0.12), (0.05, 0.22), (0.055, 0.26)], "jug", "chest", segs=12)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(p))
        C.ellipsoid(f"Water{mx}", tuple(p + V((0, 0, 0.26))), (0.045, 0.045, 0.015), "water", "chest")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.ellipsoid(f"Hoof{tag}{side}", (paw.x, paw.y - 0.04, 0.04), (0.07, 0.09, 0.05), "hoof", f"shin_{tag}.{side}")
