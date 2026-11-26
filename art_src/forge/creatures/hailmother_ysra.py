"""Hailmother Ysra (Frost Peaks, 8, legend): a floating storm-witch of the peaks, pale blue skin, a mane
of wind-whipped white hair, a crown of hailstones, wings of frozen mist and a storm of hail orbiting her."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(skin="9ac8e8", hair="f4faff", dress="2a4a8a", trim="d8f0ff", eye="ffffff", dark="0a1a3a",
              ice="aef4ff", hail="e8f8ff", wing="cfeaff", lips="3a5aaa")
    C.attack = "cast"
    kits.biped(C, "skin", hip=1.0, chest=1.45, neck=1.62, head_top=1.92, shoulder_x=0.25, hip_x=0.13,
               hand=(0.48, -0.15, 1.05), r_hip=0.18, r_waist=0.13, r_chest=0.2, r_neck=0.06, r_head=0.15,
               r_arm=0.05, r_hand=0.045, legs=False, hover=0.4)
    h = V(C.anch["head"])
    # flowing gown that becomes a tail of mist
    C.lathe("Gown", [(0.06, 0.15), (0.2, 0.45), (0.3, 0.75), (0.24, 0.95), (0.16, 1.1)], "dress", None, segs=24,
            wave=(6, 0.12, 0.15), allowed=["hips", "tail1", "tail2"])
    C.ellipsoid("Bodice", tuple(V(C.anch["chest"]) + V((0, 0, -0.05))), (0.21, 0.17, 0.22), "dress", "chest")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.14, 0.02))), (0.03, 0.012, 0.016), "eye", "head",
                    rot=(0, 15 * mx, 0))
        C.box(f"Brow{mx}", tuple(h + V((0.055 * mx, -0.14, 0.055))), (0.07, 0.02, 0.012), "dark", "head",
              rot=(0, 20 * mx, 0), bevel=0.4)
    C.box("Lips", tuple(h + V((0, -0.145, -0.07))), (0.05, 0.01, 0.012), "lips", "head", bevel=0.4)
    # wind-whipped hair streaming back
    for k in range(9):
        a = math.pi * (k / 8)
        b = h + V((math.cos(a) * 0.13, 0.04, 0.04 + math.sin(a) * 0.1))
        C.tube(f"Hair{k}", [b, b + V((math.cos(a) * 0.12, 0.3, 0.05)), b + V((math.cos(a) * 0.2, 0.62, -0.1 + 0.05 * (k % 3)))],
               [0.05, 0.04, 0.008], "hair", "head")
    # hailstone crown
    for k in range(7):
        a = math.pi * (0.1 + 0.8 * k / 6)
        b = h + V((math.cos(a) * 0.14, 0.02 - math.sin(a) * 0.05, 0.14))
        C.cone(f"Crown{k}", tuple(b), tuple(b + V((0, 0.02, 0.16 + 0.1 * (k == 3)))), 0.035, "ice", "head", segs=5)
    # wings of frozen mist
    kits.wings(C, "trim", "wing", shoulder=(0.12, 0.12, 1.45), span=0.85, up=0.55, sweep=0.3, r=0.02, droop=0.55,
               fingers=3, thick=0.015)
    # storm of hail orbiting her
    C.bone("orbit", (0, 0, 1.1), (0, 0, 1.35), "root")
    for k in range(7):
        a = 2 * math.pi * k / 7
        r = 0.58 + 0.08 * (k % 2)
        C.ellipsoid(f"Hail{k}", (math.cos(a) * r, math.sin(a) * r, 1.0 + 0.3 * math.sin(2 * a)), (0.06, 0.06, 0.06),
                    "hail", "orbit")
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 360 / 7 * t))
    # sleet gathering in both hands
    for side in ("L", "R"):
        hd = V(C.anch["hd" + side])
        C.ellipsoid(f"Orb{side}", tuple(hd + V((0, -0.08, 0.06))), (0.08, 0.08, 0.08), "ice", f"forearm.{side}")
