"""Meerkeep (Sunny Dunes, 2): a meerkat sentinel standing tall on watch. Sculpted: a slim upright meerkat
balanced on its hind legs and tail, a pale chest and belly, dark-ringed watchful eyes on a pointed face,
small ears, a dented bronze helm, a round hide shield and a short spear held ready."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep


def build(C):
    C.palette(fur="c8a06a", fur2="f0dcb0", dark="2a1a0c", eye="1a0a04", bronze="b87a2a", hide="8a5a2a", wood="5a3a1a",
              metal="d8d8d8", stripe="6a4a2a")
    C.attack = "stab"
    cl, at = skulpt.biped(C, hip=0.36, chest=0.66, head=0.88, lean=0.0, shoulder_x=0.1, hip_x=0.07,
                          r_chest=(0.1, 0.09, 0.15), r_waist=(0.1, 0.09, 0.1), r_hips=(0.12, 0.11, 0.1),
                          r_head=(0.08, 0.1, 0.08), r_arm=(0.03, 0.025), r_hand=0.025, r_leg=(0.06, 0.035),
                          r_foot=(0.035, 0.07, 0.025), arm_len=0.22, group="fur")
    h = at["head"]
    cl.chain([(0, -0.08, 0.86), (0, -0.19, 0.84)], [(0.05, 0.05, 0.045), (0.02, 0.02, 0.02)], group="fur")   # snout
    cl.add((0, -0.08, 0.52), (0.07, 0.04, 0.16), group="fur2")
    cl.chain([(0, 0.08, 0.32), (0, 0.22, 0.12), (0, 0.32, 0.02)], [0.05, 0.035, 0.02], group="fur")        # tail prop
    body = cl.build({"fur": "fur", "fur2": "fur2"}, voxel=0.006, budget=5000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.015, "strength": 0.005})
    recolor(body, lambda p, n: smoothstep(0.5, 0.9, math.sin(p.z * 60)) * (0.5 if p.y > 0.02 and p.z < 0.8 else 0.0), "stripe")
    recolor(body, lambda p, n: smoothstep(0.32, 0.38, p.y), "dark")
    skulpt.eyes(C, [(0.04, -0.07, 0.9)], 0.018, "dark", "eye")
    C.ellipsoid("Nose", (0, -0.2, 0.845), (0.012, 0.01, 0.01), "eye", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Ear{mx}", (0.07 * mx, 0.0, 0.9), (0.02, 0.015, 0.025), "dark", "head")
    C.ellipsoid("Helm", (0, -0.01, 0.95), (0.085, 0.09, 0.06), "bronze", "head")
    C.ellipsoid("HelmDent", (0.04, -0.06, 0.98), (0.02, 0.015, 0.015), "stripe", "head")
    hl = at["hdL"]
    props.shield(C, tuple(hl + V((-0.02, -0.06, 0.04))), 0.12, "hide", "bronze", "forearm.L", facing=(0, -1, 0))
    hr = at["hdR"]
    C.tube("Spear", [hr + V((0, 0.1, -0.3)), hr, hr + V((0, -0.06, 0.34))], [0.01, 0.01, 0.009], "wood", "forearm.R")
    C.cone("SpearTip", tuple(hr + V((0, -0.06, 0.34))), tuple(hr + V((0, -0.08, 0.44))), 0.018, "metal", "forearm.R", segs=4)
