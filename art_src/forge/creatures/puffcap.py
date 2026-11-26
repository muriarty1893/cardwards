"""Puffcap (Mushroom Forest, 3): a waddling puffball mushroom. Sculpted: a round, bulging, warty puffball
body squatting on stubby root legs, a crater on its crown venting clouds of healing spores, grumpy
heavy-lidded eyes and a downturned mouth."""
import math
import random
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(puff="e8dcc0", puff2="c8b890", crater="6a5a3a", spore="c8ff8a", eye="1a1408", lid="b8a880", root="6a4a2a",
              wart="d8c8a8")
    C.plan, C.attack = "biped", "slam"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.28), (0, 0, 0.56), "root")
    C.bone("chest", (0, 0, 0.56), (0, -0.02, 0.82), "hips")
    C.bone("head", (0, -0.02, 0.82), (0, -0.02, 1.0), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.14 * sx, 0, 0.22), (0.15 * sx, -0.02, 0.1), "hips")
        C.bone(f"shin.{side}", (0.15 * sx, -0.02, 0.1), (0.15 * sx, -0.02, 0.02), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
        C.bone(f"arm.{side}", (0.3 * sx, -0.04, 0.56), (0.38 * sx, -0.08, 0.44), "chest")
        C.bone(f"forearm.{side}", (0.38 * sx, -0.08, 0.44), (0.4 * sx, -0.14, 0.36), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    cl = Clay(C, "Body", res=0.018)
    cl.add((0, 0, 0.56), (0.38, 0.36, 0.36), group="puff")
    cl.add((0, 0, 0.92), (0.12, 0.12, 0.06), group="crater", neg=True)             # crater
    cl.add((0, 0, 0.88), (0.1, 0.1, 0.04), group="crater")
    rnd = random.Random(13)
    for k in range(24):
        a, b = rnd.uniform(0, 6.28), rnd.uniform(0.2, 1.4)
        cl.add((math.cos(a) * 0.37 * math.sin(b), math.sin(a) * 0.35 * math.sin(b), 0.56 + 0.35 * math.cos(b)),
               (0.035, 0.035, 0.03), group="wart")
    for sx in (-1, 1):
        cl.chain([(0.14 * sx, 0, 0.24), (0.15 * sx, -0.02, 0.04)], [0.08, 0.07], group="root")
        cl.add((0.15 * sx, -0.06, 0.03), (0.08, 0.1, 0.035), group="root")
        cl.chain([(0.3 * sx, -0.04, 0.56), (0.38 * sx, -0.08, 0.44), (0.4 * sx, -0.14, 0.36)], [0.05, 0.04, 0.035],
                 group="puff2")
        cl.add((0.12 * sx, -0.34, 0.62), (0.05, 0.03, 0.03), group="puff", neg=True)
    cl.add((0, -0.35, 0.5), (0.07, 0.03, 0.015), group="crater", neg=True)
    body = cl.build({"puff": "puff", "puff2": "puff2", "wart": "wart", "crater": "crater", "root": "root"}, voxel=0.01,
                    budget=7000, relax=2, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.6, "puff2")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.12 * mx, -0.35, 0.61), (0.025, 0.012, 0.02), "eye", "head")
        C.ellipsoid(f"Lid{mx}", (0.12 * mx, -0.355, 0.635), (0.045, 0.025, 0.022), "lid", "head", rot=(0, 15 * mx, 0))
    for k in range(7):
        a = 2 * math.pi * k / 7
        r = 0.04 + 0.03 * (k % 2)
        C.ellipsoid(f"Spore{k}", (math.cos(a) * r, math.sin(a) * r, 0.98 + 0.06 * k), (0.05 + 0.01 * (k % 3),) * 3, "spore",
                    "head")
