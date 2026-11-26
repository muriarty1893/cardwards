"""Moonlit Stalker (Dark Moon, 4): a lean shadow panther, fur black as the sky between stars, a crescent
moon glowing on its brow, wisps of shadow trailing from its shoulders and tail, eyes like two cold moons."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(fur="141028", fur2="2a2050", moon="e8f0ff", eye="aef4ff", star="c8d8ff", wisp="3a2a7a", claw="d8d8f0",
              mouth="3a0a2a")
    C.attack = "bite"
    kits.quad(C, "fur", hip=(0.36, 0.7), chest=(-0.3, 0.76), neck=(-0.55, 0.92), head=(-0.92, 0.88),
              r_hip=0.22, r_chest=0.3, r_waist=0.18, r_neck=0.14, r_head=0.18, r_snout=0.1, r_leg=0.075, r_paw=0.09,
              knee=0.36, leg_x=0.2, tail=((0.62, 0.8), (0.9, 0.95), (1.08, 1.2)), r_tail=0.06, muscle=1.2,
              head_drop=0.02)
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.09, -0.06, 0.02, mx), (0.04, 0.025, 0.022), "eye", "head", rot=(0, 0, 25 * mx))
        C.box(f"Brow{mx}", at("brow", 0.09, -0.06, 0.06, mx), (0.1, 0.06, 0.025), "fur2", "head", rot=(0, 25 * mx, -15 * mx),
              bevel=0.4)
        C.cone(f"Ear{mx}", at("cran", 0.1, 0.03, 0.1, mx), at("cran", 0.15, 0.1, 0.28, mx), 0.06, "fur", "head", segs=6,
               smooth=True)
        C.cone(f"Fang{mx}", at("snout", 0.045, -0.07, -0.05, mx), at("snout", 0.045, -0.08, -0.16, mx), 0.02, "claw", "head",
               segs=5)
    C.ellipsoid("Jaw", at("snout", 0, 0.0, -0.09), (0.08, 0.14, 0.035), "fur2", "jaw")
    C.ellipsoid("Mouth", at("snout", 0, -0.02, -0.065), (0.07, 0.12, 0.02), "mouth", "jaw")
    # crescent moon on the brow
    b = V(at("brow", 0, -0.08, 0.1))
    C.tube("Crescent", [b + V((-0.07, 0, 0.04)), b + V((0, -0.03, -0.03)), b + V((0.07, 0, 0.04))], [0.01, 0.03, 0.01],
           "moon", "head")
    # star specks across the coat
    import random
    rnd = random.Random(9)
    for k in range(14):
        x, y = rnd.uniform(-0.25, 0.25), rnd.uniform(-0.4, 0.45)
        C.decal(f"Star{k}", x, 3, (0.025, 0.025, 0.015), "star", "chest" if y < 0.03 else "hips", dir=(0, 0, -1), y=y)
    # shadow wisps from shoulders and tail tip
    for mx in (-1, 1):
        sh = V(at("chest", 0.18, 0.05, 0.22, mx))
        for k in range(3):
            C.cone(f"Wisp{mx}{k}", tuple(sh + V((0, 0.06 * k, 0))), tuple(sh + V((0.15 * mx, 0.3 + 0.08 * k, 0.15 - 0.05 * k))),
                   0.05, "wisp", "chest", segs=5, smooth=True)
    tip = V(C.anch["t2"])
    props.flame(C, tip, 0.12, "tail3", "wisp", "fur2", n=4, lean=(0, 0.8, 0.3), name="TailWisp")
