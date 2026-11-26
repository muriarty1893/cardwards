"""Sporeling (Mushroom Forest, 2): a small fungal sprout-warrior. Sculpted: a sturdy little stalk body
wrapped in a cloak of overlapping leaves, a speckled red toadstool cap pulled low over two glowing eyes,
stubby root feet, a thorn spear and a pouch of healing spores at its hip."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(stalk="efe2c8", cap="c8282a", spot="fff4e0", gill="e8c8a8", eye="9dff5a", dark="140c0a", leaf="3a8a2a",
              thorn="5a3a20", pouch="8a6a3a", glow="c8ff8a")
    C.attack = "stab"
    cl, at = skulpt.biped(C, hip=0.32, chest=0.56, head=0.72, lean=0.04, shoulder_x=0.15, hip_x=0.08,
                          r_chest=(0.14, 0.12, 0.14), r_waist=(0.12, 0.1, 0.1), r_hips=(0.13, 0.11, 0.08),
                          r_head=(0.11, 0.11, 0.1), r_arm=(0.04, 0.035), r_hand=0.04, r_leg=(0.05, 0.045),
                          r_foot=(0.05, 0.07, 0.035), arm_len=0.3, group="stalk")
    h = at["head"]
    for k in range(10):                                                         # leaf cloak
        a = math.pi * (0.1 + 1.8 * k / 9) + math.pi * 0.5
        cl.add((math.cos(a) * 0.15, 0.02 + math.sin(a) * 0.13, 0.48), (0.06, 0.035, 0.13),
               rot=(0, 0, math.degrees(a) + 90), group="leaf")
    cl.mirror((0.045, h.y - 0.09, h.z + 0.0), (0.025, 0.02, 0.02), group="dark", neg=True)
    body = cl.build({"stalk": "stalk", "leaf": "leaf", "dark": "stalk"}, voxel=0.007, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.006})
    capc = Clay(C, "Cap", res=0.012)
    capc.add((0, h.y + 0.01, h.z + 0.1), (0.21, 0.2, 0.12), group="cap")
    capc.add((0, h.y + 0.01, h.z + 0.04), (0.19, 0.18, 0.04), group="gill")
    cb = capc.build({"cap": "cap", "gill": "gill"}, voxel=0.007, budget=2500, relax=2, bone="head")
    rnd = random.Random(17)
    spots = [V((rnd.uniform(-0.14, 0.14), h.y + rnd.uniform(-0.14, 0.14), h.z + 0.2)) for _ in range(8)]
    recolor(cb, lambda p, n: max(smoothstep(0.04, 0.025, (V((p.x, p.y, 0)) - V((s.x, s.y, 0))).length) for s in spots)
            * smoothstep(0.2, 0.6, n.z), "spot")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, h.y - 0.1, h.z), (0.018, 0.008, 0.014), "eye", "head")
    hr = at["hdR"]
    C.tube("Spear", [hr + V((0, 0.16, -0.24)), hr, hr + V((0, -0.24, 0.36))], [0.014, 0.014, 0.012], "thorn", "forearm.R")
    C.cone("SpearTip", tuple(hr + V((0, -0.24, 0.36))), tuple(hr + V((0, -0.32, 0.48))), 0.025, "thorn", "forearm.R", segs=5)
    C.ellipsoid("Pouch", (-0.15, -0.04, 0.32), (0.05, 0.04, 0.06), "pouch", "hips")
    C.ellipsoid("PouchGlow", (-0.15, -0.08, 0.36), (0.02, 0.02, 0.02), "glow", "hips")
