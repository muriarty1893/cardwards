"""Moonlit Stalker (Dark Moon, 4): a lean shadow panther. Sculpted: a long, low, muscular big cat with
powerful shoulders and a whip tail, fur black as the sky between stars with a faint starry sheen, a
crescent moon glowing on its brow, wisps of shadow trailing from its shoulders and tail, and eyes like two
cold stars. Frostfang reuses it in ice with two long icicle sabres (sabres=True)."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C, sabres=False):
    C.palette(fur="141028", fur2="2a2050", moon="e8f0ff", eye="aef4ff", star="c8d8ff", wisp="3a2a7a", claw="d8d8f0",
              mouth="3a0a2a", sabre="f0fcff")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.36, 0.62), chest=(-0.26, 0.66), r_chest=(0.2, 0.26, 0.24), r_belly=(0.15, 0.3, 0.15),
                         r_hips=(0.17, 0.2, 0.18), leg_x=0.17, r_thigh=0.1, r_shin=0.05, r_paw=0.07, paw_len=1.2,
                         neck=((-0.42, 0.74),), r_neck=(0.13,), head=(-0.54, 0.76), r_head=(0.13, 0.13, 0.11),
                         snout=(-0.72, 0.7), r_snout=(0.08, 0.06), tail=((0.6, 0.66), (0.86, 0.74), (1.04, 0.66)),
                         r_tail=(0.05, 0.025), group="fur", jaw=True)
    h, s = at["head"], at["snout"]
    for sx in (-1, 1):
        cl.chain([(0.08 * sx, h.y + 0.04, h.z + 0.09), (0.11 * sx, h.y + 0.06, h.z + 0.17)], [(0.045, 0.02, 0.045), 0.01],
                 group="fur")
        cl.add((0.08 * sx, h.y - 0.08, h.z + 0.05), (0.05, 0.04, 0.025), rot=(0, 0, -15 * sx), group="fur2")
        cl.add((0.1 * sx, h.y - 0.02, h.z - 0.04), (0.05, 0.05, 0.05), group="fur")      # cheek
    cl.add(tuple(s + V((0, 0.04, -0.05))), (0.06, 0.08, 0.03), group="fur2")
    body = cl.build({"fur": "fur", "fur2": "fur2"}, voxel=0.011, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(0.55, 0.95, n.z) * 0.5, "fur2")
    rnd = random.Random(41)
    st = [v.co.copy() for v in rnd.sample(list(body.data.vertices), 30) if v.normal.z > 0.0]
    recolor(body, lambda p, n: max(smoothstep(0.02, 0.0, (p - q).length) for q in st), "star")
    skulpt.eyes(C, [(0.07, h.y - 0.1, h.z + 0.03)], 0.024, "eye", None)
    C.ellipsoid("Moon", tuple(h + V((0, -0.11, 0.08))), (0.04, 0.012, 0.03), "moon", "head")
    C.ellipsoid("MoonBite", tuple(h + V((0.015, -0.12, 0.09))), (0.032, 0.012, 0.026), "fur", "head")
    for mx in (-1, 1):
        if sabres:
            C.cone(f"Sabre{mx}", tuple(s + V((0.04 * mx, -0.02, -0.03))), tuple(s + V((0.045 * mx, -0.05, -0.24))), 0.028,
                   "sabre", "head", segs=6, smooth=True)
        else:
            C.cone(f"Fang{mx}", tuple(s + V((0.035 * mx, -0.02, -0.03))), tuple(s + V((0.035 * mx, -0.025, -0.09))), 0.012,
                   "claw", "head", segs=4)
        for k in range(3):                                                    # shadow wisps off the shoulders
            b = V((0.16 * mx, -0.24 + 0.06 * k, 0.82))
            C.cone(f"Wisp{mx}{k}", tuple(b), tuple(b + V((0.06 * mx, 0.2 + 0.05 * k, 0.12))), 0.04, "wisp", "chest", segs=5)
        for tag in ("f", "b"):
            p = V(at["legs"]["L" if mx < 0 else "R"][tag][-1])
            for k in (-1, 0, 1):
                C.cone(f"Claw{tag}{mx}{k}", tuple(p + V((0.03 * k, -0.07, 0.01))), tuple(p + V((0.035 * k, -0.12, -0.01))),
                       0.01, "claw", f"shin_{tag}.{'L' if mx < 0 else 'R'}", segs=4)
    t = V(at["tail"][-1])
    for k in range(3):
        C.cone(f"TailWisp{k}", tuple(t), tuple(t + V((0.05 * (k - 1), 0.16, 0.08 * k))), 0.035, "wisp", "tail3", segs=5)
