"""Bog Biter (Mushroom Forest, 2): a squat swamp croc-toad that is all jaw. Sculpted: a flat, wide body
low to the ground, a huge underbitten lower jaw jutting forward with fangs pointing up, bulging yellow
eyes perched on top of the skull, leech-slick hide streaked with algae, splayed webbed feet and a lily
pad stuck to its back."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="3d5a34", belly="a3a86a", eye="ffd23a", pupil="0d0d0a", tooth="efe6c8", mouth="5a1a1e", algae="7fbf3a",
              pad="2f7a3a", leech="2a1a2a")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.22, 0.3), chest=(-0.16, 0.34), r_chest=(0.27, 0.24, 0.17), r_belly=(0.26, 0.24, 0.15),
                         r_hips=(0.22, 0.2, 0.15), leg_x=0.26, r_thigh=0.08, r_shin=0.05, r_paw=0.08, paw_len=1.1,
                         neck=((-0.32, 0.38),), r_neck=(0.2,), head=(-0.44, 0.42), r_head=(0.24, 0.2, 0.15),
                         snout=(-0.66, 0.38), r_snout=(0.16, 0.08), tail=((0.42, 0.22), (0.58, 0.14)),
                         r_tail=(0.08, 0.02), digi=False, group="hide", belly_group="belly", jaw=True)
    h = at["head"]
    cl.add((0, -0.56, 0.24), (0.24, 0.2, 0.1), group="belly")                       # huge underbite jaw
    cl.add((0, -0.6, 0.31), (0.2, 0.16, 0.035), group="mouth", neg=True)
    for sx in (-1, 1):
        cl.add((0.12 * sx, h.y - 0.02, h.z + 0.14), (0.08, 0.08, 0.08), group="hide")  # eye turrets
    body = cl.build({"hide": "hide", "belly": "belly", "mouth": "mouth"}, voxel=0.011, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.55, 0.85, math.sin(p.x * 25 + p.y * 9)) * smoothstep(0.3, 0.8, n.z) * 0.7,
            "algae")
    skulpt.eyes(C, [(0.12, h.y - 0.06, h.z + 0.18)], 0.045, "eye", "pupil", slit=True)
    for k in range(9):
        a = math.pi * (0.1 + 0.8 * k / 8)
        x, y = math.cos(a) * 0.2, -0.56 - math.sin(a) * 0.16
        C.cone(f"Fang{k}", (x, y, 0.3), (x * 1.02, y - 0.01, 0.42 + 0.03 * (k % 2)), 0.02, "tooth", "jaw", segs=4)
    C.lathe("Pad", [(0.001, 0.0), (0.2, 0.0), (0.21, 0.015)], "pad", "hips", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0.04, 0.12, 0.48)))
    for k in range(2):
        C.ellipsoid(f"Leech{k}", (0.24 - 0.48 * k, -0.05 + 0.1 * k, 0.4), (0.03, 0.06, 0.025), "leech", "chest")
