"""Shadow Peddler (Dark Moon, 3): a hunched night merchant wrapped in a patched cloak, a towering pack of
trinkets and jars strapped to its back, a long hooked nose under the hood, lantern eyes and a curved
knife hidden in one sleeve."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(cloak="2a2440", patch="4a3a6a", skin="6a7a9a", eye="ffd23a", dark="06060c", pack="5a3a24",
              jar1="5affc0", jar2="c87aff", jar3="ffb03a", rope="8a7050", metal="a8a8b8", lamp="ffe08a")
    C.attack = "stab"
    kits.biped(C, "cloak", hip=0.72, chest=1.08, neck=1.2, head_top=1.45, shoulder_x=0.24, hip_x=0.13,
               hand=(0.38, -0.2, 0.68), r_hip=0.22, r_waist=0.21, r_chest=0.24, r_neck=0.08, r_head=0.14,
               r_arm=0.065, r_hand=0.055, r_leg=0.08, r_foot=0.08, lean=0.3)
    h = V(C.anch["head"])
    props.robe(C, "cloak", top_z=0.78, bottom_r=0.4, top_r=0.24, hem=0.06, wave=6)
    props.hooded_face(C, "cloak", "dark", "eye", h, r=0.17, eye_gap=0.05, eye_size=0.028)
    C.cone("Nose", tuple(h + V((0, -0.15, -0.02))), tuple(h + V((0, -0.32, -0.1))), 0.035, "skin", "head", segs=8,
           smooth=True)
    for k, (x, z) in enumerate([(0.15, 0.95), (-0.12, 0.6), (0.18, 0.4)]):
        C.decal(f"Patch{k}", x, z, (0.07, 0.07, 0.02), "patch", "chest" if z > 0.8 else "hips", spin=20 * k)
    # the towering pack
    c = V(C.anch["chest"])
    pk = c + V((0, 0.36, 0.08))
    C.box("Pack", tuple(pk), (0.48, 0.32, 0.62), "pack", "chest", bevel=0.2)
    C.box("Bedroll", tuple(pk + V((0, 0, 0.38))), (0.56, 0.22, 0.16), "patch", "chest", bevel=0.5)
    for k, (x, z, m) in enumerate([(-0.18, 0.12, "jar1"), (0.0, 0.0, "jar2"), (0.18, 0.15, "jar3"), (-0.1, -0.2, "jar3"),
                                   (0.12, -0.18, "jar1")]):
        p = pk + V((x, 0.16, z))
        C.lathe(f"Jar{k}", [(0.001, 0), (0.06, 0.01), (0.065, 0.08), (0.035, 0.12), (0.04, 0.15)], m, "chest", segs=10)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(p - V((0, 0, 0.07))))
    C.tube("PackStrapL", [c + V((-0.15, -0.2, 0.14)), c + V((-0.16, 0.1, 0.24)), pk + V((-0.18, -0.1, 0.25))], [0.025] * 3,
           "rope", "chest")
    C.tube("PackStrapR", [c + V((0.15, -0.2, 0.14)), c + V((0.16, 0.1, 0.24)), pk + V((0.18, -0.1, 0.25))], [0.025] * 3,
           "rope", "chest")
    # dangling lantern and trinkets
    lp = pk + V((0.3, 0.0, 0.2))
    C.tube("LampHook", [pk + V((0.24, 0, 0.32)), lp + V((0, 0, 0.12))], [0.012, 0.012], "metal", "chest")
    C.lathe("Lamp", [(0.03, -0.08), (0.06, -0.05), (0.06, 0.05), (0.03, 0.09)], "lamp", "chest", segs=10)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(lp))
    for k in range(3):
        C.ellipsoid(f"Trinket{k}", tuple(pk + V((-0.3, 0.0, 0.15 - 0.12 * k))), (0.03, 0.03, 0.04), "metal", "chest")
    # curved knife from the right sleeve
    props.blade(C, C.anch["hdR"], "metal", "pack", "forearm.R", length=0.35, width=0.045, direction=(0, -1, 0.15),
                curve=0.08, guard=0.08)
    for side in ("L", "R"):
        C.ellipsoid(f"Hand{side}", C.anch["hd" + side], (0.055, 0.055, 0.055), "skin", f"forearm.{side}")
