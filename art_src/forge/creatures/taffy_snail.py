"""Taffy Snail (Candy Hills, 2): a slow, sticky giant snail carrying a towering swirl-lollipop shell, a
caramel body leaving a glossy trail, eye-stalks topped with gumdrop eyes and a stubborn scowl."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(body="d8944a", body2="ffc88a", shell1="ff3a8a", shell2="fff0f8", shell3="3ad8ff", eye="ffffff",
              pupil="2a0a0a", stalk="c8843a", trail="ffe0b0", dark="3a1a0a")
    C.attack = "ram"
    kits.fish(C, "body", [(-0.55, 0.22, 0.12), (-0.42, 0.2, 0.2), (-0.1, 0.13, 0.24), (0.2, 0.1, 0.22),
                          (0.45, 0.08, 0.13), (0.6, 0.06, 0.05)], mid=3, hover=0.0, jaw=False)
    C.plan = "hover"
    C.ellipsoid("Trail", (0, 0.1, 0.0), (0.26, 0.7, 0.02), "trail", "hips")
    C.decal("Foot", 0, -1, (0.2, 0.5, 0.03), "body2", "chest", dir=(0, 0, 1), y=0.0, spin=90)
    # swirl lollipop shell
    c = V((0, 0.12, 0.56))
    C.ellipsoid("Shell", tuple(c), (0.16, 0.36, 0.36), "shell2", "hips")
    for mx in (-1, 1):
        for k in range(18):
            a = k * 0.62
            r = 0.04 + k * 0.017
            p = c + V((0.16 * mx, math.cos(a) * r, math.sin(a) * r))
            C.ellipsoid(f"Swirl{mx}{k}", tuple(p), (0.02, 0.045, 0.045), "shell1" if k % 3 else "shell3", "hips")
    C.lathe("ShellRim", [(0.36, -0.03), (0.38, 0.0), (0.36, 0.03)], "shell1", "hips", segs=24)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(c) @
                                  __import__("mathutils").Matrix.Rotation(1.5708, 4, 'Y'))
    # eye stalks with gumdrop eyes
    for mx in (-1, 1):
        base = V((0.07 * mx, -0.48, 0.3))
        top = base + V((0.08 * mx, -0.08, 0.3))
        C.tube(f"Stalk{mx}", [base, base + V((0.03 * mx, -0.05, 0.15)), top], [0.035, 0.03, 0.025], "stalk", "head")
        C.ellipsoid(f"Eye{mx}", tuple(top + V((0, -0.02, 0.04))), (0.06, 0.05, 0.06), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", tuple(top + V((0, -0.065, 0.04))), (0.025, 0.012, 0.03), "pupil", "head")
        C.box(f"Lid{mx}", tuple(top + V((0, -0.04, 0.08))), (0.1, 0.06, 0.02), "body", "head", rot=(0, 20 * mx, 0), bevel=0.5)
        C.cone(f"Feeler{mx}", (0.06 * mx, -0.58, 0.18), (0.12 * mx, -0.7, 0.12), 0.02, "stalk", "head", segs=5)
    C.box("Scowl", (0, -0.65, 0.2), (0.08, 0.015, 0.015), "dark", "head", bevel=0.3)
