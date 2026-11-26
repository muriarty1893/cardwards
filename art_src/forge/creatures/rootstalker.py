"""Rootstalker (Mushroom Forest, 4): a gaunt hunter of twisted roots. Sculpted: a long-limbed, hunched
figure of braided roots, a narrow chest of twisting strands, a hollow knotted face with two lantern-green
eyes deep inside, finger-roots like long claws, moss and little mushrooms hanging off its back."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep, crease


def build(C):
    C.palette(root="4a3220", root2="6a4a2a", moss="4f8a2a", eye="b8ff5a", dark="0c0804", bark="3a2618", shroom="d8c8a8")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.86, chest=1.36, head=1.6, lean=0.3, shoulder_x=0.26, hip_x=0.12,
                          r_chest=(0.2, 0.15, 0.22), r_waist=(0.12, 0.1, 0.14), r_hips=(0.15, 0.12, 0.1),
                          r_head=(0.11, 0.13, 0.13), r_arm=(0.06, 0.05), r_hand=0.05, r_leg=(0.07, 0.055),
                          r_foot=(0.06, 0.1, 0.04), arm_len=0.92, hand_fwd=0.2, group="root", digi=True)
    h = at["head"]
    for k in range(8):                                                         # twisting strands round the torso
        a = 2 * math.pi * k / 8
        cl.chain([(math.cos(a) * 0.14, -0.1 + math.sin(a) * 0.1, 1.5), (math.cos(a + 0.8) * 0.12, -0.05 + math.sin(a + 0.8) * 0.09, 1.2),
                  (math.cos(a + 1.6) * 0.12, math.sin(a + 1.6) * 0.09, 0.92)], [0.035, 0.03, 0.035], group="root2")
    cl.add((0, h.y - 0.1, h.z), (0.07, 0.06, 0.08), group="dark", neg=True)          # hollow face
    cl.mirror((0.04, h.y - 0.06, h.z + 0.02), (0.03, 0.03, 0.03), group="dark")
    for k in range(5):
        cl.add((0.05 * (k % 2 * 2 - 1), 0.12, 1.4 - 0.1 * k), (0.07, 0.05, 0.08), group="moss")
    body = cl.build({"root": "root", "root2": "root2", "dark": "dark", "moss": "moss"}, voxel=0.011, budget=9000,
                    relax=1, texture={"type": 'STUCCI', "scale": 0.02, "strength": 0.012})
    crease(body, "dark", 0.62, 0.85, strength=0.7)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.04 * mx, h.y - 0.07, h.z + 0.02), (0.018, 0.01, 0.018), "eye", "head")
        side = "L" if mx < 0 else "R"
        hd = at["hd" + side]
        for k in range(4):
            a = math.radians(-45 + 30 * k)
            C.tube(f"Finger{side}{k}", [hd, hd + V((math.sin(a) * 0.06, -0.08, -0.08)), hd + V((math.sin(a) * 0.1, -0.12, -0.24))],
                   [0.016, 0.01, 0.002], "root2", f"forearm.{side}")
    for k in range(3):
        C.ellipsoid(f"Shroom{k}", (0.08 * (k - 1), 0.18, 1.2 - 0.08 * k), (0.04, 0.04, 0.02), "shroom", "chest")
    for k in range(3):
        a = math.radians(-30 + 30 * k)
        C.tube(f"Crown{k}", [h + V((0.03 * (k - 1), 0, 0.1)), h + V((math.sin(a) * 0.1, 0.06, 0.24))], [0.02, 0.004], "root2",
               "head")
