"""Sugar Sprite (Candy Hills, 3): a ghostly sugar spirit. Sculpted: a body of drifting powdered sugar
that billows out from the shoulders and tapers to a curling wisp, a smooth mask-like face of glazed pink
icing with hollow eyes, a crown of rock-candy crystals and long arms whose hands trail sugar dust."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(sugar="fff4fa", sugar2="ffd8ec", icing="ff8ac8", eye="3a0a5a", crystal="c8a8ff", crystal2="8af0ff", dust="ffe8f8")
    C.attack = "cast"
    cl, at = skulpt.biped(C, hip=0.72, chest=1.04, head=1.24, lean=0.04, shoulder_x=0.22, hip_x=0.1,
                          r_chest=(0.2, 0.16, 0.18), r_waist=(0.15, 0.13, 0.14), r_hips=(0.15, 0.13, 0.12),
                          r_head=(0.12, 0.11, 0.13), r_arm=(0.045, 0.035), r_hand=0.04, arm_len=0.5, legs=False,
                          hover=0.3, group="sugar")
    h = at["head"]
    for k in range(10):
        a = 2 * math.pi * k / 10
        cl.add((math.cos(a) * 0.18, math.sin(a) * 0.14, 0.92 - 0.04 * (k % 3)), (0.08, 0.08, 0.12), group="sugar2")
    cl.add((0, h.y - 0.08, h.z), (0.1, 0.06, 0.12), group="icing")                   # icing mask
    cl.mirror((0.045, h.y - 0.13, h.z + 0.03), (0.025, 0.02, 0.03), group="icing", neg=True)
    body = cl.build({"sugar": "sugar", "sugar2": "sugar2", "icing": "icing"}, voxel=0.008, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.015})
    recolor(body, lambda p, n: smoothstep(0.5, 0.1, p.z) * 0.7, "dust")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.045 * mx, h.y - 0.13, h.z + 0.03), (0.018, 0.01, 0.024), "eye", "head")
    for k in range(6):
        a = math.pi * (0.1 + 0.8 * k / 5)
        b = h + V((math.cos(a) * 0.09, 0.02 - math.sin(a) * 0.04, 0.1))
        C.cone(f"Crystal{k}", tuple(b), tuple(b + V((math.cos(a) * 0.04, 0.02, 0.12 + 0.05 * (k in (2, 3))))), 0.03,
               "crystal" if k % 2 else "crystal2", "head", segs=4)
    for mx in (-1, 1):
        hd = at["hd" + ("L" if mx < 0 else "R")]
        for k in range(4):
            C.ellipsoid(f"Dust{mx}{k}", tuple(hd + V((0.03 * k * mx, 0.04 * k, -0.06 - 0.05 * k))), (0.02 - 0.003 * k,) * 3,
                        "dust", f"forearm.{'L' if mx < 0 else 'R'}")
