"""Pain Shroom (Mushroom Forest, 3): a vicious little toadstool brute. Sculpted: a squat, thick stalk body
on stubby root legs, long clawed root arms, a scowling face with a jagged grin carved under a sickly
purple cap that bristles with thorns, and venom dripping from its thorny gills."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(stalk="c8b8a0", cap="6a2a7a", thorn="2a1a24", venom="aaff3a", eye="ffe23a", dark="120a10", root="5a3e28",
              gill="d8a8d8")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.36, chest=0.62, head=0.78, lean=0.08, shoulder_x=0.22, hip_x=0.11,
                          r_chest=(0.21, 0.18, 0.2), r_waist=(0.19, 0.16, 0.14), r_hips=(0.19, 0.16, 0.1),
                          r_head=(0.16, 0.15, 0.13), r_arm=(0.05, 0.045), r_hand=0.05, r_leg=(0.07, 0.06),
                          r_foot=(0.07, 0.09, 0.04), arm_len=0.42, group="stalk")
    h = at["head"]
    cl.add((0, h.y - 0.12, h.z + 0.06), (0.12, 0.05, 0.03), rot=(-10, 0, 0), group="stalk")   # scowl
    cl.mirror((0.06, h.y - 0.13, h.z + 0.02), (0.03, 0.025, 0.02), group="dark", neg=True)
    cl.add((0, h.y - 0.14, h.z - 0.07), (0.08, 0.03, 0.025), group="dark", neg=True)
    body = cl.build({"stalk": "stalk", "dark": "stalk"}, voxel=0.008, budget=7000, relax=2,
                    texture={"type": 'STUCCI', "scale": 0.02, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(0.25, 0.05, p.z), "root")
    capc = Clay(C, "Cap", res=0.014)
    capc.add((0, -0.02, 1.0), (0.36, 0.34, 0.16), group="cap")
    capc.add((0, -0.02, 0.92), (0.33, 0.31, 0.06), group="gill")
    cb = capc.build({"cap": "cap", "gill": "gill"}, voxel=0.009, budget=3500, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.01}, bone="head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, h.y - 0.145, h.z + 0.02), (0.022, 0.01, 0.014), "eye", "head")
        side = "L" if mx < 0 else "R"
        hd = at["hd" + side]
        for k in (-1, 0, 1):
            C.tube(f"Claw{side}{k}", [hd, hd + V((0.03 * k, -0.06, -0.06)), hd + V((0.04 * k, -0.08, -0.14))],
                   [0.018, 0.012, 0.003], "root", f"forearm.{side}")
    for k in range(6):
        x = -0.06 + 0.024 * k
        C.cone(f"Grin{k}", (x, h.y - 0.155, h.z - 0.06), (x, h.y - 0.16, h.z - 0.09 + 0.06 * (k % 2)), 0.01, "stalk", "head",
               segs=4)
    for k in range(14):
        a = 2 * math.pi * k / 14
        r = 0.2 + 0.12 * (k % 2)
        b = V((math.cos(a) * r, -0.02 + math.sin(a) * r * 0.95, 1.04 + 0.08 * (1 - r / 0.32)))
        C.cone(f"Thorn{k}", tuple(b), tuple(b + V((math.cos(a) * 0.06, math.sin(a) * 0.06, 0.12))), 0.025, "thorn", "head",
               segs=4)
    for k in range(4):
        a = math.pi * (0.25 + 0.5 * k / 3)
        C.ellipsoid(f"Venom{k}", (math.cos(a) * 0.26, -0.02 - math.sin(a) * 0.26, 0.86), (0.018, 0.018, 0.03), "venom",
                    "head")
