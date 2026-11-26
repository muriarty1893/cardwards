"""Duchess Bonbonpaw (Candy Hills, 7, legend): an aristocratic cat noblewoman, haughty half-lidded eyes,
a towering powdered wig of whipped cream topped with a cherry, a gown of layered chocolate ruffles, a lace
fan in one paw and a box of bonbons in the other."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(fur="f4e6d6", patch="d8843a", gown="7a2a4a", ruffle="ffb0d0", choc="5a2a18", cream="fff8f0",
              cherry="e8102a", eye="3ad87a", dark="1a0a10", gold="ffd23a", nose="ff7aa0", fan="f8f0ff")
    C.attack = "swipe"
    kits.biped(C, "fur", hip=0.8, chest=1.25, neck=1.42, head_top=1.75, shoulder_x=0.22, hip_x=0.12,
               hand=(0.4, -0.12, 0.85), r_hip=0.2, r_waist=0.14, r_chest=0.22, r_neck=0.08, r_head=0.25,
               r_arm=0.06, r_hand=0.06, r_leg=0.08, r_foot=0.07)
    h = V(C.anch["head"])
    props.robe(C, "gown", top_z=0.85, bottom_r=0.55, top_r=0.18, hem=0.07, wave=10)
    for k in range(3):
        C.lathe(f"Ruffle{k}", [(0.56 - 0.1 * k, 0.04 + 0.22 * k), (0.6 - 0.1 * k, 0.1 + 0.22 * k)], "ruffle" if k != 1 else "choc",
                None, segs=28, wave=(12, 0.08, 0.3), allowed=["hips", "leg.L", "leg.R", "shin.L", "shin.R"])
    c = V(C.anch["chest"])
    C.ellipsoid("Bodice", tuple(c + V((0, 0, -0.04))), (0.23, 0.2, 0.25), "gown", "chest")
    C.lathe("Collar", [(0.12, 0.0), (0.26, 0.1), (0.24, 0.16)], "ruffle", "chest", segs=24, wave=(10, 0.1, 0.18))
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(c + V((0, 0, 0.1))))
    # cat face: patch, ears, haughty eyes, whiskers
    C.ellipsoid("Patch", tuple(h + V((0.1, -0.15, 0.09))), (0.12, 0.11, 0.09), "patch", "head")
    for mx in (-1, 1):
        C.cone(f"Ear{mx}", tuple(h + V((0.15 * mx, 0.0, 0.15))), tuple(h + V((0.24 * mx, 0.02, 0.38))), 0.08,
               "patch" if mx > 0 else "fur", "head", segs=6, smooth=True)
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.09 * mx, -0.225, 0.03))), (0.055, 0.02, 0.03), "eye", "head",
                    rot=(0, 15 * mx, 0))
        C.box(f"Lid{mx}", tuple(h + V((0.09 * mx, -0.23, 0.065))), (0.12, 0.03, 0.03), "fur", "head",
              rot=(0, 10 * mx, 0), bevel=0.4)
        for k in (-1, 1):
            C.tube(f"Whisker{mx}{k}", [h + V((0.07 * mx, -0.235, -0.05 + 0.015 * k)),
                                       h + V((0.28 * mx, -0.16, -0.04 + 0.05 * k))], [0.005, 0.003], "dark", "head")
    C.ellipsoid("Nose", tuple(h + V((0, -0.25, -0.03))), (0.025, 0.015, 0.018), "nose", "head")
    # whipped-cream wig with a cherry
    for k, (x, y, z, s) in enumerate([(0, 0.02, 0.2, 0.2), (0.12, 0.05, 0.3, 0.13), (-0.12, 0.05, 0.3, 0.13),
                                      (0, 0.04, 0.38, 0.15), (0, 0.04, 0.52, 0.1)]):
        C.ellipsoid(f"Wig{k}", tuple(h + V((x, y + 0.04, z + 0.06))), (s, s, s * 0.85), "cream", "head")
    C.ellipsoid("Cherry", tuple(h + V((0, 0.08, 0.7))), (0.055, 0.055, 0.055), "cherry", "head")
    C.tube("CherryStem", [h + V((0, 0.08, 0.74)), h + V((0.03, 0.1, 0.84))], [0.008, 0.006], "choc", "head")
    # lace fan (right) and bonbon box (left)
    hr = V(C.anch["hdR"])
    pts = [tuple(hr)] + [tuple(hr + V((math.cos(a) * 0.28, -0.05, math.sin(a) * 0.28)))
                         for a in [math.radians(d) for d in (20, 45, 70, 95, 120, 145)]]
    C.membrane("Fan", pts, "fan", "forearm.R", thick=0.01)
    hl = V(C.anch["hdL"])
    C.box("Box", tuple(hl + V((0, -0.08, 0.04))), (0.22, 0.16, 0.06), "gold", "forearm.L", bevel=0.3)
    for k in range(3):
        C.ellipsoid(f"Bonbon{k}", tuple(hl + V((-0.06 + 0.06 * k, -0.08, 0.09))), (0.03, 0.03, 0.025), "choc",
                    "forearm.L")
    # tail curling from under the gown
    C.bone("tail1", (0, 0.12, 0.7), (0, 0.45, 0.6), "hips")
    C.bone("tail2", (0, 0.45, 0.6), (0, 0.55, 0.95), "tail1")
    C.tail = ["tail1", "tail2"]
    C.tube("Tail", [(0, 0.3, 0.55), (0, 0.48, 0.62), (0, 0.55, 0.95), (0.05, 0.48, 1.08)], [0.05, 0.045, 0.04, 0.03],
           "patch", None, allowed=["tail1", "tail2"])
