"""Tundra Stomper (Frost Peaks, 7): a war-mammoth of the high ice. Sculpted: a towering domed head and a
high humped back sloping to the rear, a shaggy grey-blue coat hanging in long skirts over pillar legs, a
long trunk, sweeping tusks capped in iron, small ears, an ice-crusted armoured brow plate and a frosted
howdah of spikes strapped to its back."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fur="5a6a7a", fur2="8a9aaa", tusk="f2ead8", iron="3a3f48", ice="aee8ff", eye="ffd23a", dark="0e1218",
              wood="4a3a2a", strap="7a2a2a", pupil="0a0a0a")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.36, 0.98), chest=(-0.28, 1.08), r_chest=(0.38, 0.38, 0.38), r_belly=(0.36, 0.38, 0.34),
                         r_hips=(0.32, 0.3, 0.32), leg_x=0.26, r_thigh=0.17, r_shin=0.15, r_paw=0.16, paw_len=1.0,
                         neck=((-0.5, 1.2),), r_neck=(0.28,), head=(-0.62, 1.32), r_head=(0.27, 0.26, 0.3),
                         snout=(-0.86, 1.0), r_snout=(0.13, 0.11), tail=((0.6, 0.94), (0.68, 0.74)),
                         r_tail=(0.04, 0.02), digi=False, hump=(0.26, 0.28, 0.2), group="fur")
    h = at["head"]
    for k in range(16):                                                        # long hanging coat skirts
        a = 2 * math.pi * k / 16
        y = 0.04 + math.sin(a) * 0.46
        cl.add((math.cos(a) * 0.36, y, 0.72), (0.08, 0.09, 0.24), group="fur2")
    cl.mirror((0.26, h.y + 0.08, h.z - 0.02), (0.05, 0.12, 0.12), group="fur")    # small ears
    cl.chain([tuple(at["snout"]), (0, -0.9, 0.7), (0, -0.84, 0.44), (0, -0.78, 0.32)], [0.12, 0.09, 0.07, 0.06],
             group="fur")                                                        # trunk
    cl.mirror((0.13, h.y - 0.18, h.z + 0.02), (0.03, 0.03, 0.03), group="fur", neg=True)
    body = cl.build({"fur": "fur", "fur2": "fur2"}, voxel=0.018, budget=11000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.035, "strength": 0.035})
    recolor(body, lambda p, n: smoothstep(0.6, 1.0, n.z) * 0.5, "ice")
    skulpt.eyes(C, [(0.14, h.y - 0.2, h.z + 0.02)], 0.022, "eye", "pupil")
    for mx in (-1, 1):
        b = V((0.14 * mx, -0.86, 1.06))
        pts = [b, b + V((0.08 * mx, -0.18, -0.26)), b + V((0.12 * mx, -0.4, -0.22)), b + V((0.06 * mx, -0.5, 0.06))]
        C.tube(f"Tusk{mx}", pts, [0.06, 0.05, 0.035, 0.01], "tusk", "head")
        C.cone(f"TuskCap{mx}", tuple(V(pts[2]).lerp(V(pts[3]), 0.5)), tuple(pts[3]), 0.04, "iron", "head", segs=6)
    C.ellipsoid("BrowPlate", (0, h.y - 0.12, h.z + 0.18), (0.24, 0.12, 0.08), "iron", "head", rot=(-25, 0, 0))
    for k in range(3):
        C.cone(f"BrowIce{k}", (-0.12 + 0.12 * k, h.y - 0.12, h.z + 0.24), (-0.14 + 0.14 * k, h.y - 0.2, h.z + 0.38), 0.04,
               "ice", "head", segs=4)
    C.box("Howdah", (0, 0.0, 1.62), (0.48, 0.52, 0.16), "wood", "chest", bevel=0.2)
    C.box("Strap", (0, 0.0, 1.28), (0.82, 0.12, 0.66), "strap", "chest", bevel=0.4)
    for k in range(6):
        x = (-0.22, 0.22)[k % 2]
        y = -0.22 + 0.22 * (k // 2)
        C.cone(f"HSpike{k}", (x, y, 1.68), (x * 1.2, y, 1.92), 0.04, "ice", "chest", segs=4)
