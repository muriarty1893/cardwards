"""Blizzard Titan (Frost Peaks, 7): a towering storm-yeti. Sculpted: a hulking ape-like giant in shaggy
blue-white fur, a slate-blue face with a heavy brow and eyes like pale stars, a long icicle beard, a
glacier grown over its shoulders and back in jagged crystal plates, and a club of solid glacier ice
dragged in one huge fist."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep


def build(C):
    C.palette(fur="dfe8f2", fur2="a8bcd0", skin="5a7a9a", ice="7ad8ff", ice2="cff4ff", eye="ffffff", dark="0a1a2a",
              horn="c8d8e8")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.86, chest=1.46, head=1.72, lean=0.2, shoulder_x=0.46, hip_x=0.2,
                          r_chest=(0.42, 0.32, 0.34), r_waist=(0.3, 0.24, 0.22), r_hips=(0.28, 0.22, 0.18),
                          r_head=(0.16, 0.16, 0.16), r_arm=(0.16, 0.14), r_hand=0.13, r_leg=(0.17, 0.13),
                          r_foot=(0.13, 0.17, 0.07), arm_len=0.95, hand_fwd=0.1, group="fur")
    h = at["head"]
    for k in range(14):                                                        # shaggy fur clumps
        a = 2 * math.pi * k / 7
        z = 1.15 + 0.25 * (k // 7)
        cl.add((math.cos(a) * 0.36, 0.0 + math.sin(a) * 0.24, z), (0.13, 0.13, 0.17), rot=(math.sin(a) * 15, 0, 0),
               group="fur")
    cl.add((0, h.y - 0.15, h.z - 0.02), (0.12, 0.08, 0.12), group="skin")          # face
    cl.add((0, h.y - 0.2, h.z + 0.07), (0.13, 0.05, 0.035), group="skin")         # brow
    cl.mirror((0.055, h.y - 0.22, h.z + 0.02), (0.03, 0.025, 0.025), group="skin", neg=True)
    cl.add((0, h.y - 0.22, h.z - 0.09), (0.07, 0.03, 0.02), group="dark", neg=True)
    body = cl.build({"fur": "fur", "skin": "skin", "dark": "skin"}, voxel=0.018, budget=11000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.03})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.7, "fur2")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.055 * mx, h.y - 0.225, h.z + 0.02), (0.022, 0.01, 0.016), "eye", "head")
    for k in range(5):                                                         # icicle beard
        x = -0.07 + 0.035 * k
        C.cone(f"Beard{k}", (x, h.y - 0.2, h.z - 0.1), (x * 0.7, h.y - 0.18, h.z - 0.28 - 0.05 * (k % 2)), 0.03, "ice2",
               "head", segs=5)
    # a glacier grown over shoulders and back: jagged crystal plates
    for k, (x, y, z, ht) in enumerate([(0.42, 0.0, 1.62, 0.3), (0.3, 0.12, 1.7, 0.36), (0.12, 0.2, 1.66, 0.3),
                                       (-0.42, 0.0, 1.62, 0.28), (-0.28, 0.12, 1.72, 0.38), (-0.1, 0.22, 1.62, 0.26),
                                       (0.2, 0.26, 1.4, 0.24), (-0.2, 0.26, 1.42, 0.22), (0.0, 0.3, 1.2, 0.2)]):
        d = V((x * 0.6, 0.35, 1.0)).normalized()
        C.cone(f"Glacier{k}", (x, y, z - 0.08), tuple(V((x, y, z)) + d * ht), 0.09, "ice" if k % 2 else "ice2", "chest",
               segs=5)
    hr = at["hdR"]
    C.cone("Club", tuple(hr + V((0, 0.0, 0.08))), tuple(hr + V((0.04, -0.2, -0.62))), 0.16, "ice", "forearm.R", segs=6)
    for k in range(4):
        a = 2 * math.pi * k / 4
        C.cone(f"ClubSpike{k}", tuple(hr + V((0.02, -0.14, -0.42))),
               tuple(hr + V((0.02 + math.cos(a) * 0.16, -0.14 + math.sin(a) * 0.12, -0.46))), 0.04, "ice2", "forearm.R",
               segs=4)
