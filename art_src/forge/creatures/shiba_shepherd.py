"""Shiba Shepherd (Dark Moon, 4): a stout guardian hound who herds lost dreams home, russet coat with a
cream mask, a night-blue mantle clasped with a moon brooch, a shepherd's lantern hanging from its collar."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(fur="c8642a", cream="fff0d8", dark="1a0e08", eye="2a1a10", mantle="1a2a5a", trim="d8c8ff",
              moon="f0f4ff", lamp="ffe08a", metal="8a8aa0", nose="1a1010")
    C.attack = "bite"
    kits.quad(C, "fur", hip=(0.3, 0.7), chest=(-0.24, 0.78), neck=(-0.44, 1.0), head=(-0.78, 0.98),
              r_hip=0.26, r_chest=0.32, r_waist=0.25, r_neck=0.17, r_head=0.21, r_snout=0.1, r_leg=0.085, r_paw=0.1,
              knee=0.36, leg_x=0.22, tail=((0.48, 0.95), (0.4, 1.12)), r_tail=0.09, muscle=1.2, head_drop=0.03)
    at = C.at
    C.ellipsoid("Mask", at("snout", 0, 0.0, -0.02), (0.11, 0.14, 0.09), "cream", "head")
    C.ellipsoid("Cheeks", at("brow", 0, -0.02, -0.06), (0.17, 0.1, 0.08), "cream", "head")
    C.ellipsoid("Nose", at("nose", 0, -0.08, 0.03), (0.04, 0.03, 0.03), "nose", "head")
    C.ellipsoid("Jaw", at("snout", 0, 0.0, -0.1), (0.08, 0.12, 0.035), "cream", "jaw")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.085, -0.08, 0.03, mx), (0.03, 0.02, 0.025), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.085, -0.08, 0.075, mx), (0.08, 0.04, 0.02), "cream", "head", rot=(0, 20 * mx, 0),
              bevel=0.4)
        C.cone(f"Ear{mx}", at("cran", 0.11, 0.02, 0.12, mx), at("cran", 0.14, 0.05, 0.32, mx), 0.07, "fur", "head", segs=6,
               smooth=True)
    C.decal("Chest", 0, 0.78, (0.2, 0.22, 0.05), "cream", "chest")
    # curled tail
    C.ellipsoid("TailCurl", C.anch["t1"], (0.1, 0.1, 0.1), "fur", "tail2")
    # night mantle with a moon brooch
    n = V(C.anch["neck"])
    C.lathe("Collar", [(0.2, 0.0), (0.22, 0.06)], "metal", "neck", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(n) @ __import__("mathutils").Matrix.Rotation(0.6, 4, 'X'))
    C.ellipsoid("Mantle", at("back", 0, -0.18, 0.02), (0.32, 0.3, 0.1), "mantle", "chest")
    for mx in (-1, 1):
        C.box(f"MantleSide{mx}", at("chest", 0.3, 0.05, 0.0, mx), (0.04, 0.34, 0.3), "mantle", "chest", bevel=0.3)
        C.box(f"MantleTrim{mx}", at("chest", 0.32, 0.05, -0.15, mx), (0.04, 0.36, 0.04), "trim", "chest", bevel=0.3)
    C.ellipsoid("Brooch", at("chest", 0, -0.32, 0.12), (0.06, 0.03, 0.06), "moon", "chest")
    # lantern hanging from the collar
    lp = V(at("chest", 0, -0.36, -0.12))
    C.tube("LampChain", [n + V((0, -0.18, -0.08)), lp + V((0, 0, 0.12))], [0.01, 0.01], "metal", "neck")
    C.lathe("Lamp", [(0.03, -0.08), (0.06, -0.05), (0.06, 0.05), (0.03, 0.09)], "lamp", "neck", segs=10)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(lp))
