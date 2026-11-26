"""Moss Oracle (Mushroom Forest, 4): an ancient floating moss-mound seer, draped in hanging lichen, a great
glowing third eye in a bark mask, two small eyes on stalks, and runestones circling it in slow orbit."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(moss="3f6a2a", moss2="6aa83a", lichen="a8c878", bark="5a3e28", eye="aef8ff", pupil="0a1a20",
              glow="c8ff5a", stone="7a7f78", rune="7affd8", stalk="4a5a2a")
    C.attack = "cast"
    C.relax = 0.9
    kits.biped(C, "moss", hip=0.7, chest=0.95, neck=1.05, head_top=1.2, shoulder_x=0.32, hip_x=0.12,
               hand=(0.46, -0.12, 0.72), r_hip=0.35, r_waist=0.4, r_chest=0.42, r_neck=0.3, r_head=0.24,
               r_arm=0.06, r_hand=0.05, legs=False, hover=0.4)
    c = V(C.anch["chest"])
    # bark mask with a glowing third eye
    C.ellipsoid("Mask", (0, -0.36, 0.92), (0.22, 0.08, 0.22), "bark", "chest")
    C.ellipsoid("ThirdEye", (0, -0.43, 0.97), (0.09, 0.03, 0.065), "eye", "chest")
    C.ellipsoid("Pupil", (0, -0.455, 0.97), (0.02, 0.015, 0.05), "pupil", "chest")
    for mx in (-1, 1):
        C.decal(f"MaskRune{mx}", 0.12 * mx, 0.82, (0.03, 0.06, 0.015), "glow", "chest", part="Mask")
        # eye stalks
        top = V((0.2 * mx, -0.18, 1.42))
        C.bone(f"stalk.{'L' if mx < 0 else 'R'}", (0.12 * mx, -0.12, 1.12), tuple(top), "chest")
        C.tube(f"Stalk{mx}", [V((0.12 * mx, -0.12, 1.12)), V((0.18 * mx, -0.18, 1.28)), top], [0.03, 0.025, 0.02], "stalk",
               f"stalk.{'L' if mx < 0 else 'R'}")
        C.ellipsoid(f"StalkEye{mx}", tuple(top + V((0, -0.03, 0.03))), (0.05, 0.05, 0.05), "eye",
                    f"stalk.{'L' if mx < 0 else 'R'}")
        C.ellipsoid(f"StalkPupil{mx}", tuple(top + V((0, -0.07, 0.03))), (0.02, 0.012, 0.02), "pupil",
                    f"stalk.{'L' if mx < 0 else 'R'}")
    C.extra_idle.append(lambda P, t: (P.r("stalk.L", 'Y', 12 * math.sin(6.283 * t)), P.r("stalk.R", 'Y', -12 * math.sin(6.283 * t + 1))))
    # hanging lichen beard and moss tufts
    for k in range(9):
        a = math.pi * (0.1 + 0.8 * k / 8)
        b = V((math.cos(a) * 0.3, -0.28 + (1 - math.sin(a)) * 0.15, 0.7))
        C.cone(f"Lichen{k}", tuple(b), tuple(b + V((0, -0.02, -0.3 - 0.08 * (k % 3)))), 0.06, "lichen", "hips", segs=5,
               smooth=True)
    for k in range(6):
        a = 2 * math.pi * k / 6
        C.decal(f"Tuft{k}", math.cos(a) * 0.25, 2, (0.12, 0.12, 0.05), "moss2", "chest", dir=(0, 0, -1), y=math.sin(a) * 0.25)
    # orbiting runestones
    C.bone("orbit", (0, 0, 0.8), (0, 0, 1.0), "root")
    for k in range(4):
        a = 2 * math.pi * k / 4
        p = V((math.cos(a) * 0.62, math.sin(a) * 0.62, 0.85 + 0.15 * math.sin(2 * a)))
        C.box(f"Stone{k}", tuple(p), (0.1, 0.06, 0.14), "stone", "orbit", rot=(0, 0, math.degrees(a)), bevel=0.4)
        C.box(f"Rune{k}", tuple(p + V((math.cos(a) * 0.03, math.sin(a) * 0.03, 0))), (0.04, 0.03, 0.07), "rune", "orbit",
              rot=(0, 0, math.degrees(a)), bevel=0.3)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 90 * t))
