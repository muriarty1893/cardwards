"""Sandwraith (Sunny Dunes, 4): the ghost of a desert raider. Sculpted: a gaunt torso in tattered,
flapping wrappings, a hooded skull with cold glowing eyes, bony arms, and a body that dissolves below the
waist into a whirling column of sand; a pitted old scimitar in one hand."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(wrap="c8b080", wrap2="8a7a58", bone="e8dcc0", dark="1a1408", eye="3affd8", sand="e0c088", sand2="c8a060",
              metal="9a9a90", gold="c8902a")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.9, chest=1.26, head=1.5, lean=0.12, shoulder_x=0.24, hip_x=0.1,
                          r_chest=(0.19, 0.14, 0.18), r_waist=(0.12, 0.1, 0.12), r_hips=(0.14, 0.12, 0.1),
                          r_head=(0.1, 0.11, 0.12), r_arm=(0.045, 0.035), r_hand=0.04, arm_len=0.56, legs=False,
                          hover=0.15, group="wrap")
    h = at["head"]
    for k in range(14):                                                        # whirling sand column
        t = k / 13
        a = t * 4 * math.pi
        r = 0.12 + 0.16 * t
        cl.add((math.cos(a) * r * 0.6, 0.04 + math.sin(a) * r * 0.6, 0.86 - 0.8 * t), (0.1 + 0.08 * t, 0.1 + 0.08 * t, 0.07),
               group="sand")
    cl.add((0, h.y, h.z + 0.02), (0.13, 0.14, 0.15), group="wrap2")                 # hood
    cl.add((0, h.y - 0.1, h.z), (0.09, 0.08, 0.11), group="dark", neg=True)
    cl.add((0, h.y - 0.02, h.z - 0.01), (0.075, 0.08, 0.09), group="bone")          # skull
    cl.mirror((0.03, h.y - 0.08, h.z + 0.01), (0.022, 0.02, 0.02), group="dark", neg=True)
    for k in range(6):                                                         # tattered strips
        a = 2 * math.pi * k / 6
        cl.add((math.cos(a) * 0.15, math.sin(a) * 0.12, 0.98), (0.045, 0.02, 0.14), rot=(0, 0, math.degrees(a) + 90),
               group="wrap2")
    body = cl.build({"wrap": "wrap", "wrap2": "wrap2", "sand": "sand", "bone": "bone", "dark": "dark"}, voxel=0.009,
                    budget=7000, relax=2, texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.015})
    recolor(body, lambda p, n: smoothstep(0.6, 0.9, math.sin(p.z * 40 + math.atan2(p.x, p.y) * 3)) * (1.0 if p.z < 0.85 else 0.0),
            "sand2")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.03 * mx, h.y - 0.095, h.z + 0.01), (0.014, 0.008, 0.012), "eye", "head")
    props.blade(C, at["hdR"], "metal", "gold", "forearm.R", length=0.55, width=0.1, direction=(0, -0.4, 1), guard=0.12)
