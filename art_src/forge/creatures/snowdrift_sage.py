"""Snowdrift Sage (Frost Peaks, 3): an old yeti hermit. Sculpted: a hunched, heavy-shouldered yeti in a
shaggy white coat, a weathered slate face with frost-blue war paint under bushy brows, a long braided
beard, small curled horns, a fur mantle hung with rune charms, and a staff topped with a floating snow
crystal."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import recolor, smoothstep


def build(C):
    C.palette(fur="eef4fa", shade="b8c8d8", face="7a9ab8", paint="3ad8ff", eye="ffffff", dark="0e1a2a", wood="5a4030",
              crystal="aef4ff", charm="ffcf5a", horn="d8cfb8")
    C.attack = "cast"
    cl, at = skulpt.biped(C, hip=0.66, chest=1.1, head=1.32, lean=0.22, shoulder_x=0.32, hip_x=0.15,
                          r_chest=(0.3, 0.24, 0.26), r_waist=(0.24, 0.2, 0.18), r_hips=(0.22, 0.18, 0.15),
                          r_head=(0.13, 0.13, 0.14), r_arm=(0.1, 0.09), r_hand=0.08, r_leg=(0.12, 0.1),
                          r_foot=(0.09, 0.12, 0.06), arm_len=0.62, group="fur")
    h = at["head"]
    for k in range(12):
        a = 2 * math.pi * k / 12
        cl.add((math.cos(a) * 0.28, -0.1 + math.sin(a) * 0.2, 1.08), (0.11, 0.11, 0.1), group="fur")   # mantle
    cl.add((0, h.y - 0.14, h.z - 0.01), (0.09, 0.06, 0.1), group="face")
    cl.add((0, h.y - 0.17, h.z + 0.07), (0.11, 0.05, 0.03), group="fur")          # bushy brow
    cl.mirror((0.04, h.y - 0.19, h.z + 0.02), (0.022, 0.02, 0.018), group="face", neg=True)
    cl.chain([(0, h.y - 0.18, h.z - 0.08), (0, h.y - 0.21, h.z - 0.24), (0, h.y - 0.19, h.z - 0.42)],
             [(0.08, 0.05, 0.06), (0.05, 0.04, 0.05), (0.025, 0.025, 0.04)], group="fur")    # braided beard
    body = cl.build({"fur": "fur", "face": "face"}, voxel=0.012, budget=10000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.035, "strength": 0.022})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.6, "shade")
    recolor(body, lambda p, n: (smoothstep(0.012, 0.0, abs(p.x) - 0.03 - abs(p.z - h.z) * 0.5)
                                * (1.0 if p.y < h.y - 0.15 and abs(p.z - h.z) < 0.06 else 0.0)), "paint")
    for k in range(4):
        C.ellipsoid(f"Braid{k}", (0, h.y - 0.205, h.z - 0.16 - 0.08 * k), (0.03, 0.03, 0.012), "charm", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.04 * mx, h.y - 0.195, h.z + 0.02), (0.014, 0.008, 0.01), "eye", "head")
        C.tube(f"Horn{mx}", [h + V((0.09 * mx, 0.0, 0.1)), h + V((0.17 * mx, 0.04, 0.14)), h + V((0.18 * mx, 0.1, 0.06))],
               [0.03, 0.022, 0.006], "horn", "head")
    for k in range(5):
        a = math.pi * (0.2 + 0.6 * k / 4)
        C.box(f"Charm{k}", (math.cos(a) * 0.3, -0.1 - math.sin(a) * 0.22, 0.96), (0.04, 0.012, 0.06), "charm", "chest",
              bevel=0.3)
    hr = at["hdR"]
    C.tube("Staff", [hr + V((0, 0.04, -0.6)), hr, hr + V((0.02, -0.04, 0.6))], [0.025, 0.025, 0.022], "wood", "forearm.R")
    C.ellipsoid("StaffCrystal", tuple(hr + V((0.02, -0.06, 0.78))), (0.07, 0.07, 0.11), "crystal", "forearm.R")
    for k in range(6):
        a = 2 * math.pi * k / 6
        C.cone(f"Flake{k}", tuple(hr + V((0.02, -0.06, 0.78))),
               tuple(hr + V((0.02 + math.cos(a) * 0.15, -0.06, 0.78 + math.sin(a) * 0.15))), 0.015, "crystal", "forearm.R",
               segs=4)
