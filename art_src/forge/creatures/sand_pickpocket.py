"""Sand Pickpocket (Sunny Dunes, 2): a sly desert gecko thief. Sculpted: a slinking, crouched gecko on
splayed sticky-toed feet, spotted green scales over a pale belly, a wide grinning reptile face with big
amber eyes peering from under a sand-coloured hood, a red scarf, a long curling tail, a stolen coin purse
and a quick dagger."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(scale="7ab84a", belly="e8e0a0", hood="d8b878", scarf="c83a2a", eye="ffb02a", pupil="0a0a0a", dark="1a1408",
              metal="d8d8e0", gold="ffcf3a", purse="7a4a2a", spot="4a8a2a")
    C.attack = "stab"
    cl, at = skulpt.biped(C, hip=0.4, chest=0.66, head=0.84, lean=0.2, shoulder_x=0.14, hip_x=0.1,
                          r_chest=(0.12, 0.11, 0.14), r_waist=(0.1, 0.09, 0.1), r_hips=(0.11, 0.1, 0.08),
                          r_head=(0.1, 0.12, 0.08), r_arm=(0.035, 0.03), r_hand=0.035, r_leg=(0.05, 0.035),
                          r_foot=(0.05, 0.08, 0.025), arm_len=0.3, group="scale", digi=True)
    h = at["head"]
    cl.chain([(0, h.y - 0.04, h.z - 0.02), (0, h.y - 0.16, h.z - 0.04)], [(0.09, 0.08, 0.06), (0.06, 0.04, 0.04)],
             group="scale")
    cl.add((0, -0.18, 0.56), (0.08, 0.05, 0.12), group="belly")
    cl.chain([(0, 0.06, 0.38), (0, 0.26, 0.24), (0.12, 0.4, 0.2), (0.2, 0.36, 0.34)], [0.06, 0.045, 0.03, 0.015], group="scale")
    for k in range(9):                                                         # hood
        a = math.pi * (0.0 + 1.0 * k / 8)
        cl.add((math.cos(a) * 0.1, h.y + 0.04 + math.sin(a) * 0.02, h.z + 0.04 + math.sin(a) * 0.06), (0.06, 0.07, 0.05),
               group="hood")
    cl.add((0, h.y + 0.08, h.z - 0.04), (0.12, 0.1, 0.1), group="hood")
    cl.add((0, -0.14, 0.74), (0.11, 0.08, 0.05), group="scarf")
    body = cl.build({"scale": "scale", "belly": "belly", "hood": "hood", "scarf": "scarf"}, voxel=0.006, budget=6000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.012, "strength": 0.004})
    recolor(body, lambda p, n: smoothstep(0.75, 0.92, math.sin(p.x * 50) * math.sin(p.y * 45) * math.sin(p.z * 40) + 0.3)
            * 0.8, "spot")
    skulpt.eyes(C, [(0.065, h.y - 0.07, h.z + 0.04)], 0.032, "eye", "pupil", slit=True)
    C.box("Grin", (0, h.y - 0.13, h.z - 0.06), (0.1, 0.01, 0.01), "dark", "head", rot=(0, 0, 0), bevel=0.4)
    for mx in (-1, 1):
        side = "L" if mx < 0 else "R"
        for k in range(3):
            C.ellipsoid(f"ToePad{side}{k}", tuple(at["ft" + side] + V((0.03 * (k - 1), -0.08, -0.02))), (0.018,) * 3, "belly",
                        f"shin.{side}")
    C.ellipsoid("Purse", tuple(at["hdL"] + V((0, -0.02, -0.06))), (0.05, 0.04, 0.06), "purse", "forearm.L")
    C.ellipsoid("Coin", tuple(at["hdL"] + V((0, -0.06, -0.02))), (0.02, 0.006, 0.02), "gold", "forearm.L")
    hr = at["hdR"]
    C.cone("Dagger", tuple(hr + V((0, -0.02, 0.02))), tuple(hr + V((0, -0.16, 0.14))), 0.018, "metal", "forearm.R", segs=4)
