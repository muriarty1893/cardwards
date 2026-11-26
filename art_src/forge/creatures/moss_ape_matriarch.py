"""Moss Ape Matriarch (Mushroom Forest, 6): a huge silverback of the deep forest. Sculpted: a massive
gorilla, knuckle-walking on huge arms, a towering crested head and heavy brow over a wise, stern face,
moss growing thick over the shoulders and back, stone-and-bark bracers on her forearms and a crown of
antler twigs with glowing blossoms."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep


def build(C):
    C.palette(fur="2e3a26", moss="5f9a2e", face="3a302c", eye="ffcf3a", dark="0e0c0a", stone="7a7f74", bark="5a3e28",
              bloom="ff7ac8", antler="d8c8a8")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.74, chest=1.22, head=1.42, lean=0.3, shoulder_x=0.44, hip_x=0.2,
                          r_chest=(0.4, 0.32, 0.32), r_waist=(0.3, 0.24, 0.22), r_hips=(0.27, 0.22, 0.18),
                          r_head=(0.15, 0.15, 0.16), r_arm=(0.16, 0.15), r_hand=0.13, r_leg=(0.15, 0.12),
                          r_foot=(0.12, 0.16, 0.07), arm_len=1.05, hand_fwd=0.25, group="fur")
    h = at["head"]
    cl.add((0, h.y + 0.02, h.z + 0.14), (0.07, 0.12, 0.08), group="fur")            # sagittal crest
    cl.add((0, h.y - 0.1, h.z - 0.03), (0.11, 0.08, 0.11), group="face")
    cl.add((0, h.y - 0.15, h.z + 0.05), (0.13, 0.05, 0.035), group="face")           # heavy brow
    cl.mirror((0.05, h.y - 0.17, h.z + 0.02), (0.025, 0.02, 0.02), group="face", neg=True)
    cl.add((0, h.y - 0.17, h.z - 0.05), (0.07, 0.05, 0.05), group="face")            # muzzle
    for k in range(10):
        a = math.pi * (0.05 + 0.9 * k / 9)
        cl.add((math.cos(a) * 0.38, 0.06 - math.sin(a) * 0.02, 1.36 + 0.1 * math.sin(a)), (0.13, 0.13, 0.09),
               group="moss")
    cl.add((0, 0.2, 1.1), (0.26, 0.14, 0.22), group="moss")
    body = cl.build({"fur": "fur", "face": "face", "moss": "moss"}, voxel=0.015, budget=11000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.022})
    recolor(body, lambda p, n: smoothstep(0.2, 0.0, (p - V((0, 0.24, 1.0))).length) * 0.5, "stone")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.05 * mx, h.y - 0.185, h.z + 0.02), (0.016, 0.008, 0.012), "eye", "head")
        side = "L" if mx < 0 else "R"
        el, hd = at["el" + side], at["hd" + side]
        mid = el.lerp(hd, 0.55)
        C.ellipsoid(f"Bracer{side}", tuple(mid), (0.16, 0.16, 0.13), "bark", f"forearm.{side}")
        C.ellipsoid(f"BracerStone{side}", tuple(mid + V((0.08 * mx, -0.06, 0.0))), (0.07, 0.06, 0.07), "stone",
                    f"forearm.{side}")
        b = h + V((0.08 * mx, 0.02, 0.14))
        C.tube(f"Antler{mx}", [b, b + V((0.1 * mx, 0.04, 0.12)), b + V((0.18 * mx, 0.02, 0.24))], [0.02, 0.015, 0.004],
               "antler", "head")
        C.tube(f"Tine{mx}", [b + V((0.1 * mx, 0.04, 0.12)), b + V((0.12 * mx, -0.06, 0.2))], [0.012, 0.003], "antler", "head")
        for k in range(2):
            C.ellipsoid(f"Bloom{mx}{k}", tuple(b + V((0.18 * mx - 0.06 * mx * k, 0.02, 0.24 - 0.1 * k))), (0.03,) * 3, "bloom",
                        "head")
