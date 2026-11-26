"""Gluttonous Dreamer (Dark Moon, 6, legend): a colossal sleepwalking bull of the night pastures. Sculpted:
a mountain of a bull with a towering shoulder hump, a deep dewlapped chest and lighter hindquarters, a
massive head carried low, heavy-lidded dreaming eyes, great curved horns with a nightcap snagged on one,
a coat dappled with stars, and the dreams it has swallowed floating up from its back as glowing bubbles."""
import math
import random
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="2a2a5a", star="f0e8ff", horn="e8dcc0", horn2="b8a888", cap="7a3aa8", capw="f0e8ff",
              eye="ffe08a", lid="1a1a40", ring="d8b83a", bub1="aef4ff", bub2="ffb8f0", bub3="fff0a0",
              hoof="1a1028", dark="0a0a1a")
    C.plan, C.attack = "quad", "ram"
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.42, 0.98), (0, 0.0, 1.08), "root")
    C.bone("chest", (0, 0.0, 1.08), (0, -0.36, 1.12), "hips")
    C.bone("neck", (0, -0.36, 1.12), (0, -0.62, 1.06), "chest")
    C.bone("head", (0, -0.62, 1.06), (0, -1.0, 0.86), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    tail = [(0, 0.66, 1.0), (0, 0.76, 0.7), (0, 0.8, 0.44)]
    for i in range(2):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        legs[side] = dict(f=[(0.3 * sx, -0.36, 0.86), (0.32 * sx, -0.38, 0.44), (0.32 * sx, -0.4, 0.05)],
                          b=[(0.27 * sx, 0.46, 0.86), (0.28 * sx, 0.38, 0.46), (0.28 * sx, 0.46, 0.05)])
        f, b = legs[side]["f"], legs[side]["b"]
        C.bone(f"leg_f.{side}", f[0], f[1], "chest")
        C.bone(f"shin_f.{side}", f[1], f[2], f"leg_f.{side}")
        C.bone(f"leg_b.{side}", b[0], b[1], "hips")
        C.bone(f"shin_b.{side}", b[1], b[2], f"leg_b.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.032)
    cl.add((0, -0.26, 1.08), (0.42, 0.4, 0.4), group="hide")                    # huge forequarters
    cl.add((0, -0.2, 1.42), (0.28, 0.32, 0.2), rot=(-10, 0, 0), group="hide")   # towering hump
    cl.add((0, 0.12, 1.02), (0.36, 0.36, 0.32), group="hide")                   # barrel
    cl.add((0, 0.46, 1.0), (0.3, 0.26, 0.28), group="hide")                     # hindquarters
    cl.mirror((0.2, 0.5, 0.92), (0.14, 0.2, 0.24), group="hide")                # haunches
    cl.add((0, -0.48, 0.78), (0.14, 0.2, 0.22), group="hide")                   # dewlap
    cl.mirror((0.3, -0.36, 1.0), (0.14, 0.2, 0.24), group="hide")               # shoulders
    # massive neck flowing into the low-carried head
    cl.chain([(0, -0.4, 1.14), (0, -0.62, 1.06)], [(0.3, 0.26, 0.28), (0.24, 0.2, 0.24)], group="hide")
    cl.add((0, -0.74, 1.02), (0.24, 0.2, 0.2), group="hide")                    # broad skull
    cl.chain([(0, -0.8, 0.98), (0, -0.94, 0.88), (0, -1.02, 0.8)], [(0.2, 0.14, 0.17), (0.17, 0.12, 0.14),
                                                                   (0.17, 0.1, 0.12)], group="hide")
    cl.add((0, -1.04, 0.78), (0.16, 0.08, 0.1), group="muzzle")                 # wet muzzle
    cl.mirror((0.06, -1.1, 0.8), (0.03, 0.03, 0.025), group="muzzle", neg=True) # nostrils
    cl.mirror((0.17, -0.86, 1.04), (0.05, 0.05, 0.04), group="hide", neg=True)  # eye sockets
    cl.add((0, -0.78, 1.18), (0.18, 0.1, 0.06), group="hide")                   # poll / horn boss
    for sx in (-1, 1):
        f, b = legs["L" if sx < 0 else "R"]["f"], legs["L" if sx < 0 else "R"]["b"]
        cl.chain(f, [0.16, 0.11, 0.1], group="hide")
        cl.chain(b, [0.15, 0.1, 0.095], group="hide")
    cl.chain(tail, [0.05, 0.035, 0.025], group="hide")
    cl.add(tail[-1], (0.06, 0.06, 0.09), group="tuft")
    body = cl.build({"hide": "2a2a5a", "muzzle": "6a5a9a", "tuft": "f0e8ff"}, voxel=0.018, budget=11000,
                    texture={"type": 'CLOUDS', "scale": 0.06, "strength": 0.012})
    # star-dappled coat: pale dapples with bright pinpoint stars, a darker night along the back
    rnd = random.Random(6)
    cand = [v.co.copy() for v in body.data.vertices if v.normal.z > -0.2 and v.co.z > 0.6 and v.co.y > -0.75]
    stars = rnd.sample(cand, 45)
    recolor(body, lambda p, n: max(smoothstep(0.045, 0.0, (p - s).length) for s in stars), "f0e8ff")
    recolor(body, lambda p, n: max(smoothstep(0.1, 0.03, (p - s).length) for s in stars) * 0.45, "6a6aaa")
    recolor(body, lambda p, n: smoothstep(0.7, 1.0, n.z) * 0.5, "14143a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.17 * mx, -0.87, 1.04), (0.045, 0.03, 0.03), "eye", "head")
        C.ellipsoid(f"Lid{mx}", (0.17 * mx, -0.88, 1.06), (0.055, 0.04, 0.025), "lid", "head", rot=(15, 0, -10 * mx))
        C.ellipsoid(f"Ear{mx}", (0.3 * mx, -0.7, 1.08), (0.12, 0.05, 0.05), "hide", "head", rot=(0, 25 * mx, 0))
        base = V((0.16 * mx, -0.76, 1.18))
        pts = [base, base + V((0.26 * mx, 0.06, 0.04)), base + V((0.46 * mx, -0.06, 0.24)), base + V((0.42 * mx, -0.22, 0.44))]
        C.tube(f"Horn{mx}", pts, [0.085, 0.065, 0.042, 0.005], "horn", "head")
        for k in range(3):
            C.ellipsoid(f"HornRing{mx}{k}", tuple(V(pts[0]).lerp(V(pts[1]), 0.3 + 0.3 * k)), (0.075 - 0.008 * k,) * 2 +
                        (0.014,), "horn2", "head", rot=(0, 90, 0))
    C.lathe("NoseRing", [(0.06, 0.0), (0.07, 0.01), (0.06, 0.02)], "ring", "head", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, -1.1, 0.72)) @
                                  __import__("mathutils").Matrix.Rotation(1.57, 4, 'X'))
    # nightcap snagged on the right horn tip, drooping
    hb = V((0.16, -0.76, 1.18)) + V((0.42, -0.22, 0.44))
    C.cone("Cap", tuple(hb + V((0, 0, -0.06))), tuple(hb + V((0.2, 0.1, -0.22))), 0.11, "cap", "head", segs=12,
           smooth=True)
    C.ellipsoid("CapBand", tuple(hb + V((0, 0, -0.06))), (0.11, 0.11, 0.03), "capw", "head")
    C.ellipsoid("CapPom", tuple(hb + V((0.21, 0.1, -0.24))), (0.045,) * 3, "capw", "head")
    C.bone("dreams", (0, 0, 1.6), (0, 0, 2.0), "chest", deform=True)
    for k, (x, y, z, s, m) in enumerate([(0.1, -0.1, 1.78, 0.1, "bub1"), (-0.15, 0.15, 1.96, 0.08, "bub2"),
                                         (0.05, 0.3, 2.14, 0.06, "bub3"), (-0.05, -0.25, 2.1, 0.05, "bub1"),
                                         (0.2, 0.2, 2.2, 0.04, "bub2")]):
        C.ellipsoid(f"Dream{k}", (x, y, z), (s, s, s), m, "dreams")
    C.extra_idle.append(lambda P, t: (P.l("dreams", z=0.08 * math.sin(6.283 * t)),
                                      P.r("dreams", 'Z', 25 * math.sin(6.283 * t))))
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = V(legs[side][tag][2])
            C.lathe(f"Hoof{tag}{side}", [(0.12, 0.0), (0.13, 0.06), (0.1, 0.11)], "hoof", f"shin_{tag}.{side}", segs=12)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((paw.x, paw.y - 0.02, 0)))
