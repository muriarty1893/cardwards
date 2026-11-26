"""Glimmer Morel (Mushroom Forest, 3): a morel knight. Sculpted: a sturdy stalk body in bark plate armour,
a tall honeycombed morel cap worn like a great helm with a glowing visor slit, broad pauldrons of bark,
a round bark shield studded with glowing spores and a thorn-bladed lance."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(stalk="d8c8a0", morel="8a6a3a", pit="4a3420", glow="b8ff6a", bark="5a3e28", bark2="7a5a3a", metal="8a8a7a",
              dark="140c08")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.5, chest=0.86, head=1.08, lean=0.04, shoulder_x=0.24, hip_x=0.11,
                          r_chest=(0.22, 0.17, 0.2), r_waist=(0.16, 0.13, 0.12), r_hips=(0.16, 0.13, 0.1),
                          r_head=(0.12, 0.12, 0.1), r_arm=(0.07, 0.06), r_hand=0.06, r_leg=(0.08, 0.07),
                          r_foot=(0.07, 0.1, 0.05), arm_len=0.46, group="stalk")
    h = at["head"]
    cl.add((0, -0.02, 0.84), (0.24, 0.19, 0.2), group="bark")                      # breastplate
    cl.add((0, -0.02, 0.62), (0.2, 0.16, 0.1), group="bark2")                      # tasset
    body = cl.build({"stalk": "stalk", "bark": "bark", "bark2": "bark2"}, voxel=0.009, budget=8000, relax=2,
                    texture={"type": 'STUCCI', "scale": 0.025, "strength": 0.01})
    helm = Clay(C, "Helm", res=0.014)
    helm.chain([(0, -0.02, 1.0), (0, -0.01, 1.22), (0, 0.0, 1.44), (0, 0.01, 1.56)], [0.17, 0.16, 0.12, 0.04],
               group="morel")
    hb = helm.build({"morel": "morel"}, voxel=0.008, budget=4000, relax=1,
                    texture={"type": 'VORONOI', "scale": 0.03, "strength": 0.03}, bone="head")
    recolor(hb, lambda p, n: cracks(p, 0.06, 0.25, seed=67), "pit")
    C.box("Visor", (0, -0.17, 1.08), (0.18, 0.04, 0.03), "glow", "head", bevel=0.4)
    for mx in (-1, 1):
        side = "L" if mx < 0 else "R"
        C.ellipsoid(f"Pauldron{side}", tuple(at["sh" + side] + V((0.03 * mx, 0, 0.05))), (0.11, 0.11, 0.07), "bark2",
                    f"arm.{side}")
    hl = at["hdL"]
    sc = hl + V((-0.04, -0.12, 0.06))
    props.shield(C, tuple(sc), 0.22, "bark", "bark2", "forearm.L", facing=(0, -1, 0))
    for k in range(5):
        a = 2 * math.pi * k / 5
        C.ellipsoid(f"Spore{k}", tuple(sc + V((math.cos(a) * 0.12, -0.04, math.sin(a) * 0.12))), (0.025,) * 3, "glow",
                    "forearm.L")
    hr = at["hdR"]
    C.tube("Lance", [hr + V((0, 0.2, -0.1)), hr, hr + V((0, -0.5, 0.36))], [0.022, 0.022, 0.016], "bark", "forearm.R")
    C.cone("LanceTip", tuple(hr + V((0, -0.5, 0.36))), tuple(hr + V((0, -0.66, 0.48))), 0.035, "metal", "forearm.R",
           segs=5)
