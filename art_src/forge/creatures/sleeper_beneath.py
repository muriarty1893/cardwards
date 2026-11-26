"""The Sleeper Beneath (Dark Moon, 10, legend): an abyssal leviathan risen from the deep, a vast manta-like
body of midnight hide, a crown of bone spines, a cluster of half-open glowing eyes and a beard of tentacles
around a maw full of needle teeth."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(hide="12122a", hide2="2a2a5a", glow="7affd8", eye="d8ff8a", pupil="0a0a0a", tooth="e8e0d0",
              bone="c8c0a8", tent="3a1a5a", sucker="a87aff", lid="0a0a18")
    C.attack = "dive"
    kits.fish(C, "hide", [(-0.75, 0.5, 0.22), (-0.6, 0.48, 0.38, 0.3), (-0.28, 0.44, 0.45, 0.34), (0.05, 0.42, 0.38),
                          (0.38, 0.44, 0.22), (0.62, 0.5, 0.1), (0.82, 0.6, 0.04)], mid=3, hover=0.35)
    # vast manta wings
    for mx in (-1, 1):
        C.membrane(f"Wing{mx}", [(0.3 * mx, -0.45, 0.5), (1.05 * mx, -0.05, 0.62), (0.9 * mx, 0.12, 0.5),
                                 (0.3 * mx, 0.3, 0.42)][::(1 if mx > 0 else -1)], "hide", "chest", thick=0.06)
        C.membrane(f"WingGlow{mx}", [(0.62 * mx, -0.2, 0.6), (1.0 * mx, -0.05, 0.66), (0.62 * mx, 0.0, 0.58)][::(1 if mx > 0 else -1)],
                   "glow", "chest", thick=0.07)
    # cluster of eyes, some half-lidded
    for k, (x, z, s) in enumerate([(0.0, 0.66, 0.08), (-0.16, 0.6, 0.06), (0.16, 0.6, 0.06), (-0.1, 0.74, 0.045),
                                   (0.1, 0.74, 0.045), (-0.25, 0.5, 0.04), (0.25, 0.5, 0.04)]):
        loc, nor = C.surf(x, z, dir=(0, 1, 0))
        if loc is None:
            continue
        C.ellipsoid(f"Eye{k}", tuple(loc), (s, s * 0.6, s), "eye", "head")
        C.ellipsoid(f"Pupil{k}", tuple(loc + nor * s * 0.55), (s * 0.3, s * 0.2, s * 0.75), "pupil", "head")
        if k % 2:
            C.ellipsoid(f"Lid{k}", tuple(loc + nor * 0.01 + V((0, 0, s * 0.4))), (s * 1.1, s * 0.7, s * 0.6), "lid", "head")
    # maw with needle teeth and a tentacle beard
    C.ellipsoid("Maw", (0, -0.7, 0.36), (0.2, 0.1, 0.07), "pupil", "head")
    for k in range(8):
        x = -0.16 + 0.045 * k
        C.cone(f"Tooth{k}", (x, -0.74 + abs(x) * 0.4, 0.42), (x, -0.75 + abs(x) * 0.4, 0.33), 0.018, "tooth", "head", segs=4)
    for k in range(7):
        a = math.pi * (0.15 + 0.7 * k / 6)
        top = V((math.cos(a) * 0.22, -0.62 - math.sin(a) * 0.04, 0.32))
        pts = [top, top + V((math.cos(a) * 0.05, -0.08, -0.2)), top + V((math.cos(a) * 0.1, -0.02, -0.38)),
               top + V((math.cos(a) * 0.04, -0.1, -0.48))]
        C.tube(f"Tentacle{k}", pts, [0.045, 0.035, 0.02, 0.006], "tent", None, allowed=["head", "jaw"])
    # crown of bone spines along the back
    for k in range(6):
        y = -0.5 + 0.17 * k
        loc, nor = C.surf(0, 3, dir=(0, 0, -1), y=y)
        if loc is None:
            continue
        C.cone(f"Spine{k}", tuple(loc), tuple(loc + V((0, 0.12, 0.32 - 0.03 * abs(k - 1)))), 0.05, "bone",
               "chest" if y < 0.05 else "hips", segs=5)
    # glowing lines down the flanks
    for mx in (-1, 1):
        for k in range(4):
            C.decal(f"Line{mx}{k}", 0, 0.45, (0.02, 0.1, 0.015), "glow", "chest" if k < 2 else "hips", dir=(-mx, 0, 0),
                    y=-0.4 + 0.22 * k)
