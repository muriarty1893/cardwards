"""Shadow Peddler (Dark Moon, 3): a hunched night merchant. Sculpted: a bent, shuffling figure wrapped in
a patched cloak, a long hooked nose jutting from the hood, two lantern eyes in the dark, long grasping
fingers holding a curved knife, and a towering pack of trinkets, jars and lanterns strapped to its back."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(cloak="2a2440", patch="4a3a6a", skin="6a7a9a", eye="ffd23a", dark="06060c", pack="5a3a24", jar1="5affc0",
              jar2="c87aff", jar3="ffb03a", rope="8a7050", metal="a8a8b8", lamp="ffe08a")
    C.attack = "stab"
    cl, at = skulpt.biped(C, hip=0.6, chest=0.96, head=1.12, lean=0.3, shoulder_x=0.2, hip_x=0.1,
                          r_chest=(0.2, 0.17, 0.18), r_waist=(0.17, 0.15, 0.14), r_hips=(0.18, 0.15, 0.12),
                          r_head=(0.1, 0.11, 0.11), r_arm=(0.06, 0.05), r_hand=0.035, r_leg=(0.06, 0.05),
                          r_foot=(0.05, 0.09, 0.04), arm_len=0.5, group="cloak")
    h = at["head"]
    cl.chain([(0, 0.0, 0.66), (0, 0.04, 0.3), (0, 0.06, 0.08)], [(0.2, 0.18, 0.14), (0.24, 0.2, 0.14), (0.26, 0.22, 0.06)],
             group="cloak")
    cl.add((0, h.y + 0.01, h.z + 0.02), (0.13, 0.14, 0.14), group="cloak")
    cl.add((0, h.y - 0.09, h.z), (0.08, 0.07, 0.09), group="dark", neg=True)
    cl.add((0, h.y - 0.02, h.z), (0.07, 0.07, 0.08), group="dark")
    for k, (x, z) in enumerate([(0.14, 0.4), (-0.16, 0.7), (0.1, 0.86)]):
        cl.add((x, -0.18, z), (0.06, 0.03, 0.06), group="patch")
    body = cl.build({"cloak": "cloak", "dark": "dark", "patch": "patch"}, voxel=0.009, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.008})
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.035 * mx, h.y - 0.09, h.z + 0.02), (0.018, 0.008, 0.014), "eye", "head")
    C.tube("Nose", [h + V((0, -0.08, -0.01)), h + V((0, -0.18, -0.03)), h + V((0, -0.2, -0.08))], [0.025, 0.016, 0.006],
           "skin", "head")
    hr = at["hdR"]
    C.tube("Knife", [hr, hr + V((0, -0.08, 0.06)), hr + V((0.02, -0.16, 0.06))], [0.014, 0.01, 0.002], "metal", "forearm.R")
    C.box("Pack", (0, 0.24, 0.86), (0.34, 0.24, 0.5), "pack", "chest", rot=(-15, 0, 0), bevel=0.2)
    for k, (x, z, c) in enumerate([(-0.12, 1.16, "jar1"), (0.08, 1.2, "jar2"), (0.18, 0.98, "jar3"), (-0.2, 0.84, "jar2"),
                                   (0.0, 1.3, "jar3")]):
        C.lathe(f"Jar{k}", [(0.001, 0.0), (0.05, 0.02), (0.055, 0.1), (0.025, 0.14)], c, "chest", segs=10)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((x, 0.24, z)))
    C.tube("PackRope", [V((-0.18, 0.1, 1.06)), V((0.18, 0.1, 1.06))], [0.012, 0.012], "rope", "chest")
    C.tube("LampHook", [V((0.2, 0.2, 1.16)), V((0.3, 0.16, 1.06))], [0.008, 0.008], "metal", "chest")
    C.ellipsoid("Lamp", (0.3, 0.16, 1.0), (0.04, 0.04, 0.05), "lamp", "chest")
