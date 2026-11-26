"""Cotton Sheep (Candy Hills, 4): a burly battering ram whose fleece is spun cotton candy. Sculpted: a
heavy-shouldered ram buried in a huge fleece of pink and blue candy-floss clumps, thin dark legs, a long
dark stubborn face with a heavy brow, and great spiral candy-stick horns curling round its ears."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(face="3a2a3a", fleece="ffb8e0", fleece2="b8d8ff", horn="fff0f4", stripe="ff3a6a", eye="ffe23a", hoof="2a1a2a",
              pupil="1a0a0a")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.3, 0.7), chest=(-0.22, 0.76), r_chest=(0.28, 0.28, 0.28), r_belly=(0.27, 0.3, 0.26),
                         r_hips=(0.25, 0.24, 0.25), leg_x=0.18, r_thigh=0.08, r_shin=0.04, r_paw=0.05, paw_len=1.0,
                         neck=((-0.42, 0.84),), r_neck=(0.16,), head=(-0.54, 0.86), r_head=(0.1, 0.13, 0.11),
                         snout=(-0.76, 0.76), r_snout=(0.08, 0.06), tail=((0.52, 0.72),), r_tail=(0.06, 0.04),
                         digi=False, group="face")
    h = at["head"]
    rnd = random.Random(23)
    for k in range(30):                                                         # candy-floss fleece
        a, b = rnd.uniform(0, 6.28), rnd.uniform(0.3, 2.2)
        y = rnd.uniform(-0.4, 0.42)
        cl.add((math.cos(a) * 0.26, y, 0.78 + math.sin(a) * 0.24 * (0.7 if math.sin(a) < 0 else 1.0)), (0.13, 0.13, 0.12),
               group="fleece" if k % 2 else "fleece2")
    for k in range(5):
        cl.add((rnd.uniform(-0.08, 0.08), -0.42 + 0.02 * k, 0.98 + 0.02 * k), (0.09, 0.08, 0.08), group="fleece")
    cl.add((0, h.y - 0.08, h.z + 0.06), (0.1, 0.06, 0.04), group="face")
    body = cl.build({"face": "face", "fleece": "fleece", "fleece2": "fleece2"}, voxel=0.011, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.02})
    skulpt.eyes(C, [(0.08, h.y - 0.07, h.z + 0.02)], 0.022, "eye", "pupil")
    for mx in (-1, 1):
        pts = []
        for k in range(10):
            t = k / 9
            a = t * 1.7 * math.pi
            r = 0.15 * (1 - 0.55 * t)
            pts.append(h + V((0.1 * mx + mx * (0.06 + r * (1 - math.cos(a))) * 0.9, 0.04 + r * math.sin(a), 0.08 - r * math.sin(a * 0.5) * 0.6)))
        C.tube(f"Horn{mx}", pts, [0.05 - 0.004 * k for k in range(10)], "horn", "head")
        for k in range(0, 9, 2):
            C.ellipsoid(f"HornStripe{mx}{k}", tuple(pts[k]), (0.052 - 0.004 * k,) * 3, "stripe", "head")
        for tag in ("f", "b"):
            p = V(at["legs"]["L" if mx < 0 else "R"][tag][-1])
            C.ellipsoid(f"Hoof{tag}{mx}", tuple(p + V((0, -0.02, -0.01))), (0.055, 0.065, 0.04), "hoof",
                        f"shin_{tag}.{'L' if mx < 0 else 'R'}")
