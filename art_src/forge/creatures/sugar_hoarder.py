"""Sugar Hoarder (Candy Hills, 4): a greedy candy vulture. Sculpted: a hunched vulture with a heavy dark
body, a fluffy white ruff around a long bare pink neck, a bald wrinkled head with a hooked beak and a
greedy eye, ragged wings held half open, and a bulging sack of stolen sweets clutched in its talons with
lollipops poking out."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(feather="5a2a5a", ruff="e8e0f0", head="ff8aa8", beak="ffc83a", eye="ff3a3a", dark="140a14", sack="c89a5a",
              rope="7a5a3a", pop1="ff4a8a", pop2="3ad8ff", stick="ffffff", wingtip="2a1030")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.08, 0.56), (0, -0.02, 0.8), "root")
    C.bone("neck", (0, -0.02, 0.8), (0, -0.14, 0.96), "hips")
    C.bone("head", (0, -0.14, 0.96), (0, -0.34, 0.98), "neck")
    C.bone("tail1", (0, 0.16, 0.56), (0, 0.36, 0.4), "hips")
    C.spine, C.neck, C.head, C.tail = ["hips"], ["neck"], "head", ["tail1"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.1 * sx, 0.04, 0.48), (0.1 * sx, -0.02, 0.3), "hips")
        C.bone(f"shin.{side}", (0.1 * sx, -0.02, 0.3), (0.1 * sx, -0.06, 0.12), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    skulpt.wing_bones(C, (0.2, 0.02, 0.8), (0.5, 0.12, 0.96), (0.86, 0.26, 0.82), parent="hips")
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, 0.06, 0.66), (0.22, 0.26, 0.22), rot=(-25, 0, 0), group="feather")
    for k in range(10):
        a = 2 * math.pi * k / 10
        cl.add((math.cos(a) * 0.13, -0.04 + math.sin(a) * 0.1, 0.84), (0.07, 0.07, 0.06), group="ruff")
    cl.chain([(0, -0.04, 0.84), (0, -0.14, 0.96), (0, -0.2, 0.98)], [0.05, 0.04, 0.045], group="head")
    cl.add((0, -0.22, 0.99), (0.07, 0.08, 0.065), group="head")
    cl.mirror((0.045, -0.26, 1.01), (0.02, 0.02, 0.018), group="head", neg=True)
    cl.chain([(0, 0.16, 0.56), (0, 0.36, 0.42)], [(0.12, 0.06, 0.05), (0.1, 0.04, 0.02)], group="feather")
    body = cl.build({"feather": "feather", "ruff": "ruff", "head": "head"}, voxel=0.008, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.012})
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.05 * mx, -0.265, 1.01), (0.014, 0.01, 0.012), "eye", "head")
        C.tube(f"Shin{mx}", [V((0.1 * mx, -0.02, 0.32)), V((0.1 * mx, -0.06, 0.12))], [0.022, 0.018], "head",
               f"shin.{'L' if mx < 0 else 'R'}")
        side = "L" if mx < 0 else "R"
        sh, el, tip = V((0.2 * mx, 0.02, 0.8)), V((0.5 * mx, 0.12, 0.96)), V((0.86 * mx, 0.26, 0.82))
        C.tube(f"WingArm{side}", [sh, el, tip], [0.05, 0.035, 0.02], "feather", None, allowed=[f"wing.{side}", f"wing2.{side}"])
        for k in range(7):
            t = k / 6
            base = sh.lerp(el, t * 2) if t < 0.5 else el.lerp(tip, (t - 0.5) * 2)
            d = V((0.2 * mx * t, 0.45, -0.85)).normalized()
            C.cone(f"Feather{side}{k}", tuple(base), tuple(base + d * (0.26 + 0.1 * t)), 0.045, "wingtip" if k % 2 else "feather",
                   f"wing.{side}" if t < 0.5 else f"wing2.{side}", segs=4)
    C.cone("Beak", (0, -0.28, 0.99), (0, -0.37, 0.95), 0.03, "beak", "head", segs=6, smooth=True)
    C.cone("BeakHook", (0, -0.36, 0.96), (0, -0.38, 0.91), 0.012, "beak", "head", segs=5)
    C.ellipsoid("Sack", (0, -0.1, 0.12), (0.17, 0.15, 0.15), "sack", "shin.R")
    C.tube("Rope", [V((-0.08, -0.1, 0.25)), V((0.08, -0.1, 0.25))], [0.015, 0.015], "rope", "shin.R")
    for k, (x, c) in enumerate([(-0.06, "pop1"), (0.05, "pop2")]):
        C.tube(f"PopStick{k}", [V((x, -0.1, 0.24)), V((x * 1.6, -0.12, 0.38))], [0.008, 0.008], "stick", "shin.R")
        C.ellipsoid(f"Pop{k}", (x * 1.6, -0.12, 0.42), (0.05, 0.02, 0.05), c, "shin.R")
