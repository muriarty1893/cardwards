"""Gumdrop Baker (Candy Hills, 3): a burly sugar-crusted gumdrop golem. Sculpted: a stout gumdrop body
with thick arms and stubby legs, sugar crystals crusting its shoulders and head, a tall puffed chef's hat,
a pink apron, a huge rolling pin swung in both fists and a tray of fresh gumdrops strapped to its back."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(gum="2ad07a", sugar="c8ffe0", dark="0e2a1a", eye="fff2a0", hat="ffffff", apron="ff9ac0", wood="d89a5a",
              tray="b0b0b8", g1="ff4a6a", g2="ffd23a", g3="7a5aff")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.44, chest=0.8, head=1.02, lean=0.06, shoulder_x=0.3, hip_x=0.14,
                          r_chest=(0.3, 0.26, 0.28), r_waist=(0.3, 0.26, 0.2), r_hips=(0.28, 0.24, 0.14),
                          r_head=(0.15, 0.15, 0.14), r_arm=(0.09, 0.08), r_hand=0.08, r_leg=(0.1, 0.09),
                          r_foot=(0.09, 0.12, 0.05), arm_len=0.46, group="gum")
    h = at["head"]
    cl.add((0, -0.2, 0.6), (0.27, 0.12, 0.3), rot=(-8, 0, 0), group="apron")
    cl.mirror((0.06, h.y - 0.13, h.z + 0.02), (0.03, 0.025, 0.025), group="dark", neg=True)
    cl.add((0, h.y - 0.13, h.z + 0.06), (0.11, 0.05, 0.025), rot=(-12, 0, 0), group="gum")
    hat = [(0, h.y + 0.01, h.z + 0.18), (0, h.y + 0.02, h.z + 0.3)]
    for k in range(6):
        a = 2 * math.pi * k / 6
        cl.add((math.cos(a) * 0.09, h.y + 0.02 + math.sin(a) * 0.09, h.z + 0.32), (0.08, 0.08, 0.08), group="hat")
    cl.chain(hat, [0.12, 0.12], group="hat")
    body = cl.build({"gum": "gum", "apron": "apron", "dark": "gum", "hat": "hat"}, voxel=0.011, budget=8000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.012, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.45, 0.9, n.z) * (0.0 if p.z > h.z + 0.14 else 0.9), "sugar")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, h.y - 0.145, h.z + 0.02), (0.022, 0.01, 0.016), "eye", "head")
    hl, hr = at["hdL"], at["hdR"]
    mid = (hl + hr) / 2 + V((0, -0.14, 0.05))
    C.tube("Pin", [mid + V((-0.45, 0, 0)), mid + V((0.45, 0, 0))], [0.075, 0.075], "wood", "forearm.R")
    for mx in (-1, 1):
        C.tube(f"PinHandle{mx}", [mid + V((0.45 * mx, 0, 0)), mid + V((0.58 * mx, 0, 0))], [0.03, 0.03], "wood", "forearm.R")
    C.box("Tray", (0, 0.32, 0.86), (0.48, 0.06, 0.4), "tray", "chest", rot=(-10, 0, 0), bevel=0.2)
    for k in range(6):
        C.ellipsoid(f"Drop{k}", (-0.14 + 0.14 * (k % 3), 0.37, 0.76 + 0.16 * (k // 3)), (0.06, 0.05, 0.06),
                    ("g1", "g2", "g3")[k % 3], "chest")
