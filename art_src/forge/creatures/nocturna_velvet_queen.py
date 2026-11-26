"""Nocturna, Velvet Queen (Dark Moon, 6, legend): a vampire bat matriarch, sleek velvet-black fur with a
plush ruby ruff, vast crimson-lined wings, a delicate silver crown between tall ears, fangs and blood-red eyes."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(fur="1e1020", ruff="8a0a2a", wing="2a0a1a", lining="a8102a", bone="3a2030", silver="d8d8e8",
              gem="ff2a4a", eye="ff2a3a", fang="ffffff", skin="5a3a4a")
    C.attack = "dive"
    kits.quad(C, "fur", hip=(0.18, 0.72), chest=(-0.1, 0.9), neck=(-0.18, 1.12), head=(-0.42, 1.2),
              r_hip=0.2, r_chest=0.26, r_waist=0.21, r_neck=0.12, r_head=0.17, r_snout=0.08, r_leg=0.045, r_paw=0.05,
              knee=0.4, leg_x=0.12, tail=((0.32, 0.6),), r_tail=0.05, front=False, head_drop=0.0)
    C.plan, C.hover = "flyer", 0.5
    at = C.at
    C.ellipsoid("Ruff", at("chest", 0, -0.04, 0.16), (0.3, 0.26, 0.14), "ruff", "chest")
    for mx in (-1, 1):
        C.cone(f"Ear{mx}", at("cran", 0.1, 0.02, 0.1, mx), at("cran", 0.2, 0.06, 0.42, mx), 0.08, "fur", "head", segs=6,
               smooth=True)
        C.cone(f"EarIn{mx}", at("cran", 0.1, -0.03, 0.12, mx), at("cran", 0.19, 0.01, 0.38, mx), 0.05, "lining", "head",
               segs=6, smooth=True)
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.08, 0.03, mx), (0.035, 0.02, 0.025), "eye", "head", rot=(0, 0, 25 * mx))
        C.box(f"Brow{mx}", at("brow", 0.07, -0.08, 0.07, mx), (0.08, 0.04, 0.02), "fur", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        C.cone(f"Fang{mx}", at("snout", 0.03, -0.06, -0.04, mx), at("snout", 0.03, -0.07, -0.13, mx), 0.017, "fang", "head",
               segs=5)
    C.ellipsoid("Nose", at("nose", 0, -0.05, 0.02), (0.05, 0.03, 0.04), "skin", "head")
    props.crown(C, at("cran", 0, 0.02, 0.14), 0.08, "silver", "head", points=5, height=0.07, m_gem="gem")
    kits.wings(C, "bone", "wing", shoulder=(0.18, -0.06, 1.0), span=0.95, up=0.6, sweep=0.3, r=0.04, droop=0.75,
               fingers=4, thick=0.02)
    for side, mx in (("L", -1), ("R", 1)):
        el = V(C.bones[f"wing2.{side}"]["head"])
        C.cone(f"Thumb{side}", tuple(el), tuple(el + V((0.02 * mx, -0.08, 0.1))), 0.02, "silver", f"wing2.{side}", segs=4)
    # crimson lining on the wings' inner side
    for side, mx in (("L", -1), ("R", 1)):
        sh = V((0.2 * mx, -0.02, 1.0))
        C.membrane(f"Lining{side}", [tuple(sh), tuple(sh + V((0.35 * mx, 0.08, 0.3))), tuple(sh + V((0.45 * mx, 0.2, -0.25))),
                                     tuple(sh + V((0.05 * mx, 0.28, -0.3)))][::(-1 if mx < 0 else 1)], "lining", None,
                   thick=0.025, allowed=[f"wing.{side}", f"wing2.{side}"])
    C.ellipsoid("Pendant", at("chest", 0, -0.27, 0.06), (0.04, 0.02, 0.05), "gem", "chest")
