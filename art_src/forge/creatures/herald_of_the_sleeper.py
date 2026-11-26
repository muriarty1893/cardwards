"""Herald of the Sleeper (Dark Moon, 3): a floating cultist of something vast beneath the sea. Sculpted:
a tall, narrow hooded robe of deep teal with glowing trim, a single huge eye filling the hood where a face
should be, tentacles writhing out from under the hem, and a staff hung with a tarnished bell."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(robe="10303a", trim="3affd0", eye="f4f0c8", pupil="1a0a20", tent="4a2a6a", sucker="c8a0ff", bell="c8a03a",
              wood="2a2018", dark="05080a")
    C.attack = "cast"
    cl, at = skulpt.biped(C, hip=0.86, chest=1.24, head=1.48, lean=0.08, shoulder_x=0.2, hip_x=0.1,
                          r_chest=(0.18, 0.15, 0.18), r_waist=(0.15, 0.13, 0.14), r_hips=(0.17, 0.15, 0.12),
                          r_head=(0.12, 0.12, 0.13), r_arm=(0.06, 0.06), r_hand=0.04, arm_len=0.5, legs=False,
                          hover=0.3, group="robe")
    h = at["head"]
    cl.chain([(0, 0, 0.86), (0, 0.02, 0.6), (0, 0.04, 0.36)], [(0.18, 0.16, 0.14), (0.22, 0.2, 0.14), (0.25, 0.22, 0.06)],
             group="robe")
    for k in range(8):
        a = 2 * math.pi * k / 8
        cl.add((math.cos(a) * 0.2, 0.02 + math.sin(a) * 0.18, 0.6), (0.04, 0.04, 0.2), rot=(0, 0, math.degrees(a)), group="robe")
    cl.add((0, h.y + 0.02, h.z + 0.04), (0.14, 0.15, 0.17), group="robe")             # hood
    cl.add((0, h.y + 0.06, h.z + 0.22), (0.05, 0.06, 0.06), rot=(-30, 0, 0), group="robe")
    cl.add((0, h.y - 0.1, h.z + 0.02), (0.1, 0.08, 0.12), group="dark", neg=True)
    cl.add((0, h.y - 0.02, h.z + 0.02), (0.09, 0.09, 0.1), group="dark")
    body = cl.build({"robe": "robe", "dark": "dark"}, voxel=0.009, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.006})
    recolor(body, lambda p, n: (1.0 if 0.39 < p.z < 0.44 or (abs(p.x) < 0.025 and p.y < -0.1 and 0.4 < p.z < 1.2) else 0.0),
            "trim")
    C.ellipsoid("Eye", (0, h.y - 0.1, h.z + 0.02), (0.07, 0.04, 0.08), "eye", "head")
    C.ellipsoid("Pupil", (0, h.y - 0.135, h.z + 0.02), (0.018, 0.012, 0.05), "pupil", "head")
    for k in range(7):
        a = 2 * math.pi * k / 7
        b = V((math.cos(a) * 0.16, 0.04 + math.sin(a) * 0.14, 0.4))
        pts = [b, b + V((math.cos(a) * 0.08, math.sin(a) * 0.06, -0.14)), b + V((math.cos(a) * 0.1, 0.02, -0.28)),
               b + V((math.cos(a) * 0.16, 0.04, -0.32))]
        C.tube(f"Tentacle{k}", pts, [0.035, 0.028, 0.016, 0.004], "tent", None, allowed=["tail1", "tail2"])
        C.ellipsoid(f"Sucker{k}", tuple(V(pts[1]) + V((0, -0.02, 0))), (0.012,) * 3, "sucker", "tail2")
    hr = at["hdR"]
    C.tube("Staff", [hr + V((0, 0.04, -0.7)), hr, hr + V((0, -0.04, 0.42)), hr + V((0.1, -0.06, 0.52))],
           [0.018, 0.018, 0.016, 0.012], "wood", "forearm.R")
    C.lathe("Bell", [(0.001, 0.0), (0.03, -0.01), (0.06, -0.1), (0.065, -0.12)], "bell", "forearm.R", segs=12)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(tuple(hr + V((0.1, -0.06, 0.5)))))
