"""Glowmoth (Mushroom Forest, 2): a night moth the size of a hound. Sculpted: a thick, fuzzy body with a
shaggy collar of fur around the head, big dark eyes, feathered antennae, six thin legs, and two pairs of
broad wings marked with glowing eye-spots that stare down whatever it hunts."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fuzz="5a4a3a", fuzz2="c8b890", wing="3a2a4a", wing2="7a5aa8", spot="b8ff6a", spotc="1a1020", eye="ff8a3a",
              leg="2a2018")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.5
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.62), (0, -0.08, 0.66), "root")
    C.bone("head", (0, -0.08, 0.66), (0, -0.3, 0.68), "hips")
    C.bone("tail1", (0, 0.1, 0.62), (0, 0.4, 0.52), "hips")
    C.spine, C.head, C.tail = ["hips"], "head", ["tail1"]
    skulpt.wing_bones(C, (0.08, -0.02, 0.72), (0.4, 0.0, 0.84), (0.72, 0.08, 0.9), parent="hips")
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, -0.04, 0.66), (0.13, 0.13, 0.12), group="fuzz2")                     # thorax
    cl.chain([(0, 0.08, 0.64), (0, 0.26, 0.58), (0, 0.42, 0.52)], [0.11, 0.1, 0.05], group="fuzz")
    for k in range(8):                                                            # fur collar
        a = 2 * math.pi * k / 8
        cl.add((math.cos(a) * 0.1, -0.13 + math.sin(a) * 0.04, 0.66 + math.sin(a) * 0.08), (0.05, 0.05, 0.05),
               group="fuzz2")
    cl.add((0, -0.2, 0.66), (0.08, 0.07, 0.07), group="fuzz")
    body = cl.build({"fuzz": "fuzz", "fuzz2": "fuzz2"}, voxel=0.008, budget=6000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.015, "strength": 0.015})
    recolor(body, lambda p, n: smoothstep(0.5, 0.9, math.sin(p.y * 45)) * 0.5 * (1.0 if p.y > 0.1 else 0.0), "fuzz2")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, -0.25, 0.68), (0.045, 0.045, 0.05), "eye", "head")
        b = V((0.04 * mx, -0.25, 0.74))
        C.tube(f"Antenna{mx}", [b, b + V((0.08 * mx, -0.08, 0.14)), b + V((0.18 * mx, -0.06, 0.22))], [0.01, 0.008, 0.004],
               "leg", "head")
        for k in range(5):
            p = b + V((0.04 * mx + 0.03 * k * mx, -0.07, 0.08 + 0.03 * k))
            C.cone(f"Plume{mx}{k}", tuple(p), tuple(p + V((0.05 * mx, 0.0, 0.03))), 0.008, "fuzz2", "head", segs=4)
        side = "L" if mx < 0 else "R"
        for k, y in enumerate((-0.1, -0.02, 0.06)):
            C.tube(f"Leg{side}{k}", [V((0.06 * mx, y, 0.58)), V((0.14 * mx, y - 0.02, 0.5)), V((0.16 * mx, y, 0.38))],
                   [0.012, 0.01, 0.004], "leg", "hips")
        for k, (ln, wd, dy, dz) in enumerate(((0.56, 0.32, -0.08, 0.04), (0.4, 0.24, 0.2, -0.06))):
            pts = []
            for i in range(14):
                a = math.pi * i / 13
                u = (1 - math.cos(a)) / 2
                pts.append((0.08 * mx + mx * u * ln, -0.02 + dy + math.sin(a) * wd * (1.0 - 0.3 * u),
                            0.72 + dz + u * 0.5))
            if mx < 0:
                pts = pts[::-1]
            C.membrane(f"Wing{side}{k}", pts, "wing2" if k == 0 else "wing", None, thick=0.012,
                       allowed=[f"wing.{side}", f"wing2.{side}"])
            c = V((0.08 * mx + mx * ln * 0.6, -0.02 + dy + wd * 0.5, 0.72 + dz + 0.3))
            C.ellipsoid(f"Spot{side}{k}", tuple(c + V((0, 0, 0.012))), (0.07 - 0.02 * k, 0.07 - 0.02 * k, 0.012), "spot",
                        f"wing2.{side}")
            C.ellipsoid(f"SpotC{side}{k}", tuple(c + V((0, 0, 0.02))), (0.03 - 0.008 * k, 0.03 - 0.008 * k, 0.012), "spotc",
                        f"wing2.{side}")
