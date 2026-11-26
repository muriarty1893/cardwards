"""Bloodbow Ranger (Dark Moon, 3): a hooded night hunter. Sculpted: a lean, poised archer in a tattered
cloak that hangs in ragged strips, fitted leathers, a deep hood over a pale vampire's face masked below
the eyes, eyes that glint red, a crimson recurve bow held ready and a quiver of red-fletched arrows."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(cloak="2a1a2a", leather="4a2a2a", skin="d8ccd8", eye="ff2a3a", dark="0c060c", bow="8a1020", string="e8e0e8",
              fletch="ff3a4a", metal="8a8a98", mask="1a1014")
    C.attack = "cast"
    cl, at = skulpt.biped(C, hip=0.92, chest=1.38, head=1.62, lean=0.08, shoulder_x=0.22, hip_x=0.11,
                          r_chest=(0.19, 0.14, 0.18), r_waist=(0.13, 0.11, 0.12), r_hips=(0.15, 0.12, 0.11),
                          r_head=(0.1, 0.11, 0.12), r_arm=(0.055, 0.045), r_hand=0.04, r_leg=(0.075, 0.055),
                          r_foot=(0.05, 0.1, 0.04), arm_len=0.58, group="leather")
    h = at["head"]
    cape = [(0, 0.12, 1.5), (0, 0.18, 1.1), (0, 0.24, 0.6)]
    cl.chain(cape, [(0.24, 0.06, 0.1), (0.26, 0.06, 0.2), (0.28, 0.05, 0.2)], group="cloak")
    for k in range(5):                                                          # ragged strips
        cl.add((-0.2 + 0.1 * k, 0.24, 0.46 - 0.06 * (k % 2)), (0.04, 0.03, 0.12), group="cloak")
    cl.add((0, h.y + 0.01, h.z + 0.02), (0.13, 0.14, 0.15), group="cloak")          # hood
    cl.add((0, h.y - 0.1, h.z), (0.085, 0.07, 0.1), group="dark", neg=True)
    cl.add((0, h.y - 0.02, h.z), (0.075, 0.08, 0.09), group="skin")
    cl.add((0, h.y - 0.08, h.z - 0.04), (0.07, 0.04, 0.045), group="mask")
    body = cl.build({"leather": "leather", "cloak": "cloak", "dark": "dark", "skin": "skin", "mask": "mask"}, voxel=0.009,
                    budget=7000, relax=2, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.006})
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.03 * mx, h.y - 0.095, h.z + 0.02), (0.014, 0.008, 0.008), "eye", "head")
    hl = at["hdL"]
    top, bot = hl + V((0.02, -0.08, 0.5)), hl + V((0.02, -0.08, -0.5))
    C.tube("Bow", [top, top + V((0, -0.1, -0.14)), hl + V((0, -0.02, 0)), bot + V((0, -0.1, 0.14)), bot],
           [0.012, 0.02, 0.024, 0.02, 0.012], "bow", "forearm.L")
    C.tube("String", [top, bot], [0.003, 0.003], "string", "forearm.L")
    C.box("Quiver", (0.1, 0.16, 1.32), (0.08, 0.08, 0.36), "leather", "chest", rot=(-10, 0, -15), bevel=0.4)
    for k in range(4):
        b = V((0.12 + 0.02 * k, 0.16, 1.5))
        C.tube(f"Arrow{k}", [b, b + V((0.02, 0.02, 0.1))], [0.006, 0.006], "metal", "chest")
        C.cone(f"Fletch{k}", tuple(b + V((0.02, 0.02, 0.08))), tuple(b + V((0.025, 0.025, 0.16))), 0.02, "fletch", "chest", segs=3)
