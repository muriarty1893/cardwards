"""Elder Shroomhulk (Mushroom Forest, 7): an ancient fungal giant. Sculpted: a hulking, hunched brute of
packed white mycelium and moss, huge arms ending in knuckled root-fists, a small face of glowing eyes
under a vast red spotted cap that sits on its shoulders like a war-banner, and smaller mushrooms bursting
from its back and shoulders, roots trailing from its feet."""
import math
import random
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep, crease


def build(C):
    C.palette(body="e8dcc8", body2="c8b898", cap="b8201a", spot="fff4e0", gill="e8c8a8", moss="4f8a2a", eye="ffcf3a",
              dark="120a08", root="5a3e28", cap2="d8782a")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.78, chest=1.3, head=1.5, lean=0.2, shoulder_x=0.44, hip_x=0.2,
                          r_chest=(0.4, 0.3, 0.32), r_waist=(0.28, 0.22, 0.22), r_hips=(0.28, 0.22, 0.18),
                          r_head=(0.14, 0.14, 0.13), r_arm=(0.15, 0.14), r_hand=0.14, r_leg=(0.16, 0.13),
                          r_foot=(0.13, 0.16, 0.07), arm_len=0.82, hand_fwd=0.1, group="body")
    h = at["head"]
    for k in range(9):                                                         # mossy patches over the shoulders
        a = math.pi * (k / 8)
        cl.add((math.cos(a) * 0.36, 0.02, 1.4 + 0.08 * math.sin(a)), (0.14, 0.14, 0.09), group="moss")
    cl.mirror((0.05, h.y - 0.12, h.z + 0.01), (0.03, 0.025, 0.025), group="dark", neg=True)
    body = cl.build({"body": "body", "moss": "moss", "dark": "body2"}, voxel=0.016, budget=11000, relax=2,
                    texture={"type": 'STUCCI', "scale": 0.03, "strength": 0.02})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.6, "body2")
    crease(body, "body2", 0.6, 0.85, strength=0.7)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.05 * mx, h.y - 0.135, h.z + 0.01), (0.02, 0.01, 0.016), "eye", "head")
    C.lathe("Cap", [(0.001, 0.0), (0.62, -0.04), (0.66, 0.0), (0.58, 0.12), (0.34, 0.26), (0.001, 0.3)], "cap", "chest",
            segs=32, wave=(7, 0.08, 0.3))
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0.02, 1.62)))
    C.lathe("Gills", [(0.08, 0.0), (0.62, -0.035)], "gill", "chest", segs=32)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0.02, 1.61)))
    rnd = random.Random(5)
    for k in range(9):
        a, r = rnd.uniform(0, 6.28), rnd.uniform(0.1, 0.5)
        C.decal(f"Spot{k}", math.cos(a) * r, 3.0, (0.06, 0.06, 0.02), "spot", "chest", part="Cap", dir=(0, 0, -1),
                y=0.02 + math.sin(a) * r)
    for k, (x, y, z, s) in enumerate([(0.3, 0.2, 1.3, 0.09), (-0.34, 0.16, 1.2, 0.08), (0.1, 0.32, 1.08, 0.07),
                                      (-0.12, 0.34, 0.96, 0.06), (0.46, -0.02, 1.36, 0.06)]):
        C.tube(f"SmallStalk{k}", [V((x, y, z - 0.06)), V((x, y + 0.03, z + 0.04))], [0.025, 0.02], "body", "chest")
        C.ellipsoid(f"SmallCap{k}", (x, y + 0.03, z + 0.05), (s, s, s * 0.5), "cap2", "chest")
    for mx in (-1, 1):
        ft = at["ft" + ("L" if mx < 0 else "R")]
        for k in range(3):
            a = math.radians(-40 + 40 * k)
            C.tube(f"Root{mx}{k}", [ft + V((0, 0, 0.02)), ft + V((math.sin(a) * 0.14, -math.cos(a) * 0.14 - 0.06, 0.0))],
                   [0.03, 0.008], "root", f"shin.{'L' if mx < 0 else 'R'}")
