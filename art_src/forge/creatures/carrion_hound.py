"""Carrion Hound (Mushroom Forest, 3): a gaunt grave-hound. Sculpted: a starved, hunched wolf-shape with
a deep narrow chest, ribs and hip bones pushing through rotting hide, a tucked waist, long bony legs,
a bare skull head with empty sockets lit by sickly glowing eyes, bone spines down its back and a ragged
moss mane."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="2f3a2d", bone="e3d7b8", eye="c6ff3a", dark="12150f", moss="5f8f2e", claw="2a2520")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.3, 0.7), chest=(-0.22, 0.74), r_chest=(0.18, 0.24, 0.26), r_belly=(0.12, 0.24, 0.13),
                         r_hips=(0.15, 0.16, 0.16), leg_x=0.15, r_thigh=0.08, r_shin=0.04, r_paw=0.055, paw_len=1.4,
                         neck=((-0.38, 0.86),), r_neck=(0.1,), head=(-0.5, 0.86), r_head=(0.11, 0.13, 0.1),
                         snout=(-0.74, 0.78), r_snout=(0.07, 0.05), tail=((0.5, 0.66), (0.66, 0.5)),
                         r_tail=(0.04, 0.015), group="hide", jaw=True)
    h, s = at["head"], at["snout"]
    for k in range(5):                                                         # ribs
        cl.mirror((0.17, -0.3 + 0.07 * k, 0.68), (0.025, 0.03, 0.14), rot=(0, 15, 0), group="bone")
    cl.mirror((0.13, 0.38, 0.8), (0.05, 0.06, 0.05), group="bone")              # hip bones
    cl.add((0, h.y - 0.02, h.z), (0.12, 0.13, 0.1), group="bone")               # skull
    cl.chain([(0, h.y - 0.08, h.z - 0.02), tuple(s)], [0.075, 0.05], group="bone")
    cl.mirror((0.06, h.y - 0.1, h.z + 0.02), (0.035, 0.03, 0.028), group="dark", neg=True)
    for k in range(6):                                                         # ragged moss mane
        cl.add((0.03 * (k % 2 * 2 - 1), -0.42 + 0.06 * k, 0.98 - 0.03 * k), (0.07, 0.06, 0.08), group="moss")
    body = cl.build({"hide": "hide", "bone": "bone", "dark": "bone", "moss": "moss"}, voxel=0.01, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.1, 0.6, math.sin(p.x * 40 + p.y * 30)) * 0.3, "dark")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, h.y - 0.12, h.z + 0.02), (0.018, 0.01, 0.016), "eye", "head")
        C.cone(f"Fang{mx}", tuple(s + V((0.03 * mx, 0.0, -0.03))), tuple(s + V((0.03 * mx, -0.01, -0.09))), 0.012, "bone",
               "head", segs=4)
        for k in (-1, 0, 1):
            for tag in ("f", "b"):
                p = V(at["legs"]["L" if mx < 0 else "R"][tag][-1])
                C.cone(f"Claw{tag}{mx}{k}", tuple(p + V((0.025 * k, -0.07, 0.01))), tuple(p + V((0.03 * k, -0.12, -0.02))),
                       0.01, "claw", f"shin_{tag}.{'L' if mx < 0 else 'R'}", segs=4)
    for k in range(6):
        y = -0.18 + 0.1 * k
        C.cone(f"Spine{k}", (0, y, 0.96 - 0.02 * k), (0, y + 0.06, 1.08 - 0.02 * k), 0.025, "bone",
               "chest" if y < 0.04 else "hips", segs=5)
