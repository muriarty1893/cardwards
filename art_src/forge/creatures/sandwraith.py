"""Sandwraith (Sunny Dunes, 4): the ghost of a desert raider, a hooded skull in tattered wrappings, a body
that dissolves into a whirling column of sand below the waist, and a pitted old scimitar."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(wrap="c8b080", wrap2="8a7a58", bone="e8dcc0", dark="1a1408", eye="3affd8", sand="e0c088", sand2="c8a060",
              metal="9a9a90", gold="c8902a")
    C.attack = "swipe"
    kits.biped(C, "wrap", hip=0.85, chest=1.28, neck=1.45, head_top=1.72, shoulder_x=0.26, hip_x=0.12,
               hand=(0.45, -0.12, 0.88), r_hip=0.18, r_waist=0.14, r_chest=0.22, r_neck=0.07, r_head=0.14,
               r_arm=0.06, r_hand=0.05, legs=False, hover=0.3)
    h = V(C.anch["head"])
    props.hooded_face(C, "wrap2", "dark", "eye", h, r=0.17, eye_gap=0.05, eye_size=0.025)
    C.ellipsoid("Skull", tuple(h + V((0, -0.1, -0.02))), (0.1, 0.06, 0.11), "bone", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Socket{mx}", tuple(h + V((0.04 * mx, -0.155, 0.01))), (0.025, 0.012, 0.025), "dark", "head")
        C.ellipsoid(f"Glow{mx}", tuple(h + V((0.04 * mx, -0.165, 0.01))), (0.012, 0.008, 0.012), "eye", "head")
    # whirling sand column instead of legs
    for k in range(6):
        a = k * 1.1
        pts = [V((math.cos(a + j * 0.9) * (0.24 - 0.035 * j), math.sin(a + j * 0.9) * (0.24 - 0.035 * j), 0.85 - 0.16 * j))
               for j in range(6)]
        C.tube(f"Sand{k}", pts, [0.06, 0.055, 0.045, 0.035, 0.025, 0.006], "sand" if k % 2 else "sand2", None,
               allowed=["hips", "tail1", "tail2"])
    # trailing wrappings
    c = V(C.anch["chest"])
    for k in range(4):
        C.box(f"Wrap{k}", tuple(c + V((-0.15 + 0.1 * k, 0.15, -0.3))), (0.06, 0.02, 0.35), "wrap2", "chest",
              rot=(15, 0, 10 * (k - 1.5)), bevel=0.3)
    for side in ("L", "R"):
        C.ellipsoid(f"Hand{side}", C.anch["hd" + side], (0.05, 0.05, 0.06), "bone", f"forearm.{side}")
    props.blade(C, C.anch["hdR"], "metal", "gold", "forearm.R", length=0.6, width=0.07, direction=(0, -0.35, -1),
                curve=0.12, guard=0.14)
