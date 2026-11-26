"""Leaf Finch (Mushroom Forest, 2): a fierce little forest raptor-finch, feathers like layered green leaves,
a hooked thorn beak, a crest of fern fronds and talons of polished bark."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(leaf="3a8a2a", leaf2="7ac83a", belly="e8d870", beak="c8783a", eye="1a1008", ring="ffd23a",
              bark="5a3a20")
    C.attack = "dive"
    kits.quad(C, "leaf", hip=(0.16, 0.5), chest=(-0.1, 0.62), neck=(-0.2, 0.82), head=(-0.42, 0.86),
              r_hip=0.18, r_chest=0.22, r_waist=0.2, r_neck=0.1, r_head=0.14, r_snout=0.05, r_leg=0.035, r_paw=0.04,
              knee=0.25, leg_x=0.1, tail=((0.35, 0.5), (0.52, 0.46)), r_tail=0.08, jaw=False, front=False)
    C.plan, C.hover = "flyer", 0.4
    at = C.at
    C.decal("Belly", 0, 0.55, (0.16, 0.2, 0.04), "belly", "chest")
    C.cone("Beak", at("snout", 0, 0.0, 0.0), at("snout", 0, -0.16, -0.07), 0.05, "beak", "head", segs=8, smooth=True)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.075, -0.03, 0.02, mx), (0.03, 0.02, 0.028), "ring", "head")
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.08, -0.05, 0.02, mx), (0.016, 0.01, 0.016), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.075, -0.03, 0.06, mx), (0.07, 0.03, 0.02), "leaf", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
    for k in range(4):
        C.cone(f"Crest{k}", at("cran", 0, 0.0 + 0.04 * k, 0.1), at("cran", 0, 0.12 + 0.06 * k, 0.3 - 0.04 * k), 0.035,
               "leaf2", "head", segs=4)
    kits.wings(C, "leaf", "leaf", shoulder=(0.14, -0.06, 0.72), span=0.7, up=0.4, sweep=0.3, r=0.03, droop=0.45,
               fingers=4, membrane=True)
    for side, mx in (("L", -1), ("R", 1)):
        tip = V(C.bones[f"wing2.{side}"]["tail"])
        for k in range(3):
            C.ellipsoid(f"LeafFeather{side}{k}", tuple(tip + V((-0.08 * k * mx, 0.08 + 0.06 * k, -0.06 * k))),
                        (0.1, 0.05, 0.015), "leaf2", f"wing2.{side}", rot=(0, 0, 30 * mx))
    for k in range(3):
        C.ellipsoid(f"TailLeaf{k}", tuple(V(C.anch["t1"]) + V((0.06 * (k - 1), 0.12, 0.0))), (0.05, 0.16, 0.015),
                    "leaf2" if k == 1 else "leaf", "tail2", rot=(0, 0, 20 * (k - 1)))
    for side in ("L", "R"):
        paw = V(C.bones[f"shin_b.{side}"]["tail"])
        for k in (-1, 0, 1):
            C.cone(f"Talon{side}{k}", tuple(paw + V((0.025 * k, -0.03, 0.02))), tuple(paw + V((0.04 * k, -0.09, -0.02))),
                   0.013, "bark", f"shin_b.{side}", segs=4)
