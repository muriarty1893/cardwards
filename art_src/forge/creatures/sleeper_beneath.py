"""The Sleeper Beneath (Dark Moon, 10, legend): an abyssal leviathan risen from the deep. Sculpted: a thick
manta body whose great wing-discs curl upward at the tips, two curling cephalic horns, a carved maw ringed
with needle teeth over a beard of tentacles, a cluster of half-lidded glowing eyes, bone spines down the
back, bioluminescent bands, and a long whip tail."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(eye="d8ff8a", pupil="05080a", lid="0c0c1e", socket="040408", tooth="e8e0d0", bone="c8c0a8",
              tent="3a1a5a", sucker="b88aff", maw="1a0410")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.35
    # ---- skeleton
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.3, 0.55), (0, -0.05, 0.56), "root")
    C.bone("chest", (0, -0.05, 0.56), (0, -0.45, 0.56), "hips")
    C.bone("head", (0, -0.45, 0.56), (0, -0.95, 0.56), "chest")
    C.bone("jaw", (0, -0.6, 0.44), (0, -0.92, 0.42), "head")
    C.spine, C.head, C.jaw = ["hips", "chest"], "head", "jaw"
    tail = [(0, 0.3, 0.55), (0, 0.62, 0.58), (0, 0.9, 0.68), (0, 1.1, 0.86), (0, 1.18, 1.08)]
    for i in range(4):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"wing.{side}", (0.3 * sx, -0.15, 0.58), (0.68 * sx, -0.05, 0.64), "chest")
        C.bone(f"wing2.{side}", (0.68 * sx, -0.05, 0.64), (1.0 * sx, 0.12, 0.82), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.028)
    cl.add((0, -0.68, 0.56), (0.3, 0.26, 0.21), group="hide")                    # head
    cl.add((0, -0.3, 0.56), (0.4, 0.4, 0.28), group="hide")                      # chest
    cl.add((0, 0.08, 0.56), (0.36, 0.38, 0.25), group="hide")                    # mid body
    cl.add((0, 0.4, 0.57), (0.22, 0.28, 0.18), group="hide")                     # hind body
    cl.add((0, -0.3, 0.42), (0.34, 0.5, 0.12), group="belly")                    # pale underside
    cl.chain(tail, [0.17, 0.1, 0.06, 0.035, 0.015], group="hide")                # whip tail
    for sx in (-1, 1):
        # wing discs fanning out, curling up at the tips
        cl.add((0.45 * sx, -0.2, 0.58), (0.3, 0.38, 0.1), rot=(0, 6 * sx, 0), group="hide")
        cl.add((0.74 * sx, -0.06, 0.63), (0.24, 0.28, 0.07), rot=(0, 14 * sx, 0), group="hide")
        cl.add((0.88 * sx, 0.04, 0.7), (0.16, 0.2, 0.06), rot=(0, 28 * sx, 0), group="fin")
        cl.add((0.62 * sx, 0.22, 0.6), (0.14, 0.12, 0.05), group="hide", neg=True)          # scalloped trailing edge
        cl.add((0.86 * sx, 0.3, 0.68), (0.1, 0.1, 0.06), group="hide", neg=True)
        # curling cephalic horns
        cl.chain([(0.2 * sx, -0.78, 0.56), (0.3 * sx, -0.98, 0.6), (0.27 * sx, -1.1, 0.74), (0.17 * sx, -1.08, 0.86)],
                 [0.085, 0.06, 0.04, 0.02], group="fin")
        # eye sockets for the cluster of eyes
    for (x, y, z, r) in [(0.0, -0.78, 0.74, 0.07), (0.13, -0.76, 0.71, 0.055), (-0.13, -0.76, 0.71, 0.055),
                         (0.22, -0.7, 0.66, 0.045), (-0.22, -0.7, 0.66, 0.045), (0.07, -0.68, 0.8, 0.04),
                         (-0.07, -0.68, 0.8, 0.04)]:
        cl.add((x, y, z), (r, r, r), group="hide", neg=True)
    cl.add((0, -0.9, 0.46), (0.2, 0.12, 0.07), group="hide", neg=True)          # the maw
    body = cl.build({"hide": "1a1838", "belly": "4a4a7a", "fin": "2a2050"}, voxel=0.016, budget=11000,
                    texture={"type": 'VORONOI', "scale": 0.05, "strength": 0.01})
    # bioluminescent bands across the back and along the wings, pale underside
    recolor(body, lambda p, n: smoothstep(-0.2, -0.7, n.z) * 0.8, "5a5a8a")
    recolor(body, lambda p, n: (smoothstep(0.72, 0.98, math.sin(p.y * 14 + abs(p.x) * 4)) * smoothstep(0.3, 0.8, n.z)
                                * (1.0 if abs(p.x) < 0.95 and p.y > -0.55 else 0.0)), "4affd0")
    recolor(body, lambda p, n: smoothstep(0.85, 1.0, abs(p.x)) * 0.9, "7affd8")

    # ---- crisp details: eyes, teeth, tentacles, spines
    for k, (x, y, z, r) in enumerate([(0.0, -0.78, 0.74, 0.07), (0.13, -0.76, 0.71, 0.055), (-0.13, -0.76, 0.71, 0.055),
                                      (0.22, -0.7, 0.66, 0.045), (-0.22, -0.7, 0.66, 0.045), (0.07, -0.68, 0.8, 0.04),
                                      (-0.07, -0.68, 0.8, 0.04)]):
        C.ellipsoid(f"Eye{k}", (x, y + r * 0.15, z), (r * 0.85, r * 0.85, r * 0.85), "eye", "head")
        C.ellipsoid(f"Pupil{k}", (x * 1.05, y - r * 0.6, z), (r * 0.18, r * 0.2, r * 0.6), "pupil", "head")
        if k % 2:
            C.ellipsoid(f"Lid{k}", (x, y - r * 0.05, z + r * 0.45), (r * 0.95, r * 0.95, r * 0.55), "lid", "head")
    C.ellipsoid("MawDark", (0, -0.86, 0.46), (0.17, 0.08, 0.05), "maw", "head")
    for k in range(10):
        a = math.pi * (0.1 + 0.8 * k / 9)
        x, y = math.cos(a) * 0.17, -0.88 - math.sin(a) * 0.05
        C.cone(f"ToothU{k}", (x, y, 0.5), (x * 0.9, y - 0.01, 0.43), 0.014, "tooth", "head", segs=4)
        C.cone(f"ToothL{k}", (x * 0.92, y + 0.02, 0.4), (x * 0.85, y + 0.01, 0.46), 0.012, "tooth", "jaw", segs=4)
    for k in range(9):
        a = math.pi * (0.12 + 0.76 * k / 8)
        top = V((math.cos(a) * 0.22, -0.78 - math.sin(a) * 0.06, 0.4))
        sway = 0.06 * (1 if k % 2 else -1)
        pts = [top, top + V((math.cos(a) * 0.05 + sway, -0.06, -0.18)), top + V((math.cos(a) * 0.08, 0.02, -0.34)),
               top + V((math.cos(a) * 0.04 - sway, -0.08, -0.46))]
        C.tube(f"Tentacle{k}", pts, [0.04, 0.032, 0.02, 0.005], "tent", None, allowed=["head", "jaw"])
        C.ellipsoid(f"Sucker{k}", tuple(pts[1] + V((0, -0.025, 0))), (0.012, 0.01, 0.012), "sucker", None,
                    allowed=["head", "jaw"])
    for k, (y, z, h) in enumerate([(-0.55, 0.78, 0.18), (-0.38, 0.84, 0.26), (-0.2, 0.84, 0.32), (0.0, 0.82, 0.3),
                                   (0.18, 0.78, 0.26), (0.36, 0.72, 0.2), (0.55, 0.68, 0.14)]):
        bone = "head" if y < -0.45 else "chest" if y < -0.05 else "hips"
        C.tube(f"Spine{k}", [V((0, y, z - 0.04)), V((0, y + h * 0.3, z + h * 0.65)), V((0, y + h * 0.75, z + h))],
               [h * 0.22, h * 0.12, 0.003], "bone", bone)
