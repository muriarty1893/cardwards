"""Rimeback Stegosaur (Frost Peaks, 9): an armoured stegosaur. Sculpted: a massive arched body, high at
the hips and sloping down to a low, small horned skull, columnar legs, frost-rimed hide with a pale belly,
a double row of great ice-crystal plates down its back and a club-spiked thagomizer of icicles."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep, cracks


def build(C):
    C.palette(hide="4a6a6a", hide2="8aaab0", belly="c8d8d0", ice="9ee8ff", ice2="e0faff", eye="ffd23a", dark="0e1418",
              horn="d8d0c0", pupil="0a0a0a")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.22, 0.98), chest=(-0.32, 0.8), r_chest=(0.3, 0.32, 0.28), r_belly=(0.33, 0.36, 0.32),
                         r_hips=(0.3, 0.28, 0.32), leg_x=0.26, r_thigh=0.16, r_shin=0.12, r_paw=0.13, paw_len=1.0,
                         neck=((-0.58, 0.62),), r_neck=(0.15,), head=(-0.74, 0.52), r_head=(0.12, 0.15, 0.1),
                         snout=(-0.9, 0.46), r_snout=(0.08, 0.06), tail=((0.54, 0.9), (0.8, 0.74), (1.0, 0.66)),
                         r_tail=(0.2, 0.05), digi=False, group="hide", belly_group="belly")
    h = at["head"]
    cl.mirror((0.08, h.y - 0.06, h.z + 0.05), (0.04, 0.04, 0.03), group="hide2")
    body = cl.build({"hide": "hide", "belly": "belly", "hide2": "hide2"}, voxel=0.017, budget=11000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.03, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.75, n.z) * 0.85, "belly")
    recolor(body, lambda p, n: smoothstep(0.6, 0.95, n.z) * 0.7, "hide2")
    recolor(body, lambda p, n: cracks(p, 0.12, 0.05, seed=47) * smoothstep(0.4, 0.9, n.z) * 0.6, "ice2")
    skulpt.eyes(C, [(0.085, h.y - 0.08, h.z + 0.03)], 0.018, "eye", "pupil")
    for mx in (-1, 1):
        C.cone(f"Horn{mx}", (0.07 * mx, h.y + 0.04, h.z + 0.08), (0.12 * mx, h.y + 0.12, h.z + 0.16), 0.025, "horn", "head",
               segs=5)
    # two staggered rows of great ice plates along the arched back
    spine = [(-0.58, 0.72), (-0.42, 0.98), (-0.24, 1.12), (-0.04, 1.22), (0.16, 1.28), (0.36, 1.24), (0.56, 1.1),
             (0.74, 0.92), (0.9, 0.8)]
    for k, (y, z) in enumerate(spine):
        sz = 0.16 + 0.22 * math.sin(math.pi * (k + 0.5) / len(spine))
        for mx in (-1, 1):
            yy = y + (0.05 if mx > 0 else -0.05)
            bone = "neck" if yy < -0.5 else "chest" if yy < -0.05 else "hips" if yy < 0.5 else "tail1" if yy < 0.78 else "tail2"
            C.cone(f"Plate{k}{mx}", (0.06 * mx, yy, z - 0.06), (0.12 * mx, yy + 0.03, z + sz), sz * 0.45,
                   "ice" if k % 2 else "ice2", bone, segs=4)
    t = V((0, 1.0, 0.66))
    for k, d in enumerate([(0.28, 0.1, 0.12), (-0.28, 0.1, 0.12), (0.24, 0.2, 0.2), (-0.24, 0.2, 0.2)]):
        C.cone(f"Thag{k}", tuple(t), tuple(t + V(d)), 0.05, "ice2", "tail3", segs=5)
