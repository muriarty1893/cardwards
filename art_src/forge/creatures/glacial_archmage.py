"""Glacial Archmage (Frost Peaks, 7, legend): a towering ice sorcerer in layered frost robes, a crown of
jagged ice spires, a face hidden but for two cold lights, a ring of orbiting ice shards and a crystal staff."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(robe="1e3a6a", robe2="2a5a9a", trim="cfe8ff", dark="060a14", eye="aef8ff", ice="9ee8ff",
              ice2="e8faff", silver="b8c8d8", wood="2a3a4a")
    C.attack = "cast"
    kits.biped(C, "robe", hip=0.98, chest=1.52, neck=1.72, head_top=2.05, shoulder_x=0.34, hip_x=0.15,
               hand=(0.52, -0.14, 1.0), r_hip=0.24, r_waist=0.2, r_chest=0.32, r_neck=0.08, r_head=0.17,
               r_arm=0.08, r_hand=0.06, r_leg=0.09, lean=0.04)
    h = V(C.anch["head"])
    props.robe(C, "robe", top_z=1.05, bottom_r=0.55, top_r=0.26, hem=0.06, wave=8)
    C.lathe("Robe2", [(0.45, 0.35), (0.3, 0.8), (0.27, 1.0)], "robe2", None, segs=24, wave=(8, 0.08, 0.3),
            allowed=["hips", "leg.L", "leg.R"])
    props.hooded_face(C, "robe2", "dark", "eye", h, r=0.22, eye_gap=0.07, eye_size=0.04)
    # crown of ice spires above the hood
    for k in range(5):
        a = math.pi * (0.15 + 0.7 * k / 4)
        b = h + V((math.cos(a) * 0.17, 0.02 - math.sin(a) * 0.08, 0.2))
        C.cone(f"Spire{k}", tuple(b), tuple(b + V((math.cos(a) * 0.1, 0.02, 0.28 + 0.12 * (k == 2)))), 0.05, "ice", "head",
               segs=5)
    # high frost collar and pauldrons
    c = V(C.anch["chest"])
    for k in range(7):
        a = math.pi * (0.1 + 0.8 * k / 6)
        b = c + V((math.cos(a) * 0.26, 0.08 + math.sin(a) * 0.05, 0.18))
        C.cone(f"Collar{k}", tuple(b), tuple(b + V((math.cos(a) * 0.12, 0.08, 0.3))), 0.06, "trim", "chest", segs=4)
    for side, mx in (("L", -1), ("R", 1)):
        sh = V(C.anch["sh" + side])
        C.ellipsoid(f"Pauldron{side}", tuple(sh + V((0.02 * mx, 0, 0.06))), (0.17, 0.17, 0.1), "silver", f"arm.{side}")
        C.cone(f"PSpike{side}", tuple(sh + V((0.06 * mx, 0, 0.1))), tuple(sh + V((0.2 * mx, 0.02, 0.32))), 0.05, "ice",
               f"arm.{side}", segs=5)
    C.box("Sash", (0, -0.27, 0.7), (0.16, 0.04, 0.7), "trim", "hips", rot=(-12, 0, 0), bevel=0.3, taper=(0.6, 1))
    # orbiting ice shards around the waist (spin on their own bone)
    C.bone("orbit", (0, 0, 1.15), (0, 0, 1.4), "root")
    for k in range(5):
        a = 2 * math.pi * k / 5
        p = V((math.cos(a) * 0.62, math.sin(a) * 0.62, 1.2 + 0.12 * math.sin(3 * a)))
        C.cone(f"Shard{k}", tuple(p - V((0, 0, 0.12))), tuple(p + V((0, 0, 0.14))), 0.06, "ice2", "orbit", segs=4)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 72 * t))
    # crystal staff
    top = props.staff(C, C.anch["hdR"], "wood", "forearm.R", length=1.9, up=1.0, top="crystal", m_top="ice", top_r=0.11)
    for side in ("L", "R"):
        C.ellipsoid(f"Hand{side}", C.anch["hd" + side], (0.055, 0.055, 0.06), "trim", f"forearm.{side}")
    # frost forming over the left palm
    hl = V(C.anch["hdL"])
    for k in range(4):
        a = 2 * math.pi * k / 4
        C.cone(f"Frost{k}", tuple(hl + V((0, -0.1, 0.08))), tuple(hl + V((math.cos(a) * 0.12, -0.1, 0.08 + math.sin(a) * 0.12))),
               0.025, "ice2", "forearm.L", segs=4)
