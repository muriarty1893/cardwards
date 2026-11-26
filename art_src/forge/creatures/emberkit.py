"""Emberkit (Ember Flats, 2): a sly fire fox kit with three burning tails, ember-orange fur fading to soot
at the legs, tall ears with glowing tips and a knowing grin. Sand Fox reuses this with one tail."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C, tails=3, fire=True):
    C.palette(fur="e8682a", fur2="fff0d8", soot="2a1a14", eye="ffe23a", pupil="1a0a08", tip="ffd03a", fire_m="ff6a1a",
              hot="ffd03a", nose="1a0e0a")
    C.attack = "bite"
    kits.quad(C, "fur", hip=(0.24, 0.46), chest=(-0.2, 0.52), neck=(-0.36, 0.68), head=(-0.68, 0.64),
              r_hip=0.17, r_chest=0.21, r_waist=0.15, r_neck=0.11, r_head=0.17, r_snout=0.07, r_leg=0.06, r_paw=0.07,
              knee=0.24, leg_x=0.15, tail=((0.42, 0.56), (0.58, 0.72)), r_tail=0.08, muscle=1.1, head_drop=0.03)
    at = C.at
    C.ellipsoid("Cheeks", at("brow", 0, -0.03, -0.07), (0.17, 0.08, 0.07), "fur2", "head")
    C.ellipsoid("Muzzle", at("snout", 0, -0.02, -0.03), (0.06, 0.1, 0.045), "fur2", "head")
    C.ellipsoid("Nose", at("nose", 0, -0.05, 0.01), (0.025, 0.02, 0.02), "nose", "head")
    C.decal("Chest", 0, 0.5, (0.14, 0.18, 0.04), "fur2", "chest")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.08, -0.08, 0.03, mx), (0.035, 0.02, 0.022), "eye", "head", rot=(0, 0, 25 * mx))
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.085, -0.1, 0.03, mx), (0.008, 0.008, 0.018), "pupil", "head")
        C.cone(f"Ear{mx}", at("cran", 0.1, 0.03, 0.1, mx), at("cran", 0.16, 0.06, 0.38, mx), 0.075, "fur", "head", segs=6,
               smooth=True)
        C.cone(f"EarTip{mx}", at("cran", 0.15, 0.055, 0.3, mx), at("cran", 0.16, 0.06, 0.4, mx), 0.03, "tip", "head", segs=6)
    C.box("Grin", at("snout", 0.02, -0.07, -0.05), (0.08, 0.015, 0.012), "pupil", "head", rot=(0, -10, 0), bevel=0.3)
    for side in ("L", "R"):
        for tag in ("f", "b"):
            sh = C.bones[f"shin_{tag}.{side}"]
            C.ellipsoid(f"Sock{tag}{side}", tuple(sh["head"].lerp(sh["tail"], 0.65)), (0.07, 0.07, 0.12), "soot",
                        f"shin_{tag}.{side}")
    base = V(C.anch["t0"])
    for k in range(tails):
        a = (k - (tails - 1) / 2) * 0.55
        d = V((math.sin(a) * 0.3, 0.3, 0.32))
        pts = [base, base + d * 0.5 + V((0, 0, 0.05)), base + d]
        C.tube(f"Tail{k}", pts, [0.07, 0.08, 0.05], "fur", "tail2" if tails > 1 else None,
               allowed=None if tails > 1 else ["tail1", "tail2"])
        if fire:
            props.flame(C, pts[2], 0.1, "tail2", "fire_m", "hot", n=4, lean=(math.sin(a) * 0.5, 0.5, 0.3), name=f"TailFire{k}")
        else:
            C.ellipsoid(f"TailTip{k}", tuple(pts[2] + d.normalized() * 0.04), (0.06, 0.06, 0.07), "fur2", "tail2")
