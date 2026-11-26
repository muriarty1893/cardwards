"""Cinderpup (Ember Flats, 1): a scrappy ash-grey hellhound pup, smouldering cracks along its back, ember
eyes, oversized paws and a tail that burns at the tip. Shared by Snow Pup and Sand Fox with other looks."""
from mathutils import Vector as V
from forge import kits, props


def build(C, tails=1, ears=0.26, frost=False):
    C.palette(fur="4a4044", fur2="2a2428", crack="ff5a1a", eye="ffcf3a", nose="140c0c", fire="ff6a1a", hot="ffd03a",
              fang="f0e8d8")
    C.attack = "bite"
    kits.quad(C, "fur", hip=(0.24, 0.48), chest=(-0.2, 0.55), neck=(-0.36, 0.72), head=(-0.66, 0.68),
              r_hip=0.2, r_chest=0.24, r_waist=0.18, r_neck=0.13, r_head=0.19, r_snout=0.09, r_leg=0.07, r_paw=0.1,
              knee=0.25, leg_x=0.17, tail=((0.42, 0.62), (0.56, 0.78)), r_tail=0.06, muscle=1.1, head_drop=0.03)
    at = C.at
    C.ellipsoid("Muzzle", at("snout", 0, -0.02, -0.02), (0.08, 0.1, 0.06), "fur2", "head")
    C.ellipsoid("Nose", at("nose", 0, -0.06, 0.02), (0.035, 0.025, 0.025), "nose", "head")
    C.ellipsoid("Jaw", at("snout", 0, 0.0, -0.08), (0.07, 0.1, 0.03), "fur2", "jaw")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.09, -0.08, 0.03, mx), (0.04, 0.025, 0.03), "eye", "head", rot=(0, 0, 20 * mx))
        C.box(f"Brow{mx}", at("brow", 0.09, -0.08, 0.075, mx), (0.08, 0.04, 0.02), "fur2", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        C.cone(f"Ear{mx}", at("cran", 0.11, 0.03, 0.1, mx), at("cran", 0.17, 0.08, 0.1 + ears, mx), 0.07, "fur", "head",
               segs=6, smooth=True)
        C.cone(f"Fang{mx}", at("snout", 0.04, -0.06, -0.04, mx), at("snout", 0.04, -0.07, -0.11, mx), 0.016, "fang", "head",
               segs=4)
    for k in range(4):
        y = -0.2 + 0.13 * k
        C.decal(f"Crack{k}", 0, 2, (0.03, 0.1, 0.02), "crack", "chest" if y < 0.02 else "hips", dir=(0, 0, -1), y=y,
                spin=20 * (k % 2 * 2 - 1))
    tip = V(C.anch["t1"])
    import math
    for k in range(tails):
        a = (k - (tails - 1) / 2) * 0.5
        off = V((math.sin(a) * 0.12, 0.0, 0.0))
        props.flame(C, tip + off, 0.11, "tail2", "fire", "hot", n=4, lean=(math.sin(a) * 0.6, 0.6, 0.3), name=f"TailFire{k}")
