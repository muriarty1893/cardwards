"""Sugar Smuggler (Candy Hills, 2): a shifty gremlin. Sculpted: a hunched little goblin swamped in an
oversized trench coat with the collar turned up, the coat thrown open to show a lining hung with
contraband sweets, a low-brimmed hat, long pointed ears, glinting eyes and a grin full of sharp teeth."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(skin="7ab84a", coat="5a3a2a", lining="ff7ab8", hat="2a1e18", band="ffd23a", eye="ffe23a", dark="0a0806",
              tooth="ffffff", c1="ff3a6a", c2="3ad8ff", c3="ffd23a")
    C.attack = "stab"
    cl, at = skulpt.biped(C, hip=0.34, chest=0.62, head=0.84, lean=0.14, shoulder_x=0.16, hip_x=0.08,
                          r_chest=(0.18, 0.15, 0.18), r_waist=(0.17, 0.15, 0.12), r_hips=(0.18, 0.16, 0.1),
                          r_head=(0.12, 0.12, 0.11), r_arm=(0.06, 0.055), r_hand=0.04, r_leg=(0.045, 0.04),
                          r_foot=(0.05, 0.08, 0.035), arm_len=0.32, group="coat")
    h = at["head"]
    cl.chain([(0, 0.02, 0.5), (0, 0.04, 0.22)], [(0.2, 0.18, 0.16), (0.24, 0.2, 0.14)], group="coat")   # coat skirt
    cl.add((0, -0.2, 0.42), (0.1, 0.06, 0.22), group="lining", neg=True)                                 # open front
    cl.add((0, -0.12, 0.44), (0.1, 0.04, 0.22), group="lining")
    for k in range(7):                                                          # upturned collar
        a = math.pi * (0.1 + 0.8 * k / 6)
        cl.add((math.cos(a) * 0.12, -0.08 + math.sin(a) * 0.07, 0.8), (0.05, 0.025, 0.08), group="coat")
    cl.add((0, h.y - 0.02, h.z), (0.11, 0.11, 0.1), group="skin")
    for sx in (-1, 1):
        cl.chain([(0.1 * sx, h.y, h.z + 0.02), (0.2 * sx, h.y + 0.04, h.z + 0.06), (0.28 * sx, h.y + 0.06, h.z + 0.04)],
                 [(0.04, 0.02, 0.035), (0.03, 0.015, 0.025), 0.005], group="skin")
        cl.add(tuple(at["hd" + ("L" if sx < 0 else "R")]), (0.045, 0.045, 0.045), group="skin")
    cl.mirror((0.045, h.y - 0.1, h.z + 0.02), (0.022, 0.02, 0.018), group="dark", neg=True)
    body = cl.build({"coat": "coat", "lining": "lining", "skin": "skin", "dark": "skin"}, voxel=0.007, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.005})
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, h.y - 0.115, h.z + 0.02), (0.018, 0.008, 0.012), "eye", "head")
    for k in range(5):
        x = -0.04 + 0.02 * k
        C.cone(f"Tooth{k}", (x, h.y - 0.115, h.z - 0.04), (x, h.y - 0.12, h.z - 0.065), 0.008, "tooth", "head", segs=4)
    C.lathe("HatBrim", [(0.001, 0.0), (0.2, 0.0), (0.2, 0.015)], "hat", "head", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y, h.z + 0.08)) @
                                  __import__("mathutils").Matrix.Rotation(-0.15, 4, 'X'))
    C.lathe("HatCrown", [(0.11, 0.0), (0.1, 0.12), (0.001, 0.13)], "hat", "head", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y + 0.01, h.z + 0.08)))
    C.lathe("HatBand", [(0.112, 0.0), (0.112, 0.03)], "band", "head", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, h.y + 0.01, h.z + 0.09)))
    for k in range(6):
        C.ellipsoid(f"Sweet{k}", (-0.06 + 0.12 * (k % 2), -0.16, 0.56 - 0.08 * (k // 2)), (0.025, 0.012, 0.025),
                    ("c1", "c2", "c3")[k % 3], "hips")
    hr = at["hdR"]
    C.cone("Shiv", tuple(hr + V((0, -0.02, 0.0))), tuple(hr + V((0, -0.16, 0.08))), 0.015, "band", "forearm.R", segs=4)
