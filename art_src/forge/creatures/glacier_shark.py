"""Glacier Shark (Frost Peaks, 5): a great shark carved from blue ice. Sculpted: a heavy torpedo body with
a deep, blunt snout, jagged glacier fins, a crest of frozen spikes down its back, a cavernous gaping jaw
lined with icicle teeth, gill slits, cold white eyes and a pale belly, the ice cracked with white fractures."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(ice="3a7ab8", belly="d8f0ff", crystal="aef0ff", dark="0a1a2a", tooth="ffffff", eye="f0ffff", gum="1a3a5a")
    C.plan, C.attack, C.hover = "swimmer", "bite", 0.5
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.6), (0, -0.2, 0.62), "root")
    C.bone("chest", (0, -0.2, 0.62), (0, -0.45, 0.62), "hips")
    C.bone("head", (0, -0.45, 0.62), (0, -0.85, 0.6), "chest")
    C.bone("jaw", (0, -0.42, 0.5), (0, -0.78, 0.42), "head")
    tail = [(0, 0.06, 0.6), (0, 0.3, 0.62), (0, 0.5, 0.66), (0, 0.64, 0.7)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    C.spine, C.head, C.jaw = ["hips", "chest"], "head", "jaw"
    cl = Clay(C, "Body", res=0.024)
    cl.add((0, -0.26, 0.62), (0.27, 0.34, 0.26), group="ice")
    cl.add((0, -0.66, 0.6), (0.2, 0.2, 0.17), group="ice")                         # blunt head
    cl.add((0, -0.26, 0.46), (0.22, 0.34, 0.1), group="belly")
    cl.chain(tail, [0.2, 0.13, 0.07, 0.04], group="ice")
    cl.add((0, -0.62, 0.48), (0.18, 0.18, 0.06), group="dark", neg=True)            # gaping mouth
    cl.add((0, -0.58, 0.42), (0.15, 0.18, 0.05), group="belly")                     # lower jaw
    cl.mirror((0.15, -0.72, 0.64), (0.03, 0.03, 0.025), group="ice", neg=True)
    for k in range(4):                                                              # gill slits
        cl.mirror((0.24, -0.4 + 0.05 * k, 0.6), (0.02, 0.008, 0.08), group="ice", neg=True)
    for sx in (-1, 1):                                                              # pectoral fins
        cl.chain([(0.2 * sx, -0.3, 0.48), (0.42 * sx, -0.16, 0.32), (0.52 * sx, -0.04, 0.24)],
                 [(0.06, 0.12, 0.03), (0.04, 0.08, 0.025), 0.01], group="ice")
        cl.chain([(0, 0.64, 0.7), (0.0, 0.74, 0.94 if sx > 0 else 0.5), (0.0, 0.8, 1.04 if sx > 0 else 0.42)],
                 [(0.04, 0.08, 0.08), (0.03, 0.06, 0.05), 0.01], group="ice")         # tail lobes
    cl.chain([(0, -0.24, 0.84), (0, -0.12, 1.08), (0, 0.0, 1.14)], [(0.04, 0.16, 0.06), (0.03, 0.09, 0.05), 0.01],
             group="ice")                                                           # dorsal fin
    body = cl.build({"ice": "ice", "belly": "belly", "dark": "gum"}, voxel=0.014, budget=10000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.05, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.7, n.z) * 0.9, "belly")
    recolor(body, lambda p, n: cracks(p, 0.18, 0.04, seed=41) * 0.7, "crystal")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.15 * mx, -0.725, 0.64), (0.025, 0.02, 0.02), "eye", "head")
    for k in range(11):
        a = math.pi * (0.06 + 0.88 * k / 10)
        x, y = math.cos(a) * 0.17, -0.5 - math.sin(a) * 0.28
        C.cone(f"ToothU{k}", (x, y, 0.55), (x * 0.95, y - 0.01, 0.47), 0.018, "tooth", "head", segs=4)
        C.cone(f"ToothL{k}", (x * 0.9, y + 0.03, 0.42), (x * 0.88, y + 0.02, 0.49), 0.016, "tooth", "jaw", segs=4)
    for k in range(6):
        y = -0.5 + 0.18 * k
        C.cone(f"Spike{k}", (0.05 * (k % 2 * 2 - 1), y, 0.84 - 0.03 * k), (0.06 * (k % 2 * 2 - 1), y + 0.06, 0.98 - 0.04 * k),
               0.035, "crystal", "chest" if y < -0.2 else "hips" if y < 0.1 else "tail1", segs=4)
