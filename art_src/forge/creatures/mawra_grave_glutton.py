"""Mawra, the Grave Glutton (Dark Moon, 5, legend): a squat, bloated ghoul-hound that is mostly mouth.
Sculpted: a hairless, hunched body sagging under a swollen stitched belly, bony spine and shoulder blades
pushing through the skin, thin crooked legs with long claws, and a huge head split by a gaping jaw lined
with too many teeth, a drooling tongue lolling out, tiny mad eyes set high on the skull."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(stitch="2a1a2a", tongue="d84a7a", tooth="f0e8d0", eye="d8ff3a", dark="0a060c", drool="c8f0ff",
              bone="e8dcc0", claw="1a1018", gum="7a1a3a")
    C.plan, C.attack = "quad", "bite"
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.32, 0.66), (0, 0.0, 0.72), "root")
    C.bone("chest", (0, 0.0, 0.72), (0, -0.28, 0.78), "hips")
    C.bone("neck", (0, -0.28, 0.78), (0, -0.42, 0.78), "chest")
    C.bone("head", (0, -0.42, 0.78), (0, -0.86, 0.78), "neck")
    C.bone("jaw", (0, -0.42, 0.62), (0, -0.84, 0.44), "head")
    C.spine, C.neck, C.head, C.jaw = ["hips", "chest"], ["neck"], "head", "jaw"
    C.bone("tail1", (0, 0.48, 0.7), (0, 0.66, 0.6), "hips")
    C.bone("tail2", (0, 0.66, 0.6), (0, 0.78, 0.42), "tail1")
    C.tail = ["tail1", "tail2"]
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        legs[side] = dict(f=[(0.26 * sx, -0.26, 0.7), (0.34 * sx, -0.3, 0.36), (0.32 * sx, -0.4, 0.04)],
                          b=[(0.24 * sx, 0.38, 0.62), (0.3 * sx, 0.26, 0.34), (0.3 * sx, 0.42, 0.04)])
        f, b = legs[side]["f"], legs[side]["b"]
        C.bone(f"leg_f.{side}", f[0], f[1], "chest")
        C.bone(f"shin_f.{side}", f[1], f[2], f"leg_f.{side}")
        C.bone(f"leg_b.{side}", b[0], b[1], "hips")
        C.bone(f"shin_b.{side}", b[1], b[2], f"leg_b.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.026)
    cl.add((0, 0.06, 0.6), (0.36, 0.38, 0.3), group="belly")                    # swollen belly, sagging low
    cl.add((0, 0.06, 0.78), (0.26, 0.42, 0.16), group="skin")                   # back
    cl.add((0, 0.38, 0.68), (0.22, 0.18, 0.18), group="skin")                   # rump
    cl.mirror((0.2, -0.24, 0.82), (0.12, 0.12, 0.1), group="skin")              # hunched shoulders
    for k in range(7):                                                          # knobbly spine
        cl.add((0, -0.26 + 0.11 * k, 0.94 - 0.02 * abs(k - 3)), (0.04, 0.035, 0.04), group="skin")
    cl.mirror((0.14, -0.14, 0.9), (0.08, 0.1, 0.03), rot=(0, -25, 0), group="skin")   # shoulder blades
    for k in range(4):                                                          # ribs showing at the flanks
        cl.mirror((0.27, -0.2 + 0.08 * k, 0.76), (0.02, 0.025, 0.09), rot=(0, 20, 0), group="skin")
    # the head: a huge skull over a gaping split jaw
    cl.add((0, -0.52, 0.86), (0.25, 0.24, 0.16), group="skin")                  # cranium
    cl.chain([(0, -0.56, 0.84), (0, -0.74, 0.8), (0, -0.88, 0.74)], [(0.24, 0.12, 0.12), (0.2, 0.1, 0.1),
                                                                    (0.16, 0.06, 0.08)], group="skin")
    cl.add((0, -0.7, 0.72), (0.2, 0.22, 0.05), group="gum", neg=True)           # upper palate
    cl.chain([(0, -0.48, 0.6), (0, -0.66, 0.5), (0, -0.84, 0.42)], [(0.22, 0.12, 0.08), (0.2, 0.1, 0.06),
                                                                   (0.15, 0.06, 0.05)], group="skin")   # lower jaw
    cl.add((0, -0.68, 0.56), (0.17, 0.2, 0.04), group="gum", neg=True)
    cl.mirror((0.1, -0.6, 0.98), (0.035, 0.03, 0.03), group="skin", neg=True)   # little sunken eyes
    for sx in (-1, 1):
        f, b = legs["L" if sx < 0 else "R"]["f"], legs["L" if sx < 0 else "R"]["b"]
        cl.chain(f, [0.08, 0.05, 0.045], group="skin")
        cl.chain(b, [0.1, 0.055, 0.045], group="skin")
        for leg in (f, b):
            cl.add((leg[2][0], leg[2][1] - 0.03, 0.04), (0.07, 0.08, 0.035), group="skin")
    cl.chain([(0, 0.48, 0.7), (0, 0.66, 0.6), (0, 0.78, 0.42)], [0.05, 0.035, 0.015], group="skin")
    body = cl.build({"skin": "4a3a5a", "belly": "8a7a9a", "gum": "5a0a2a"}, voxel=0.015, budget=11000,
                    texture={"type": 'CLOUDS', "scale": 0.06, "strength": 0.01})
    # mottled grave-skin, bruised veins on the belly, the inside of the maw
    recolor(body, lambda p, n: smoothstep(0.1, 0.0, abs(math.sin(p.x * 22 + math.sin(p.y * 13) * 2))) * 0.45
            * (1.0 if p.z < 0.7 and -0.3 < p.y < 0.4 else 0.0), "5a3a6a")
    recolor(body, lambda p, n: (1.0 if p.y < -0.45 and 0.5 < p.z < 0.76 and abs(p.x) < 0.17 else 0.0), "5a0a2a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.615, 0.98), (0.022, 0.014, 0.018), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", (0.1 * mx + 0.005 * mx, -0.63, 0.98), (0.006, 0.006, 0.006), "dark", "head")
        C.cone(f"Ear{mx}", (0.16 * mx, -0.44, 0.96), (0.28 * mx, -0.36, 1.06), 0.04, "stitch", "head", segs=5)
    # rows of crooked teeth
    for k in range(9):
        t = k / 8
        a = math.pi * (0.08 + 0.84 * t)
        x, y = math.cos(a) * 0.17, -0.5 - math.sin(a) * 0.38
        C.cone(f"ToothU{k}", (x, y, 0.72), (x * 0.95, y - 0.01, 0.64 - 0.03 * (k % 2)), 0.024, "tooth", "head", segs=4)
        x2, y2 = math.cos(a) * 0.15, -0.5 - math.sin(a) * 0.34
        C.cone(f"ToothL{k}", (x2, y2, 0.54 - 0.06 * t), (x2 * 0.95, y2 - 0.01, 0.62 - 0.05 * t + 0.02 * (k % 2)), 0.02,
               "tooth", "jaw", segs=4)
    C.tube("Tongue", [V((0, -0.52, 0.56)), V((0, -0.74, 0.54)), V((0.06, -0.92, 0.46)), V((0.08, -0.96, 0.32))],
           [0.07, 0.065, 0.05, 0.03], "tongue", "jaw")
    for k, (x, y) in enumerate([(0.1, -0.82), (-0.12, -0.78)]):
        C.tube(f"Drool{k}", [V((x, y, 0.62)), V((x, y - 0.01, 0.48)), V((x, y, 0.36))], [0.014, 0.01, 0.018], "drool",
               "head")
    # stitches across the belly
    for k in range(6):
        y = -0.16 + 0.07 * k
        C.box(f"StitchLine{k}", (0, y, 0.305), (0.012, 0.06, 0.01), "stitch", "hips" if y > 0.0 else "chest")
        C.box(f"Stitch{k}", (0, y, 0.305), (0.09, 0.012, 0.01), "stitch", "hips" if y > 0.0 else "chest")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            ft = V(legs[side][tag][2])
            for k in (-1, 0, 1):
                C.cone(f"Claw{tag}{side}{k}", (ft.x + 0.035 * k, ft.y - 0.08, 0.04), (ft.x + 0.045 * k, ft.y - 0.15, 0.0),
                       0.014, "claw", f"shin_{tag}.{side}", segs=5)
    for k, (y, z) in enumerate([(0.14, 0.9), (-0.04, 0.95)]):                     # a bone jutting from its back
        C.cone(f"Bone{k}", (0.06 * (k * 2 - 1), y, z - 0.04), (0.12 * (k * 2 - 1), y + 0.06, z + 0.1), 0.025, "bone",
               "chest" if y < 0 else "hips", segs=5)
