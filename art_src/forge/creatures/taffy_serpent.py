"""Taffy Serpent (Candy Hills, 3): a thick pulled-taffy cobra. Sculpted: a heavy coiled body banded pink
and cream, rearing up into a broad flared hood marked with a candy-swirl eye pattern, a wedge head with a
heavy brow, rock-sugar fangs and a forked licorice tongue."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(taffy="ff7ab0", band="fff0d8", hood="8a1040", swirl="ffd0e8", eye="ffe23a", pupil="1a0a04", tongue="1a0a10",
              fang="ffffff")
    C.plan, C.attack = "biped", "bite"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.16), (0, 0.0, 0.5), "root")
    C.bone("chest", (0, 0.0, 0.5), (0, -0.06, 0.84), "hips")
    C.bone("neck", (0, -0.06, 0.84), (0, -0.1, 1.02), "chest")
    C.bone("head", (0, -0.1, 1.02), (0, -0.3, 1.04), "neck")
    C.bone("jaw", (0, -0.14, 0.98), (0, -0.3, 0.96), "head")
    C.spine, C.neck, C.head, C.jaw = ["hips", "chest"], ["neck"], "head", "jaw"
    coil = []
    for k in range(16):
        t = k / 15
        a = t * 2.2 * math.pi
        r = 0.28 * (1 - 0.3 * t)
        coil.append(V((math.cos(a) * r, 0.1 + math.sin(a) * r, 0.1 + 0.02 * t)))
    C.bone("tail1", tuple(coil[0]), tuple(coil[7]), "hips")
    C.bone("tail2", tuple(coil[7]), tuple(coil[15]), "tail1")
    C.tail = ["tail1", "tail2"]
    cl = Clay(C, "Body", res=0.016)
    cl.chain(coil, [0.11 - 0.005 * i for i in range(16)], group="taffy", steps=1)
    cl.chain([V((0.28, 0.1, 0.12)), V((0.1, 0.06, 0.4)), V((0, -0.02, 0.7)), V((0, -0.08, 0.92)), V((0, -0.14, 1.02))],
             [0.12, 0.11, 0.1, 0.09, 0.08], group="taffy")
    cl.add((0, -0.02, 0.86), (0.24, 0.05, 0.2), rot=(-10, 0, 0), group="hood")        # flared hood
    cl.add((0, -0.2, 1.03), (0.08, 0.12, 0.06), group="taffy")                        # head
    cl.mirror((0.05, -0.22, 1.08), (0.04, 0.06, 0.02), rot=(0, 0, -15), group="hood")
    body = cl.build({"taffy": "taffy", "hood": "hood"}, voxel=0.009, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.004})
    recolor(body, lambda p, n: smoothstep(0.3, 0.7, math.sin((p.x * 0.5 + p.y * 0.7 + p.z) * 28)) * (1.0 if p.z < 0.75 or abs(p.x) < 0.08 else 0.0),
            "band")
    for mx in (-1, 1):                                                              # swirl eye pattern on the hood
        c = V((0.12 * mx, 0.04, 0.88))
        C.ellipsoid(f"Swirl{mx}", tuple(c), (0.06, 0.012, 0.06), "swirl", "chest")
        C.ellipsoid(f"SwirlC{mx}", tuple(c + V((0, 0.006, 0))), (0.03, 0.012, 0.03), "hood", "chest")
        C.ellipsoid(f"Eye{mx}", (0.055 * mx, -0.25, 1.06), (0.018, 0.016, 0.014), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", (0.06 * mx, -0.262, 1.06), (0.004, 0.006, 0.012), "pupil", "head")
        C.cone(f"Fang{mx}", (0.03 * mx, -0.28, 1.0), (0.03 * mx, -0.29, 0.94), 0.01, "fang", "head", segs=4)
    C.tube("Tongue", [V((0, -0.3, 0.99)), V((0, -0.38, 0.98))], [0.008, 0.006], "tongue", "jaw")
    for mx in (-1, 1):
        C.tube(f"Fork{mx}", [V((0, -0.38, 0.98)), V((0.015 * mx, -0.43, 0.99))], [0.006, 0.002], "tongue", "jaw")
