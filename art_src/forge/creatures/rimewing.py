"""Rimewing (Frost Peaks, 4): a great snowy owl that hunts in silence, white plumage barred with ice blue,
tufted horn-like ears, burning gold eyes in a pale disc face, and flight feathers tipped with icicles."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(plume="f4f8ff", bar="7ab8e0", disc="e8f0f8", eye="ffc23a", pupil="0a0a0a", beak="3a4a5a", ice="aef4ff",
              talon="2a3a4a")
    C.attack = "dive"
    C.relax = 0.7
    kits.quad(C, "plume", hip=(0.1, 0.55), chest=(-0.04, 0.72), neck=(-0.08, 0.9), head=(-0.22, 1.0),
              r_hip=0.22, r_chest=0.26, r_waist=0.24, r_neck=0.16, r_head=0.2, r_snout=0.08, r_leg=0.04, r_paw=0.05,
              knee=0.35, leg_x=0.1, tail=((0.22, 0.45),), r_tail=0.08, jaw=False, front=False)
    C.plan, C.hover = "flyer", 0.4
    at = C.at
    C.ellipsoid("Disc", at("brow", 0, -0.06, 0.0), (0.2, 0.06, 0.16), "disc", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.08, -0.11, 0.02, mx), (0.05, 0.02, 0.05), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.08, -0.125, 0.02, mx), (0.025, 0.01, 0.025), "pupil", "head")
        C.box(f"Brow{mx}", at("brow", 0.08, -0.11, 0.07, mx), (0.1, 0.03, 0.025), "bar", "head", rot=(0, 25 * mx, 0), bevel=0.4)
        C.cone(f"Tuft{mx}", at("cran", 0.12, 0.0, 0.12, mx), at("cran", 0.2, 0.04, 0.3, mx), 0.05, "plume", "head", segs=5)
    C.cone("Beak", at("brow", 0, -0.12, -0.04), at("brow", 0, -0.16, -0.12), 0.03, "beak", "head", segs=6, smooth=True)
    for k in range(8):
        y = -0.1 + 0.05 * (k % 4)
        z = 0.55 + 0.08 * (k // 4) + 0.05 * (k % 2)
        C.decal(f"Bar{k}", 0.08 * (k % 3 - 1), z, (0.05, 0.015, 0.015), "bar", "chest", spin=10)
    kits.wings(C, "plume", "plume", shoulder=(0.18, 0.0, 0.82), span=0.85, up=0.45, sweep=0.3, r=0.05, droop=0.55, fingers=4)
    for side, mx in (("L", -1), ("R", 1)):
        tip = V(C.bones[f"wing2.{side}"]["tail"])
        for k in range(4):
            p = tip - V((0.1 * mx * k, -0.06 * k, 0.1 * k))
            C.cone(f"Icicle{side}{k}", tuple(p), tuple(p + V((0.08 * mx, 0.1, -0.12))), 0.03, "ice", f"wing2.{side}", segs=4)
    for side in ("L", "R"):
        paw = V(C.bones[f"shin_b.{side}"]["tail"])
        for k in (-1, 0, 1):
            C.cone(f"Talon{side}{k}", tuple(paw + V((0.03 * k, -0.03, 0.02))), tuple(paw + V((0.05 * k, -0.1, -0.03))), 0.015,
                   "talon", f"shin_b.{side}", segs=4)
