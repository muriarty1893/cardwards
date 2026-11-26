"""Lollibat (Candy Hills, 3): a sugar-mad fruit bat. Sculpted: a round, fuzzy purple body with a pale
chest, a fox-like face with huge sour-green eyes and oversized ears, a mouth stained blue from stolen
lollipops with little fangs, peppermint-striped wings, and a lollipop clutched in its feet."""
import math
from mathutils import Vector as V
from forge import kits, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fur="5a2a6a", fur2="c88ad8", wing="ff3a7a", wing2="fff0f6", bone="3a1a3a", eye="c8ff3a", pupil="0a1a04",
              fang="ffffff", stick="ffffff", pop="3ad8ff", tongue="3a8aff")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.45
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.04, 0.52), (0, 0.0, 0.72), "root")
    C.bone("chest", (0, 0.0, 0.72), (0, -0.02, 0.86), "hips")
    C.bone("head", (0, -0.02, 0.86), (0, -0.06, 1.1), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.07 * sx, 0.04, 0.48), (0.08 * sx, 0.0, 0.36), "hips")
        C.bone(f"shin.{side}", (0.08 * sx, 0.0, 0.36), (0.06 * sx, -0.04, 0.28), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    cl = Clay(C, "Body", res=0.014)
    cl.add((0, 0.02, 0.64), (0.16, 0.15, 0.19), group="fur")
    cl.add((0, -0.08, 0.64), (0.1, 0.08, 0.13), group="fur2")
    cl.add((0, -0.04, 0.9), (0.14, 0.13, 0.12), group="fur")
    cl.chain([(0, -0.12, 0.88), (0, -0.22, 0.86)], [(0.07, 0.06, 0.06), (0.04, 0.03, 0.035)], group="fur2")
    for sx in (-1, 1):
        cl.chain([(0.08 * sx, -0.02, 0.98), (0.15 * sx, 0.0, 1.12), (0.18 * sx, 0.01, 1.22)],
                 [(0.07, 0.025, 0.06), (0.06, 0.02, 0.05), 0.01], group="fur")
        cl.chain([(0.07 * sx, 0.04, 0.48), (0.08 * sx, 0.0, 0.34)], [0.04, 0.025], group="fur")
    body = cl.build({"fur": "fur", "fur2": "fur2"}, voxel=0.007, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.015, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(0.02, 0.0, abs(p.z - 0.85)) * (1.0 if p.y < -0.18 else 0.0), "tongue")
    skulpt.eyes(C, [(0.06, -0.14, 0.93)], 0.04, "eye", "pupil")
    for mx in (-1, 1):
        C.cone(f"Fang{mx}", (0.02 * mx, -0.22, 0.84), (0.02 * mx, -0.22, 0.8), 0.008, "fang", "head", segs=4)
    kits.wings(C, "bone", "wing", shoulder=(0.12, 0.0, 0.76), span=0.62, up=0.32, sweep=0.18, r=0.025, droop=0.45,
               fingers=4, thick=0.014)
    for side, mx in (("L", -1), ("R", 1)):
        for k in range(3):
            C.ellipsoid(f"Stripe{side}{k}", (0.3 * mx + 0.1 * mx * k, 0.1 + 0.04 * k, 0.86 - 0.05 * k), (0.03, 0.1, 0.012),
                        "wing2", f"wing2.{side}" if k else f"wing.{side}", rot=(0, 0, -30 * mx))
    C.tube("PopStick", [V((0, -0.06, 0.28)), V((0, -0.08, 0.1))], [0.008, 0.008], "stick", "shin.R")
    C.ellipsoid("Pop", (0, -0.08, 0.06), (0.07, 0.025, 0.07), "pop", "shin.R")
