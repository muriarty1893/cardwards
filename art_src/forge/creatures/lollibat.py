"""Lollibat (Candy Hills, 3): a sugar-mad fruit bat, wings striped like peppermint, big sour-green eyes,
oversized ears and a mouth stained blue from stolen lollipops; one clutched in its feet."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(fur="5a2a6a", fur2="c88ad8", wing="ff3a7a", wing2="fff0f6", bone="3a1a3a", eye="c8ff3a", pupil="0a1a04",
              fang="ffffff", stick="ffffff", pop="3ad8ff", tongue="3a8aff")
    C.attack = "dive"
    kits.quad(C, "fur", hip=(0.1, 0.62), chest=(-0.06, 0.78), neck=(-0.12, 0.92), head=(-0.3, 0.98),
              r_hip=0.15, r_chest=0.19, r_waist=0.16, r_neck=0.1, r_head=0.16, r_snout=0.07, r_leg=0.035, r_paw=0.04,
              knee=0.4, leg_x=0.1, tail=((0.2, 0.55),), r_tail=0.04, front=False)
    C.plan, C.hover = "flyer", 0.45
    at = C.at
    C.ellipsoid("Ruff", at("chest", 0, -0.04, 0.1), (0.2, 0.17, 0.12), "fur2", "chest")
    for mx in (-1, 1):
        C.cone(f"Ear{mx}", at("cran", 0.09, 0.02, 0.08, mx), at("cran", 0.22, 0.04, 0.36, mx), 0.08, "fur", "head", segs=6,
               smooth=True)
        C.cone(f"EarIn{mx}", at("cran", 0.09, -0.02, 0.1, mx), at("cran", 0.21, 0.0, 0.32, mx), 0.05, "wing", "head", segs=6,
               smooth=True)
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.07, 0.03, mx), (0.05, 0.03, 0.05), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.075, -0.1, 0.03, mx), (0.015, 0.01, 0.035), "pupil", "head")
        C.cone(f"Fang{mx}", at("snout", 0.025, -0.05, -0.04, mx), at("snout", 0.025, -0.06, -0.11, mx), 0.014, "fang", "head",
               segs=4)
    C.ellipsoid("Tongue", at("snout", 0, -0.05, -0.06), (0.035, 0.02, 0.02), "tongue", "head")
    kits.wings(C, "bone", "wing", shoulder=(0.14, -0.04, 0.84), span=0.75, up=0.5, sweep=0.25, r=0.03, droop=0.6,
               fingers=4, thick=0.015)
    for side, mx in (("L", -1), ("R", 1)):
        el = V(C.bones[f"wing2.{side}"]["head"])
        for k in range(3):
            C.ellipsoid(f"Stripe{side}{k}", tuple(el + V((0.14 * mx * k, 0.1 + 0.05 * k, -0.15 - 0.08 * k))),
                        (0.05, 0.12, 0.015), "wing2", f"wing2.{side}", rot=(0, 0, 40 * mx))
    # lollipop clutched in the feet
    paw = V(C.bones["shin_b.R"]["tail"])
    C.tube("Stick", [paw + V((-0.1, 0, 0)), paw + V((-0.1, -0.05, -0.25))], [0.012, 0.012], "stick", "shin_b.R")
    C.ellipsoid("Pop", tuple(paw + V((-0.1, -0.06, -0.3))), (0.09, 0.025, 0.09), "pop", "shin_b.R")
    C.ellipsoid("PopSwirl", tuple(paw + V((-0.1, -0.085, -0.3))), (0.05, 0.01, 0.05), "wing2", "shin_b.R")
