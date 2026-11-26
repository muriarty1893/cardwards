"""Oasis Alpaca (Sunny Dunes, 4): a hardy desert alpaca that carries water to the wounded. Sculpted: a
sturdy alpaca in a thick cream fleece of soft clumps, a long woolly neck and a calm, knowing face with
banana ears, a woven teal-and-gold saddle blanket with clay water jugs slung either side, and a sprig of
palm tucked in its topknot."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(wool="f4ead8", wool2="e0d0b8", face="d8b890", eye="1a1008", blanket="2a8a8a", blanket2="ffcf3a", jug="c8683a",
              water="3ad8ff", palm="3a8a2a", hoof="3a2a20", rope="8a6a4a")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.3, 0.84), chest=(-0.24, 0.9), r_chest=(0.26, 0.26, 0.26), r_belly=(0.26, 0.3, 0.24),
                         r_hips=(0.24, 0.22, 0.24), leg_x=0.18, r_thigh=0.1, r_shin=0.06, r_paw=0.06, paw_len=1.0,
                         neck=((-0.36, 1.18), (-0.42, 1.42)), r_neck=(0.14, 0.11), head=(-0.48, 1.52),
                         r_head=(0.1, 0.11, 0.09), snout=(-0.66, 1.46), r_snout=(0.065, 0.05), tail=((0.52, 0.92),),
                         r_tail=(0.09, 0.07), digi=False, group="wool")
    h = at["head"]
    for k in range(18):
        a = 2 * math.pi * (k % 6) / 6
        y = -0.3 + 0.24 * (k // 6)
        cl.add((math.cos(a) * 0.24, y, 0.9 + math.sin(a) * 0.22), (0.12, 0.14, 0.12), group="wool")
    for k in range(4):
        cl.add((0, -0.34 - 0.03 * k, 1.12 + 0.1 * k), (0.12, 0.1, 0.1), group="wool")
    cl.add((0, h.y + 0.02, h.z + 0.08), (0.09, 0.09, 0.07), group="wool")            # topknot
    cl.add((0, h.y - 0.06, h.z), (0.075, 0.07, 0.075), group="face")
    cl.chain([tuple(h + V((0, -0.06, -0.01))), tuple(at["snout"])], [0.065, 0.05], group="face")
    body = cl.build({"wool": "wool", "face": "face"}, voxel=0.012, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.03})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.6, "wool2")
    skulpt.eyes(C, [(0.06, h.y - 0.08, h.z + 0.02)], 0.018, "eye", None)
    for mx in (-1, 1):
        C.tube(f"Ear{mx}", [h + V((0.06 * mx, 0.02, 0.06)), h + V((0.1 * mx, 0.0, 0.16)), h + V((0.09 * mx, -0.04, 0.22))],
               [0.025, 0.025, 0.006], "face", "head")
        for tag in ("f", "b"):
            p = V(at["legs"]["L" if mx < 0 else "R"][tag][-1])
            C.ellipsoid(f"Hoof{tag}{mx}", tuple(p + V((0, -0.02, -0.01))), (0.05, 0.06, 0.035), "hoof",
                        f"shin_{tag}.{'L' if mx < 0 else 'R'}")
    blanket = Clay(C, "Blanket", res=0.016)
    for k in range(11):
        a = math.radians(-80 + 16 * k)
        blanket.add((math.sin(a) * 0.36, 0.02, 0.94 + math.cos(a) * 0.32), (0.08, 0.3, 0.022), rot=(0, math.degrees(a), 0),
                    group="b")
    bb = blanket.build({"b": "blanket"}, voxel=0.011, relax=2, budget=2500, ao=0.3)
    recolor(bb, lambda p, n: smoothstep(0.6, 0.85, math.sin(p.y * 30 + p.z * 10)), "blanket2")
    for mx in (-1, 1):
        c = V((0.42 * mx, 0.02, 0.82))
        C.lathe(f"Jug{mx}", [(0.001, -0.12), (0.09, -0.08), (0.1, 0.02), (0.04, 0.1), (0.05, 0.13)], "jug", "chest", segs=12)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(tuple(c)))
        C.ellipsoid(f"Water{mx}", tuple(c + V((0, 0, 0.135))), (0.035, 0.035, 0.01), "water", "chest")
        C.tube(f"JugRope{mx}", [c + V((0, 0, 0.1)), V((0.3 * mx, 0.02, 1.18))], [0.01, 0.01], "rope", "chest")
    for k in range(3):
        a = math.radians(-30 + 30 * k)
        C.cone(f"Palm{k}", tuple(h + V((0, 0.04, 0.12))), tuple(h + V((math.sin(a) * 0.12, 0.1, 0.24))), 0.025, "palm", "head",
               segs=4)
