"""Inferno Drake (Ember Flats, 7): a black-scaled wyvern that stands on two legs and its wing-claws.
Sculpted: a hunched, powerful body on thick digitigrade legs, great wings folded forward as forelimbs
ending in hooked claws, a long serpentine neck, a narrow armoured skull with jagged swept horns, a throat
and belly glowing with the fire it is about to breathe, spined back and a barbed tail."""
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(scale="1e1618", scale2="3a2a2a", belly="c84a14", glow="ffd03a", horn="c8b8a0", wing="5a1a10",
              wingbone="140e0e", eye="ffcf3a", fire="ff5a14", tooth="f0e6d0", pupil="1a0404")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.3, 0.82), (0, 0.0, 0.92), "root")
    C.bone("chest", (0, 0.0, 0.92), (0, -0.28, 1.08), "hips")
    C.bone("neck", (0, -0.28, 1.08), (0, -0.4, 1.34), "chest")
    C.bone("neck2", (0, -0.4, 1.34), (0, -0.5, 1.52), "neck")
    C.bone("head", (0, -0.5, 1.52), (0, -0.86, 1.5), "neck2")
    C.bone("jaw", (0, -0.56, 1.46), (0, -0.84, 1.4), "head")
    C.spine, C.neck, C.head, C.jaw = ["hips", "chest"], ["neck", "neck2"], "head", "jaw"
    tail = [(0, 0.34, 0.82), (0, 0.66, 0.66), (0, 0.94, 0.56), (0.1, 1.16, 0.6)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.2 * sx, 0.3, 0.78), (0.24 * sx, 0.1, 0.44), "hips")
        C.bone(f"shin.{side}", (0.24 * sx, 0.1, 0.44), (0.24 * sx, 0.34, 0.06), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    skulpt.wing_bones(C, (0.22, -0.18, 1.08), (0.5, -0.16, 0.66), (0.56, -0.34, 0.06))
    cl = Clay(C, "Body", res=0.024)
    cl.add((0, -0.12, 0.98), (0.27, 0.32, 0.27), rot=(-20, 0, 0), group="scale")
    cl.add((0, 0.26, 0.86), (0.24, 0.24, 0.22), group="scale")
    cl.add((0, -0.2, 0.86), (0.16, 0.24, 0.1), rot=(-20, 0, 0), group="scale2")
    cl.chain([(0, -0.28, 1.1), (0, -0.4, 1.34), (0, -0.5, 1.52)], [0.14, 0.11, 0.1], group="scale")
    cl.chain([(0, -0.32, 1.04), (0, -0.44, 1.3), (0, -0.54, 1.44)], [0.09, 0.07, 0.06], group="belly")   # glowing throat
    cl.add((0, -0.58, 1.55), (0.12, 0.14, 0.1), group="scale")
    cl.chain([(0, -0.66, 1.54), (0, -0.84, 1.5)], [(0.09, 0.08, 0.07), (0.06, 0.05, 0.05)], group="scale")
    cl.chain([(0, -0.6, 1.46), (0, -0.84, 1.42)], [(0.08, 0.07, 0.04), (0.05, 0.04, 0.03)], group="scale2")
    cl.mirror((0.075, -0.68, 1.58), (0.05, 0.08, 0.03), rot=(0, 0, -12), group="scale2")
    cl.mirror((0.075, -0.7, 1.555), (0.025, 0.025, 0.02), group="scale", neg=True)
    for sx in (-1, 1):
        cl.add((0.2 * sx, 0.24, 0.66), (0.14, 0.2, 0.22), rot=(-25, 0, 0), group="scale")
        cl.chain([(0.24 * sx, 0.1, 0.44), (0.24 * sx, 0.28, 0.2), (0.24 * sx, 0.34, 0.08)], [0.08, 0.06, 0.05],
                 group="scale")
        cl.add((0.24 * sx, 0.24, 0.04), (0.08, 0.14, 0.04), group="scale")
        cl.chain([(0.22 * sx, -0.18, 1.08), (0.5 * sx, -0.16, 0.66), (0.56 * sx, -0.34, 0.08)], [0.08, 0.06, 0.045],
                 group="scale2")
    cl.chain(tail, [0.16, 0.1, 0.05, 0.02], group="scale")
    body = cl.build({"scale": "scale", "scale2": "scale2", "belly": "belly"}, voxel=0.013, budget=11000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.025, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.7, n.y + n.z) * (1.0 if -0.6 < p.y < -0.3 and p.z > 1.15 else 0.0)
            * 0.8, "glow")
    skulpt.eyes(C, [(0.075, -0.715, 1.56)], 0.022, "eye", "pupil", slit=True)
    for mx in (-1, 1):
        b = V((0.07 * mx, -0.58, 1.62))
        C.tube(f"Horn{mx}", [b, b + V((0.08 * mx, 0.14, 0.08)), b + V((0.12 * mx, 0.32, 0.04))], [0.04, 0.025, 0.003],
               "horn", "head")
        C.tube(f"Horn2{mx}", [b + V((0.03 * mx, 0.04, -0.06)), b + V((0.12 * mx, 0.14, -0.08))], [0.022, 0.003], "horn",
               "head")
        for k in range(3):
            C.cone(f"Claw{mx}{k}", (0.56 * mx + 0.03 * (k - 1), -0.34, 0.08), (0.56 * mx + 0.04 * (k - 1), -0.42, 0.0), 0.02,
                   "horn", f"wing2.{'L' if mx < 0 else 'R'}", segs=5)
        side = "L" if mx < 0 else "R"
        sh, el, wr = V((0.22 * mx, -0.18, 1.08)), V((0.5 * mx, -0.16, 0.66)), V((0.56 * mx, -0.34, 0.08))
        fingers = [el + V((0.3 * mx, 0.3, 0.7)), el + V((0.36 * mx, 0.46, 0.3)), el + V((0.24 * mx, 0.5, -0.1))]
        for k, ft in enumerate(fingers):
            C.tube(f"Finger{side}{k}", [el, (el + ft) / 2, ft], [0.03, 0.022, 0.006], "wingbone", f"wing2.{side}")
        outline = [tuple(sh), tuple(el)] + [tuple(f) for f in fingers] + [tuple(V((0.12 * mx, 0.3, 0.9)))]
        if mx < 0:
            outline = outline[::-1]
        C.membrane(f"Wing{side}", outline, "wing", None, thick=0.02, allowed=[f"wing.{side}", f"wing2.{side}"])
    for k in range(9):
        y = -0.5 + 0.16 * k
        z = 1.62 - 0.1 * k if k < 4 else 1.14 - 0.08 * (k - 3)
        C.cone(f"Spine{k}", (0, y, z - 0.02), (0, y + 0.08, z + 0.1), 0.03, "horn",
               "neck2" if y < -0.45 else "neck" if y < -0.28 else "chest" if y < 0.05 else "hips" if y < 0.45 else "tail1",
               segs=5)
    for mx in (-1, 1):
        C.cone(f"Barb{mx}", (0.1, 1.16, 0.6), (0.1 + 0.1 * mx, 1.28, 0.62), 0.03, "horn", "tail3", segs=5)
    for k in range(5):
        x = -0.04 + 0.02 * k
        C.cone(f"Tooth{k}", (x, -0.8, 1.47), (x, -0.8, 1.43), 0.008, "tooth", "head", segs=4)
    props.flame(C, (0, -0.86, 1.44), 0.08, "jaw", "fire", "glow", n=3, lean=(0, -0.6, 0), name="Breath")
