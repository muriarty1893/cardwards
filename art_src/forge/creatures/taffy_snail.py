"""Taffy Snail (Candy Hills, 2): a slow, sticky giant snail. Sculpted: a long glossy caramel foot with a
paler rim that leaves a sticky trail, a stubborn scowling face, two eye-stalks topped with gumdrop eyes,
and a towering spiral lollipop shell in pink, white and blue swirls."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(body="d8944a", body2="ffc88a", shell1="ff3a8a", shell2="fff0f8", shell3="3ad8ff", eye="ffffff", pupil="2a0a0a",
              stalk="c8843a", trail="ffe0b0", dark="3a1a0a")
    C.plan, C.attack = "hover", "ram"
    C.hover = 0.0
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.24, 0.16), (0, -0.06, 0.2), "root")
    C.bone("chest", (0, -0.06, 0.2), (0, -0.3, 0.28), "hips")
    C.bone("head", (0, -0.3, 0.28), (0, -0.46, 0.4), "chest")
    C.bone("tail1", (0, 0.24, 0.16), (0, 0.42, 0.08), "hips")
    C.spine, C.head, C.tail = ["hips", "chest"], "head", ["tail1"]
    cl = Clay(C, "Body", res=0.016)
    cl.chain([V((0, 0.44, 0.06)), V((0, 0.1, 0.12)), V((0, -0.22, 0.2)), V((0, -0.38, 0.34))],
             [(0.08, 0.1, 0.05), (0.18, 0.2, 0.1), (0.15, 0.16, 0.14), (0.11, 0.1, 0.11)], group="body")
    cl.add((0, 0.06, 0.04), (0.2, 0.44, 0.04), group="body2")                       # pale rim / foot
    cl.add((0, -0.46, 0.38), (0.08, 0.03, 0.02), rot=(-30, 0, 0), group="body")       # scowl
    cl.add((0, -0.48, 0.3), (0.05, 0.02, 0.012), group="dark", neg=True)
    body = cl.build({"body": "body", "body2": "body2", "dark": "body"}, voxel=0.009, budget=5000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.004})
    recolor(body, lambda p, n: smoothstep(0.75, 1.0, n.z) * 0.4, "body2")
    shell = Clay(C, "Shell", res=0.016)
    for k in range(26):                                                       # lollipop spiral
        t = k / 25
        a = t * 3.2 * math.pi
        r = 0.27 * (1 - t * 0.85)
        shell.add((math.sin(a) * 0.04, 0.12 + math.cos(a) * r, 0.42 + math.sin(a) * r), (0.08 + 0.05 * (1 - t), 0.07, 0.07),
                  group=("s1", "s2", "s3")[k % 3])
    shell.add((0, 0.12, 0.42), (0.1, 0.26, 0.26), group="s2")
    sb = shell.build({"s1": "shell1", "s2": "shell2", "s3": "shell3"}, voxel=0.009, budget=4000, relax=1,
                     texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.003}, bone="hips")
    for mx in (-1, 1):
        b = V((0.05 * mx, -0.42, 0.42))
        top = b + V((0.05 * mx, -0.06, 0.22))
        C.tube(f"Stalk{mx}", [b, b + V((0.03 * mx, -0.02, 0.12)), top], [0.02, 0.016, 0.014], "stalk", "head")
        C.ellipsoid(f"Eye{mx}", tuple(top + V((0, 0, 0.03))), (0.035,) * 3, "eye", "head")
        C.ellipsoid(f"Pupil{mx}", tuple(top + V((0, -0.03, 0.03))), (0.013, 0.01, 0.016), "pupil", "head")
    C.ellipsoid("Trail", (0, 0.62, 0.005), (0.14, 0.22, 0.008), "trail", "tail1")
