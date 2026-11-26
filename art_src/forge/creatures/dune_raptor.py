"""Dune Raptor (Sunny Dunes, 3): a sand-striped desert raptor. Sculpted: a lean, forward-leaning predator
balanced over strong digitigrade legs, a long stiff tail held level, a narrow toothy snout, grasping
clawed arms, a crest of quills down its neck, dark sand stripes over a pale belly and the killing
sickle-claw raised on each foot."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(hide="c8904a", stripe="6a3a1a", belly="f0d8a0", quill="b8301a", eye="ffd23a", pupil="0a0604", claw="1a1008",
              tooth="fff8e8")
    C.attack = "bite"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.72), (0, -0.14, 0.78), "root")
    C.bone("chest", (0, -0.14, 0.78), (0, -0.34, 0.86), "hips")
    C.bone("neck", (0, -0.34, 0.86), (0, -0.46, 1.06), "chest")
    C.bone("head", (0, -0.46, 1.06), (0, -0.74, 1.04), "neck")
    C.bone("jaw", (0, -0.5, 1.0), (0, -0.72, 0.98), "head")
    C.spine, C.neck, C.head, C.jaw = ["hips", "chest"], ["neck"], "head", "jaw"
    tail = [(0, 0.12, 0.74), (0, 0.42, 0.76), (0, 0.72, 0.78), (0, 0.96, 0.8)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.13 * sx, 0.1, 0.68), (0.15 * sx, -0.06, 0.4), "hips")
        C.bone(f"shin.{side}", (0.15 * sx, -0.06, 0.4), (0.14 * sx, 0.1, 0.04), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
        C.bone(f"arm.{side}", (0.12 * sx, -0.32, 0.8), (0.16 * sx, -0.4, 0.66), "chest")
        C.bone(f"forearm.{side}", (0.16 * sx, -0.4, 0.66), (0.14 * sx, -0.5, 0.6), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, -0.14, 0.78), (0.14, 0.26, 0.15), rot=(-10, 0, 0), group="hide")
    cl.add((0, -0.2, 0.7), (0.1, 0.2, 0.08), group="belly")
    cl.chain([V((0, -0.32, 0.84)), V((0, -0.42, 0.98)), V((0, -0.48, 1.06))], [0.08, 0.065, 0.06], group="hide")
    cl.add((0, -0.52, 1.07), (0.07, 0.09, 0.07), group="hide")
    cl.chain([V((0, -0.56, 1.06)), V((0, -0.74, 1.03))], [(0.06, 0.06, 0.05), (0.035, 0.03, 0.03)], group="hide")
    cl.chain([V((0, -0.54, 1.0)), V((0, -0.72, 0.99))], [(0.05, 0.05, 0.025), (0.03, 0.03, 0.015)], group="belly")
    cl.chain(tail, [0.11, 0.07, 0.04, 0.015], group="hide")
    for sx in (-1, 1):
        cl.add((0.12 * sx, 0.06, 0.62), (0.09, 0.14, 0.14), rot=(-20, 0, 0), group="hide")
        cl.chain([(0.15 * sx, -0.06, 0.4), (0.14 * sx, 0.06, 0.2), (0.14 * sx, 0.1, 0.06)], [0.05, 0.035, 0.03], group="hide")
        cl.add((0.14 * sx, 0.04, 0.03), (0.04, 0.08, 0.025), group="hide")
        cl.chain([(0.12 * sx, -0.32, 0.8), (0.16 * sx, -0.4, 0.66), (0.14 * sx, -0.5, 0.6)], [0.035, 0.028, 0.022], group="hide")
    body = cl.build({"hide": "hide", "belly": "belly"}, voxel=0.008, budget=7000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.015, "strength": 0.005})
    recolor(body, lambda p, n: smoothstep(0.55, 0.85, math.sin(p.y * 30)) * smoothstep(0.1, 0.6, n.z) * 0.9, "stripe")
    recolor(body, lambda p, n: smoothstep(-0.2, -0.7, n.z) * 0.7, "belly")
    skulpt.eyes(C, [(0.05, -0.58, 1.1)], 0.018, "eye", "pupil", slit=True)
    for k in range(6):
        x = 0.025 * (k % 2 * 2 - 1)
        y = -0.7 + 0.03 * k
        C.cone(f"Tooth{k}", (x, y, 1.01), (x, y, 0.985), 0.006, "tooth", "head", segs=4)
    for k in range(7):
        b = V((0, -0.46 + 0.08 * k, 1.08 - 0.04 * k))
        C.cone(f"Quill{k}", tuple(b), tuple(b + V((0, 0.12, 0.08))), 0.02, "quill", "neck" if k < 3 else "chest", segs=4)
    for mx in (-1, 1):
        side = "L" if mx < 0 else "R"
        C.tube(f"Sickle{side}", [V((0.14 * mx, 0.02, 0.06)), V((0.14 * mx, -0.04, 0.14)), V((0.14 * mx, -0.1, 0.1))],
               [0.018, 0.012, 0.003], "claw", f"shin.{side}")
        for k in (-1, 1):
            C.cone(f"Toe{side}{k}", (0.14 * mx + 0.03 * k, 0.0, 0.03), (0.14 * mx + 0.04 * k, -0.08, 0.0), 0.012, "claw",
                   f"shin.{side}", segs=4)
        for k in range(3):
            C.cone(f"Hand{side}{k}", (0.14 * mx, -0.5, 0.6), (0.14 * mx + 0.02 * (k - 1), -0.56, 0.54), 0.008, "claw",
                   f"forearm.{side}", segs=4)
