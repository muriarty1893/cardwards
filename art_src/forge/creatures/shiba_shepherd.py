"""Shiba Shepherd (Dark Moon, 4): a stout guardian hound who herds lost dreams home. Sculpted: a sturdy,
deep-chested shiba with a russet coat and a cream mask and chest, pricked ears, a curled plume of a tail,
a night-blue mantle over the shoulders clasped with a moon brooch, and a shepherd's lantern hanging from
its collar."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fur="c8642a", cream="fff0d8", dark="1a0e08", eye="2a1a10", mantle="1a2a5a", trim="d8c8ff", moon="f0f4ff",
              lamp="ffe08a", metal="8a8aa0", nose="1a1010")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.28, 0.58), chest=(-0.2, 0.64), r_chest=(0.22, 0.24, 0.24), r_belly=(0.18, 0.24, 0.17),
                         r_hips=(0.18, 0.18, 0.18), leg_x=0.15, r_thigh=0.09, r_shin=0.055, r_paw=0.07, paw_len=1.1,
                         neck=((-0.34, 0.78),), r_neck=(0.14,), head=(-0.44, 0.86), r_head=(0.14, 0.13, 0.12),
                         snout=(-0.64, 0.8), r_snout=(0.08, 0.06), tail=((0.42, 0.74), (0.4, 0.92)), r_tail=(0.08, 0.06),
                         group="fur", belly_group="cream", jaw=True)
    h, s = at["head"], at["snout"]
    for sx in (-1, 1):
        cl.chain([(0.08 * sx, h.y + 0.02, h.z + 0.09), (0.11 * sx, h.y + 0.03, h.z + 0.2)], [(0.05, 0.025, 0.05), 0.012],
                 group="fur")
        cl.add((0.08 * sx, h.y - 0.06, h.z - 0.05), (0.06, 0.06, 0.05), group="cream")      # cream cheeks
    cl.add(tuple(s + V((0, 0.02, -0.02))), (0.07, 0.08, 0.05), group="cream")
    cl.add((0, -0.32, 0.58), (0.13, 0.08, 0.16), group="cream")
    cl.chain([(0, 0.42, 0.74), (0, 0.4, 0.92), (0, 0.3, 0.98), (0, 0.24, 0.9)], [0.08, 0.09, 0.07, 0.04], group="fur")
    body = cl.build({"fur": "fur", "cream": "cream"}, voxel=0.011, budget=9000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.01})
    skulpt.eyes(C, [(0.06, h.y - 0.11, h.z + 0.03)], 0.02, "eye", None)
    C.ellipsoid("Nose", tuple(s + V((0, -0.06, 0.02))), (0.028, 0.02, 0.02), "nose", "head")
    mantle = Clay(C, "Mantle", res=0.014)
    for k in range(11):
        a = math.radians(-80 + 16 * k)
        mantle.add((math.sin(a) * 0.27, -0.2, 0.66 + math.cos(a) * 0.27), (0.07, 0.2, 0.02), rot=(0, math.degrees(a), 0),
                   group="m")
    mb = mantle.build({"m": "mantle"}, voxel=0.009, relax=2, budget=2000, ao=0.3)
    recolor(mb, lambda p, n: smoothstep(0.03, 0.0, abs(p.y + 0.38)), "trim")
    C.ellipsoid("Brooch", (0, -0.42, 0.76), (0.04, 0.015, 0.04), "moon", "chest")
    C.tube("Collar", [V((-0.12, -0.36, 0.78)), V((0, -0.42, 0.72)), V((0.12, -0.36, 0.78))], [0.015, 0.015, 0.015], "metal",
           "neck")
    C.tube("LampHook", [V((0, -0.42, 0.7)), V((0, -0.44, 0.6))], [0.006, 0.006], "metal", "neck")
    C.ellipsoid("Lantern", (0, -0.44, 0.55), (0.04, 0.04, 0.05), "lamp", "neck")
