"""Leaf Finch (Mushroom Forest, 2): a fierce little forest raptor-finch. Sculpted: a compact, puffed
bird with a hunter's scowl, feathers like layered green leaves, a pale yellow breast, a hooked thorn
beak, a crest of fern fronds, and talons of polished bark."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(leaf="3a8a2a", leaf2="7ac83a", belly="e8d870", beak="c8783a", eye="1a1008", ring="ffd23a", bark="5a3a20")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.06, 0.4), (0, -0.04, 0.58), "root")
    C.bone("head", (0, -0.04, 0.58), (0, -0.16, 0.78), "hips")
    C.bone("tail1", (0, 0.12, 0.42), (0, 0.34, 0.34), "hips")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.07 * sx, 0.04, 0.32), (0.07 * sx, 0.0, 0.18), "hips")
        C.bone(f"shin.{side}", (0.07 * sx, 0.0, 0.18), (0.07 * sx, -0.02, 0.03), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    skulpt.wing_bones(C, (0.14, 0.0, 0.52), (0.36, 0.06, 0.62), (0.62, 0.16, 0.56), parent="hips")
    cl = Clay(C, "Body", res=0.014)
    cl.add((0, 0.02, 0.44), (0.16, 0.2, 0.17), group="leaf")
    cl.add((0, -0.06, 0.42), (0.13, 0.12, 0.14), group="belly")
    cl.add((0, -0.06, 0.62), (0.12, 0.12, 0.11), group="leaf")                     # head
    cl.add((0, -0.14, 0.66), (0.09, 0.05, 0.03), rot=(-10, 0, 0), group="leaf2")    # scowl brow
    cl.mirror((0.055, -0.15, 0.63), (0.025, 0.02, 0.02), group="leaf", neg=True)
    for sx in (-1, 1):
        cl.chain([(0.14 * sx, 0.0, 0.5), (0.16 * sx, 0.12, 0.42), (0.13 * sx, 0.24, 0.34)],
                 [(0.04, 0.1, 0.09), (0.04, 0.09, 0.07), 0.02], group="leaf2")
    cl.chain([(0, 0.14, 0.42), (0, 0.32, 0.34)], [(0.08, 0.05, 0.03), (0.09, 0.04, 0.02)], group="leaf")
    body = cl.build({"leaf": "leaf", "leaf2": "leaf2", "belly": "belly"}, voxel=0.007, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.015, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(0.3, 0.8, math.sin(p.z * 70 + abs(p.x) * 30)) * 0.4 * (1.0 if p.y > -0.05 else 0.0),
            "leaf2")
    for mx in (-1, 1):
        C.ellipsoid(f"Ring{mx}", (0.055 * mx, -0.16, 0.63), (0.022, 0.012, 0.022), "ring", "head")
        C.ellipsoid(f"Eye{mx}", (0.058 * mx, -0.17, 0.63), (0.012, 0.008, 0.014), "eye", "head")
        for k in (-1, 0, 1):
            C.tube(f"Toe{mx}{k}", [V((0.07 * mx, -0.02, 0.03)), V((0.07 * mx + 0.03 * k, -0.08, 0.01))], [0.012, 0.005],
                   "bark", f"shin.{'L' if mx < 0 else 'R'}")
        C.tube(f"Shin{mx}", [V((0.07 * mx, 0.0, 0.2)), V((0.07 * mx, -0.02, 0.03))], [0.016, 0.012], "bark",
               f"shin.{'L' if mx < 0 else 'R'}")
    C.cone("Beak", (0, -0.17, 0.61), (0, -0.25, 0.56), 0.03, "beak", "head", segs=6, smooth=True)
    for k in range(4):
        b = V((0, -0.08 + 0.04 * k, 0.72))
        C.cone(f"Fern{k}", tuple(b), tuple(b + V((0.02 * (k % 2 * 2 - 1), 0.1, 0.14 - 0.02 * k))), 0.02, "leaf2", "head",
               segs=4)
