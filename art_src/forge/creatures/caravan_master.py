"""Caravan Master (Sunny Dunes, 6): a great armoured camel of the trade roads. Sculpted: a tall,
long-legged camel with a big hump, a long curving neck and a proud sneering face with heavy-lidded eyes,
a fringed and tasselled caparison, and a towering load of chests, rugs and amphorae lashed over the hump
with lanterns and bells hanging from it."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="c89a5a", hide2="a8784a", rug="b8202a", rug2="2a5aa8", tassel="ffcf3a", chest="6a3a1a", metal="d8b83a",
              jar="d86a3a", eye="1a1008", dark="1a1008", lamp="ffe08a", rope="8a6a4a", pupil="0a0604")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.34, 1.0), chest=(-0.22, 1.04), r_chest=(0.22, 0.26, 0.24), r_belly=(0.2, 0.3, 0.2),
                         r_hips=(0.2, 0.2, 0.22), leg_x=0.15, r_thigh=0.09, r_shin=0.045, r_paw=0.07, paw_len=1.2,
                         neck=((-0.42, 0.96), (-0.6, 1.1), (-0.66, 1.4)), r_neck=(0.12, 0.09, 0.08),
                         head=(-0.72, 1.52), r_head=(0.09, 0.13, 0.09), snout=(-0.94, 1.46), r_snout=(0.07, 0.055),
                         tail=((0.56, 0.92), (0.62, 0.7)), r_tail=(0.03, 0.015), group="hide")
    h = at["head"]
    cl.add((0, 0.06, 1.3), (0.18, 0.24, 0.18), group="hide")                         # the hump
    cl.add(tuple(at["snout"] + V((0, 0.0, -0.04))), (0.06, 0.06, 0.04), group="hide2")   # droopy lip
    cl.mirror((0.07, h.y - 0.05, h.z + 0.04), (0.04, 0.04, 0.025), rot=(0, 0, -15), group="hide2")
    body = cl.build({"hide": "hide", "hide2": "hide2"}, voxel=0.012, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.5, "hide2")
    skulpt.eyes(C, [(0.075, h.y - 0.06, h.z + 0.02)], 0.022, "eye", "pupil")
    for mx in (-1, 1):
        C.ellipsoid(f"Lid{mx}", (0.08 * mx, h.y - 0.07, h.z + 0.04), (0.03, 0.03, 0.014), "hide2", "head")
    # caparison with fringe and tassels
    cape = Clay(C, "Caparison", res=0.016)
    for k in range(11):
        a = math.radians(-80 + 16 * k)
        cape.add((math.sin(a) * 0.26, 0.06, 1.12 + math.cos(a) * 0.26), (0.07, 0.4, 0.022), rot=(0, math.degrees(a), 0),
                 group="rug")
    cb = cape.build({"rug": "rug"}, voxel=0.011, relax=2, budget=3000, ao=0.3)
    recolor(cb, lambda p, n: smoothstep(0.55, 0.8, math.sin(p.y * 40)) * 0.8, "rug2")
    for mx in (-1, 1):
        for k in range(6):
            C.cone(f"Tassel{mx}{k}", (0.27 * mx, -0.24 + 0.1 * k, 0.9), (0.28 * mx, -0.24 + 0.1 * k, 0.8), 0.02, "tassel",
                   "chest" if k < 3 else "hips", segs=4)
    # the towering load
    C.box("Chest1", (0, 0.0, 1.56), (0.36, 0.3, 0.2), "chest", "chest", bevel=0.15)
    C.box("Chest1Band", (0, 0.0, 1.56), (0.37, 0.05, 0.21), "metal", "chest", bevel=0.15)
    C.box("Chest2", (0.02, 0.06, 1.76), (0.26, 0.22, 0.18), "rug2", "chest", rot=(0, 0, 8), bevel=0.3)
    C.tube("RugRoll", [V((-0.22, 0.2, 1.48)), V((0.22, 0.2, 1.48))], [0.07, 0.07], "rug", "hips")
    for mx in (-1, 1):
        C.lathe(f"Jar{mx}", [(0.001, 0.0), (0.07, 0.04), (0.08, 0.12), (0.03, 0.2), (0.04, 0.24)], "jar", "hips", segs=10)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0.3 * mx, 0.24, 1.02)))
        C.tube(f"LampChain{mx}", [V((0.22 * mx, -0.12, 1.5)), V((0.3 * mx, -0.14, 1.3))], [0.006, 0.006], "metal", "chest")
        C.ellipsoid(f"Lamp{mx}", (0.3 * mx, -0.14, 1.26), (0.04, 0.04, 0.05), "lamp", "chest")
    C.ellipsoid("Bell", (0, -0.5, 0.9), (0.04, 0.04, 0.05), "metal", "neck")
