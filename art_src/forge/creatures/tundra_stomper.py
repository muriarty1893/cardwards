"""Tundra Stomper (Frost Peaks, 7): a war-mammoth of the high ice, shaggy grey-blue coat, sweeping
tusks capped in iron, an ice-crusted armoured brow plate and a frosted howdah of spikes on its back."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(fur="5a6a7a", fur2="8a9aaa", tusk="f2ead8", iron="3a3f48", ice="aee8ff", eye="ffd23a", dark="0e1218",
              wood="4a3a2a", strap="7a2a2a")
    C.attack = "ram"
    kits.quad(C, "fur", hip=(0.38, 1.0), chest=(-0.28, 1.12), neck=(-0.52, 1.25), head=(-0.78, 1.15),
              r_hip=0.46, r_chest=0.55, r_waist=0.48, r_neck=0.3, r_head=0.3, r_snout=0.16, r_leg=0.15, r_paw=0.18,
              knee=0.5, leg_x=0.3, tail=((0.72, 0.95), (0.88, 0.7)), r_tail=0.06, muscle=1.3, head_drop=0.08, jaw=False)
    at = C.at
    # trunk
    C.bone("trunk1", at("nose", 0, -0.02, -0.02), at("nose", 0, -0.12, -0.35), "head")
    C.bone("trunk2", at("nose", 0, -0.12, -0.35), at("nose", 0, -0.08, -0.72), "trunk1")
    C.tube("Trunk", [V(at("nose", 0, 0.05, 0.02)), V(at("nose", 0, -0.12, -0.35)), V(at("nose", 0, -0.08, -0.72)),
                     V(at("nose", 0, -0.18, -0.85))], [0.13, 0.1, 0.07, 0.05], "fur", None,
           allowed=["head", "trunk1", "trunk2"])
    C.extra_idle.append(lambda P, t: (P.r("trunk1", 'X', -8 * math.sin(6.283 * t)), P.r("trunk2", 'X', -14 * math.sin(6.283 * t - 0.8))))
    # tusks with iron caps
    for mx in (-1, 1):
        base = V(at("snout", 0.12, -0.02, -0.08, mx))
        pts = [base, base + V((0.1 * mx, -0.25, -0.25)), base + V((0.18 * mx, -0.55, -0.12)), base + V((0.12 * mx, -0.7, 0.15))]
        C.tube(f"Tusk{mx}", pts, [0.06, 0.05, 0.035, 0.01], "tusk", "head")
        C.ellipsoid(f"TuskRing{mx}", tuple(pts[1]), (0.07, 0.07, 0.03), "iron", "head", rot=(45, 0, 0))
        C.cone(f"TuskCap{mx}", tuple(pts[2]), tuple(pts[3] + V((0, -0.04, 0.05))), 0.045, "iron", "head", segs=6)
        C.ellipsoid(f"Eye{mx}", at("brow", 0.2, -0.1, 0.0, mx), (0.035, 0.025, 0.025), "eye", "head")
        C.ellipsoid(f"Ear{mx}", at("cran", 0.28, 0.1, -0.02, mx), (0.06, 0.18, 0.2), "fur2", "head", rot=(0, 0, -30 * mx))
    # ice-crusted brow armour
    C.box("BrowPlate", at("brow", 0, -0.12, 0.12), (0.4, 0.12, 0.22), "iron", "head", rot=(-25, 0, 0), bevel=0.3)
    for k in range(3):
        C.cone(f"BrowIce{k}", at("brow", -0.12 + 0.12 * k, -0.16, 0.22), at("brow", -0.14 + 0.14 * k, -0.12, 0.42 - 0.08 * abs(k - 1)),
               0.05, "ice", "head", segs=4)
    # shaggy coat fringe hanging from the belly and shoulders
    for k in range(14):
        y = -0.5 + 0.08 * k
        for mx in (-1, 1):
            C.cone(f"Fringe{k}{mx}", (0.4 * mx, y, 0.85), (0.44 * mx, y + 0.03, 0.5 + 0.05 * (k % 2)), 0.07, "fur2",
                   "chest" if y < 0.05 else "hips", segs=4)
    # spiked howdah on its back
    b = V(C.anch["back"])
    top = C.surf(0, 4, dir=(0, 0, -1), y=b.y)[0]
    b = V((0, b.y, top.z - 0.08))
    C.box("Saddle", tuple(b + V((0, 0, 0.06))), (0.7, 0.8, 0.12), "strap", "chest", bevel=0.3)
    C.box("Howdah", tuple(b + V((0, 0.0, 0.25))), (0.5, 0.55, 0.28), "wood", "chest", bevel=0.2)
    for k, (x, y) in enumerate([(-0.25, -0.27), (0.25, -0.27), (-0.25, 0.27), (0.25, 0.27)]):
        C.cone(f"HSpike{k}", tuple(b + V((x, y, 0.35))), tuple(b + V((x * 1.4, y * 1.3, 0.75))), 0.04, "ice", "chest", segs=4)
    for mx in (-1, 1):
        C.box(f"Strap{mx}", (0.47 * mx, b.y, b.z - 0.3), (0.04, 0.12, 0.5), "strap", "chest", bevel=0.3)
