"""Sand Scuttler (Sunny Dunes, 1): a desert crab with a sun-bleached shell striped like the dunes, eyes
on tall stalks, one oversized crushing claw and one small cutting claw, and six spiky legs."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(shell="d88a3a", shell2="f0c070", stripe="a85a2a", claw="c8602a", tip="2a1408", eye="1a0a04",
              stalk="d89a5a", leg="b8682a")
    C.plan, C.attack = "quad", "bite"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.35), (0, -0.1, 0.38), "root")
    C.bone("chest", (0, -0.1, 0.38), (0, -0.3, 0.4), "hips")
    C.bone("head", (0, -0.3, 0.42), (0, -0.4, 0.55), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.25 * sx, -0.25, 0.38), (0.36 * sx, -0.45, 0.42), "chest")
        C.bone(f"forearm.{side}", (0.36 * sx, -0.45, 0.42), (0.34 * sx, -0.62, 0.48), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    C.ellipsoid("Shell", (0, 0.0, 0.42), (0.38, 0.32, 0.2), "shell", None)
    C.parts[-1] = (C.parts[-1][0], None, ["hips", "chest"])
    C.ellipsoid("Belly", (0, 0.0, 0.32), (0.34, 0.28, 0.1), "shell2", "hips")
    for k in range(3):
        C.ellipsoid(f"Stripe{k}", (0, -0.1 + 0.12 * k, 0.6 - 0.02 * k), (0.32 - 0.04 * k, 0.03, 0.04), "stripe",
                    "chest" if k == 0 else "hips")
    for k in range(5):
        a = math.pi * (0.1 + 0.8 * k / 4)
        C.cone(f"Spike{k}", (math.cos(a) * 0.34, -0.2 + 0.05 * abs(k - 2), 0.48), (math.cos(a) * 0.42, -0.3, 0.52), 0.025,
               "stripe", "chest", segs=4)
    for mx in (-1, 1):
        base = V((0.08 * mx, -0.25, 0.55))
        top = base + V((0.03 * mx, -0.05, 0.25))
        C.tube(f"Stalk{mx}", [base, top], [0.025, 0.02], "stalk", "head")
        C.ellipsoid(f"Eye{mx}", tuple(top + V((0, 0, 0.03))), (0.04, 0.04, 0.045), "eye", "head")
        for k, y in enumerate((-0.05, 0.08, 0.2)):
            C.tube(f"Leg{mx}{k}", [V((0.3 * mx, y, 0.35)), V((0.5 * mx, y + 0.03, 0.42)), V((0.55 * mx, y + 0.05, 0.0))],
                   [0.035, 0.03, 0.01], "leg", "hips")
    # big crusher (right) and small cutter (left)
    for side, mx, s in (("L", -1, 0.65), ("R", 1, 1.0)):
        fa = C.bones[f"forearm.{side}"]
        C.tube(f"Arm{side}", [C.bones[f"arm.{side}"]["head"], fa["head"]], [0.05 * s, 0.05 * s], "claw", f"arm.{side}")
        p = fa["tail"]
        C.ellipsoid(f"Claw{side}", tuple(p), (0.11 * s, 0.14 * s, 0.09 * s), "claw", f"forearm.{side}")
        C.cone(f"Pincer{side}", tuple(p + V((0, -0.08 * s, 0.03))), tuple(p + V((0.02 * mx, -0.26 * s, 0.06))), 0.06 * s, "claw",
               f"forearm.{side}", segs=6, smooth=True)
        C.cone(f"Pincer2{side}", tuple(p + V((0, -0.08 * s, -0.03))), tuple(p + V((0.04 * mx, -0.22 * s, -0.04))), 0.045 * s,
               "tip", f"forearm.{side}", segs=6, smooth=True)
