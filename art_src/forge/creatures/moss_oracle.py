"""Moss Oracle (Mushroom Forest, 4): an ancient floating moss-mound seer. Sculpted: a heavy mound of moss
draped in long hanging lichen beards, a carved bark mask set with a great glowing third eye, two small
eyes on swaying stalks, and runestones circling it in slow orbit."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(moss="3f6a2a", moss2="6aa83a", lichen="a8c878", bark="5a3e28", eye="aef8ff", pupil="0a1a20", glow="c8ff5a",
              stone="7a7f78", rune="7affd8", stalk="4a5a2a")
    C.plan, C.attack, C.hover = "hover", "cast", 0.3
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.45), (0, 0, 0.8), "root")
    C.bone("head", (0, 0, 0.8), (0, -0.05, 1.15), "hips")
    C.bone("tail1", (0, 0, 0.45), (0, 0.04, 0.15), "hips")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1"]
    cl = Clay(C, "Body", res=0.02)
    cl.add((0, 0, 0.74), (0.4, 0.38, 0.34), group="moss")
    cl.add((0, 0, 1.0), (0.28, 0.26, 0.18), group="moss2")
    for k in range(14):                                                        # hanging lichen beards
        a = 2 * math.pi * k / 14
        cl.chain([(math.cos(a) * 0.36, math.sin(a) * 0.34, 0.6), (math.cos(a) * 0.38, math.sin(a) * 0.36, 0.36),
                  (math.cos(a) * 0.34, math.sin(a) * 0.32, 0.16 + 0.06 * (k % 3))], [0.06, 0.04, 0.015], group="lichen")
    cl.add((0, -0.32, 0.8), (0.2, 0.08, 0.2), group="bark")                      # bark mask
    cl.add((0, -0.38, 0.86), (0.06, 0.04, 0.07), group="bark", neg=True)
    body = cl.build({"moss": "moss", "moss2": "moss2", "lichen": "lichen", "bark": "bark"}, voxel=0.011, budget=8000,
                    relax=2, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.025})
    C.ellipsoid("ThirdEye", (0, -0.37, 0.86), (0.05, 0.025, 0.065), "glow", "head")
    C.ellipsoid("ThirdPupil", (0, -0.39, 0.86), (0.012, 0.01, 0.045), "pupil", "head")
    for mx in (-1, 1):
        b = V((0.14 * mx, -0.2, 1.04))
        top = b + V((0.08 * mx, -0.06, 0.2))
        C.tube(f"Stalk{mx}", [b, b + V((0.06 * mx, -0.02, 0.1)), top], [0.02, 0.016, 0.014], "stalk", "head")
        C.ellipsoid(f"Eye{mx}", tuple(top + V((0, 0, 0.03))), (0.04, 0.04, 0.04), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", tuple(top + V((0, -0.035, 0.03))), (0.016, 0.01, 0.018), "pupil", "head")
    C.bone("orbit", (0, 0, 0.7), (0, 0, 0.9), "root")
    for k in range(5):
        a = 2 * math.pi * k / 5
        p = V((math.cos(a) * 0.62, math.sin(a) * 0.6, 0.72 + 0.08 * math.sin(2 * a)))
        C.box(f"Rune{k}", tuple(p), (0.1, 0.05, 0.14), "stone", "orbit", rot=(0, 0, math.degrees(a)), bevel=0.4)
        C.box(f"RuneGlow{k}", tuple(p * 1.06), (0.04, 0.02, 0.07), "rune", "orbit", rot=(0, 0, math.degrees(a)), bevel=0.3)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 72 * t))
