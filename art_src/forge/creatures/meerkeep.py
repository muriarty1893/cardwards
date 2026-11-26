"""Meerkeep (Sunny Dunes, 2): a meerkat sentinel standing tall on watch, a dented bronze helm, dark-ringed
watchful eyes, a round hide shield and a short spear held ready."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(fur="c8a06a", fur2="f0dcb0", dark="2a1a0c", eye="1a0a04", bronze="b87a2a", hide="8a5a2a", wood="5a3a1a",
              metal="d8d8d8", stripe="6a4a2a")
    C.attack = "stab"
    kits.biped(C, "fur", hip=0.5, chest=0.85, neck=1.0, head_top=1.2, shoulder_x=0.14, hip_x=0.09,
               hand=(0.24, -0.1, 0.6), r_hip=0.16, r_waist=0.13, r_chest=0.14, r_neck=0.07, r_head=0.1,
               r_arm=0.04, r_hand=0.035, r_leg=0.06, r_foot=0.06)
    h = V(C.anch["head"])
    C.ellipsoid("Snout", tuple(h + V((0, -0.1, -0.03))), (0.05, 0.08, 0.04), "fur2", "head")
    C.ellipsoid("Nose", tuple(h + V((0, -0.17, -0.02))), (0.02, 0.015, 0.015), "dark", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Mask{mx}", tuple(h + V((0.045 * mx, -0.08, 0.02))), (0.04, 0.03, 0.035), "dark", "head")
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.05 * mx, -0.1, 0.02))), (0.015, 0.01, 0.015), "fur2", "head")
        C.ellipsoid(f"Ear{mx}", tuple(h + V((0.09 * mx, 0.02, 0.02))), (0.03, 0.02, 0.03), "dark", "head")
    C.decal("Belly", 0, 0.7, (0.1, 0.25, 0.04), "fur2", "chest")
    for k in range(3):
        C.decal(f"BackStripe{k}", 0.02 * (k - 1), 0.75 + 0.08 * k, (0.08, 0.015, 0.015), "stripe", "chest", dir=(0, -1, 0))
    # bronze helm with a crest
    C.ellipsoid("Helm", tuple(h + V((0, 0.0, 0.05))), (0.12, 0.12, 0.09), "bronze", "head")
    C.box("Crest", tuple(h + V((0, 0.02, 0.15))), (0.03, 0.18, 0.06), "bronze", "head", bevel=0.4)
    # tail as a prop
    C.bone("tail1", (0, 0.1, 0.45), (0, 0.28, 0.12), "hips")
    C.tail = ["tail1"]
    C.tube("Tail", [V((0, 0.1, 0.45)), V((0, 0.24, 0.25)), V((0, 0.3, 0.06))], [0.045, 0.035, 0.015], "fur", "tail1")
    props.shield(C, tuple(V(C.anch["hdL"]) + V((-0.03, -0.1, 0.05))), 0.14, "hide", "bronze", "forearm.L", facing=(0, -1, 0),
                 boss="bronze")
    hr = V(C.anch["hdR"])
    C.tube("Spear", [hr + V((0, 0.05, -0.3)), hr, hr + V((0, -0.05, 0.45))], [0.014, 0.014, 0.014], "wood", "forearm.R")
    C.cone("SpearTip", tuple(hr + V((0, -0.05, 0.45))), tuple(hr + V((0, -0.06, 0.58))), 0.03, "metal", "forearm.R", segs=4)
