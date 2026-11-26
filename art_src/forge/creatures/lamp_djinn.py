"""Lamp Djinn (Sunny Dunes, 6): a towering blue djinn rising out of a golden oil lamp. Sculpted: a
massive bare-chested torso and huge arms with gold bangles, a crimson sash and open vest, a proud bearded
face with burning eyes under a jewelled turban, the body thinning into a twisting tail of smoke that
pours out of the spout of a golden lamp."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(skin="3a6ad8", skin2="2a4aa8", smoke="7a9ae8", gold="ffcf3a", gem="ff2a6a", turban="f0e8f8", beard="1a1a3a",
              eye="ffe23a", dark="0a0a1a", sash="b8202a", vest="7a1a8a")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.86, chest=1.36, head=1.64, lean=0.06, shoulder_x=0.4, hip_x=0.15,
                          r_chest=(0.36, 0.24, 0.28), r_waist=(0.22, 0.17, 0.16), r_hips=(0.18, 0.15, 0.12),
                          r_head=(0.13, 0.13, 0.14), r_arm=(0.12, 0.1), r_hand=0.09, arm_len=0.62, legs=False,
                          hover=0.3, group="skin")
    h = at["head"]
    cl.mirror((0.15, -0.16, 1.32), (0.15, 0.08, 0.12), group="skin")                 # pecs
    cl.mirror((0.06, -0.15, 1.08), (0.05, 0.04, 0.1), group="skin")                  # abs
    cl.add((0, -0.02, 0.96), (0.2, 0.17, 0.06), group="sash")
    for k in range(10):                                                         # smoke tail swirling down to the lamp
        t = k / 9
        a = t * 2.5 * math.pi
        cl.add((math.sin(a) * 0.08 * (1 - t), 0.04 + 0.1 * t, 0.86 - 0.62 * t), (0.15 - 0.09 * t, 0.15 - 0.09 * t, 0.08),
               group="smoke")
    cl.mirror((0.045, h.y - 0.12, h.z + 0.03), (0.022, 0.02, 0.018), group="skin2", neg=True)
    cl.add((0, h.y - 0.12, h.z + 0.07), (0.1, 0.04, 0.025), rot=(-10, 0, 0), group="skin2")
    body = cl.build({"skin": "skin", "skin2": "skin2", "sash": "sash", "smoke": "smoke"}, voxel=0.012, budget=10000,
                    relax=2, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.006})
    recolor(body, lambda p, n: smoothstep(0.8, 0.4, p.z) * 0.8, "smoke")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, h.y - 0.135, h.z + 0.03), (0.02, 0.01, 0.012), "eye", "head")
        side = "L" if mx < 0 else "R"
        for k in range(2):
            C.ellipsoid(f"Bangle{side}{k}", tuple(at["el" + side].lerp(at["hd" + side], 0.55 + 0.15 * k)), (0.1, 0.1, 0.025),
                        "gold", f"forearm.{side}")
        C.ellipsoid(f"Vest{side}", (0.2 * mx, 0.02, 1.36), (0.14, 0.2, 0.22), "vest", "chest")
    C.tube("Beard", [h + V((0, -0.1, -0.08)), h + V((0, -0.14, -0.2)), h + V((0, -0.08, -0.32)), h + V((0.02, -0.0, -0.36))],
           [0.06, 0.05, 0.03, 0.01], "beard", "head")
    C.ellipsoid("Turban", tuple(h + V((0, 0.0, 0.12))), (0.17, 0.17, 0.12), "turban", "head")
    C.ellipsoid("TurbanGem", tuple(h + V((0, -0.17, 0.14))), (0.035, 0.015, 0.04), "gem", "head")
    C.cone("TurbanPlume", tuple(h + V((0, -0.14, 0.18))), tuple(h + V((0.0, -0.1, 0.36))), 0.025, "gold", "head", segs=5)
    lp = V((0, 0.14, 0.12))
    C.lathe("Lamp", [(0.001, -0.08), (0.18, -0.04), (0.2, 0.04), (0.1, 0.1), (0.05, 0.14)], "gold", "tail2", segs=18)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(tuple(lp)))
    C.tube("Spout", [lp + V((0, -0.16, 0.0)), lp + V((0, -0.3, 0.06)), lp + V((0, -0.36, 0.12))], [0.04, 0.03, 0.025], "gold",
           "tail2")
    C.tube("Handle", [lp + V((0, 0.16, 0.02)), lp + V((0, 0.26, 0.08)), lp + V((0, 0.2, 0.14))], [0.02, 0.02, 0.02], "gold",
           "tail2")
