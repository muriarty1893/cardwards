"""Jellywobble (Candy Hills, 4): a quivering golem of layered gelatin. Sculpted: a squat stack of three
flavoured jelly tiers bulging like a dessert mould, a cream band between each layer, candies and fruit
pressed into the sides, a cross face pressed into the top layer, a cherry on top and two big jelly fists."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(j1="ff3a6a", j2="ffd23a", j3="3ad87a", cream="fff8f0", eye="1a0a10", c1="7a3aff", c2="3ad8ff", cherry="c8102a")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.36, chest=0.72, head=1.0, lean=0.0, shoulder_x=0.38, hip_x=0.16,
                          r_chest=(0.34, 0.32, 0.16), r_waist=(0.36, 0.34, 0.14), r_hips=(0.38, 0.36, 0.14),
                          r_head=(0.28, 0.27, 0.13), r_arm=(0.07, 0.07), r_hand=0.13, r_leg=(0.1, 0.09),
                          r_foot=(0.1, 0.12, 0.05), arm_len=0.42, group="j3")
    h = at["head"]
    cl.add((0, 0, 0.38), (0.38, 0.36, 0.16), group="j3")
    cl.add((0, 0, 0.68), (0.33, 0.31, 0.15), group="j2")
    cl.add((0, 0, 0.94), (0.27, 0.26, 0.14), group="j1")
    for z, r in ((0.54, 0.36), (0.82, 0.3)):
        cl.add((0, 0, z), (r, r * 0.96, 0.035), group="cream")
    cl.mirror((0.08, -0.25, 0.97), (0.03, 0.025, 0.02), group="j1", neg=True)
    cl.add((0, -0.27, 1.02), (0.1, 0.03, 0.02), rot=(0, 0, 0), group="j1")             # cross brow
    for sx in (-1, 1):
        cl.add(tuple(at["hd" + ("L" if sx < 0 else "R")] + V((0, 0, -0.04))), (0.13, 0.13, 0.12), group="j1")
    body = cl.build({"j1": "j1", "j2": "j2", "j3": "j3", "cream": "cream"}, voxel=0.011, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.004})
    recolor(body, lambda p, n: smoothstep(0.88, 1.0, n.z) * 0.5, "cream")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.08 * mx, -0.265, 0.96), (0.025, 0.012, 0.02), "eye", "head")
    C.box("Mouth", (0, -0.27, 0.88), (0.08, 0.01, 0.012), "eye", "head", bevel=0.4)
    C.ellipsoid("Cherry", (0, 0, 1.12), (0.06, 0.06, 0.06), "cherry", "head")
    C.tube("CherryStem", [V((0, 0, 1.16)), V((0.03, 0.02, 1.26))], [0.008, 0.006], "j3", "head")
    for k, (a, z, c) in enumerate([(30, 0.4, "c1"), (150, 0.42, "c2"), (80, 0.7, "cherry"), (220, 0.68, "c1"),
                                   (300, 0.38, "c2")]):
        ar = math.radians(a)
        hit, nor = C.surf(0, z, dir=(-math.cos(ar), -math.sin(ar), 0), y=0)
        if hit is not None:
            C.ellipsoid(f"Candy{k}", tuple(hit - nor * 0.02), (0.045, 0.04, 0.04), c, "hips" if z < 0.55 else "chest")
