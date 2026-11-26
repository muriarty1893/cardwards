"""Bastion, the Last Wall (Sunny Dunes, 6, legend): an old tortoise warrior. Sculpted: a massive, stooped
body on thick elephantine legs, a great domed shell of sandstone scutes grown into a fortress with
battlements, a plated plastron, heavy scaled arms, a wrinkled beaked face under a crested helm, a tower
shield carved with a sun and a short heavy sword."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(stone="d8b878", stone2="b89858", metal="a8a8b0", metal2="6a6a74", gold="ffcf3a", eye="ffd23a",
              dark="1a140a", sun="ff8a1a", plume="b8202a", skin="6a8a4a")
    C.plan, C.attack = "biped", "slam"
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.06, 0.72), (0, 0.0, 0.98), "root")
    C.bone("chest", (0, 0.0, 0.98), (0, -0.12, 1.24), "hips")
    C.bone("neck", (0, -0.12, 1.24), (0, -0.28, 1.36), "chest")
    C.bone("head", (0, -0.28, 1.36), (0, -0.3, 1.6), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        sh, el, hd = (0.42 * sx, -0.08, 1.18), (0.56 * sx, -0.1, 0.9), (0.58 * sx, -0.26, 0.74)
        C.bone(f"arm.{side}", sh, el, "chest")
        C.bone(f"forearm.{side}", el, hd, f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
        C.anch["hd" + side] = hd
        C.bone(f"leg.{side}", (0.22 * sx, 0.04, 0.68), (0.25 * sx, -0.04, 0.36), "hips")
        C.bone(f"shin.{side}", (0.25 * sx, -0.04, 0.36), (0.25 * sx, -0.02, 0.04), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.03)
    cl.add((0, 0.24, 1.0), (0.5, 0.34, 0.5), rot=(-12, 0, 0), group="shell")          # domed shell
    cl.add((0, 0.3, 0.6), (0.44, 0.26, 0.2), group="shell")                              # shell skirt
    cl.add((0, -0.14, 0.92), (0.33, 0.14, 0.38), rot=(-8, 0, 0), group="plastron")      # plastron
    cl.add((0, 0.0, 0.76), (0.32, 0.22, 0.18), group="skin")                             # pelvis
    cl.mirror((0.36, -0.06, 1.18), (0.16, 0.16, 0.14), group="skin")                     # shoulders
    for sx in (-1, 1):
        cl.chain([(0.42 * sx, -0.08, 1.18), (0.56 * sx, -0.1, 0.9)], [0.13, 0.11], group="skin")
        cl.chain([(0.56 * sx, -0.1, 0.9), (0.58 * sx, -0.24, 0.76)], [0.11, 0.1], group="skin")
        cl.add((0.59 * sx, -0.28, 0.72), (0.1, 0.1, 0.09), group="skin")
        cl.chain([(0.22 * sx, 0.04, 0.68), (0.25 * sx, -0.04, 0.36), (0.25 * sx, -0.02, 0.08)], [0.17, 0.15, 0.15],
                 group="skin")
        cl.add((0.25 * sx, -0.06, 0.06), (0.17, 0.19, 0.07), group="skin")              # elephant foot
    # neck folds and the wrinkled beaked head, low and thrust forward
    cl.chain([(0, -0.1, 1.2), (0, -0.24, 1.32), (0, -0.3, 1.4)], [0.15, 0.13, 0.12], group="skin")
    for k in range(3):
        cl.add((0, -0.14 - 0.05 * k, 1.24 + 0.05 * k), (0.15 - 0.01 * k, 0.04, 0.12), rot=(-40, 0, 0), group="skin")
    cl.add((0, -0.34, 1.44), (0.14, 0.15, 0.12), group="skin")
    cl.add((0, -0.48, 1.4), (0.09, 0.1, 0.08), rot=(25, 0, 0), group="beak")
    cl.add((0, -0.54, 1.36), (0.05, 0.06, 0.05), group="beak")
    cl.add((0, -0.52, 1.37), (0.08, 0.08, 0.008), group="beak", neg=True)              # mouth line
    cl.mirror((0.085, -0.44, 1.46), (0.035, 0.03, 0.026), group="skin", neg=True)
    body = cl.build({"shell": "7a5a3a", "plastron": "d8b878", "skin": "6a8a4a", "beak": "d8c8a0"}, voxel=0.018,
                    budget=11000, texture={"type": 'VORONOI', "scale": 0.03, "strength": 0.01})
    # shell scutes like masonry, deep seams; plastron plates; mottled scaly skin
    recolor(body, lambda p, n: cracks(p, 0.2, 0.13, seed=2) * (1.0 if p.y > 0.05 and p.z > 0.5 else 0.0), "2a1c10")
    recolor(body, lambda p, n: (1.0 if p.y < -0.18 and 0.6 < p.z < 1.25 and abs((p.z - 0.6) % 0.17) < 0.02 else 0.0),
            "8a6a3a")

    # ---- crisp details
    for k in range(5):                                                                    # battlements
        x = -0.32 + 0.16 * k
        C.box(f"Merlon{k}", (x, 0.38, 1.38 - 0.04 * abs(k - 2)), (0.11, 0.18, 0.14), "stone", "chest", bevel=0.2)
    C.box("Rampart", (0, 0.36, 1.3), (0.66, 0.24, 0.06), "stone2", "chest", bevel=0.2)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.085 * mx, -0.46, 1.46), (0.022, 0.01, 0.014), "eye", "head")
        C.ellipsoid(f"Pauldron{mx}", (0.4 * mx, -0.06, 1.26), (0.2, 0.2, 0.12), "stone", f"arm.{'L' if mx < 0 else 'R'}",
                    rot=(0, -25 * mx, 0))
        C.ellipsoid(f"Pauldron2{mx}", (0.46 * mx, -0.06, 1.18), (0.17, 0.18, 0.08), "stone2",
                    f"arm.{'L' if mx < 0 else 'R'}", rot=(0, -35 * mx, 0))
        C.cone(f"Spur{mx}", (0.48 * mx, -0.06, 1.3), (0.62 * mx, -0.04, 1.42), 0.04, "metal", f"arm.{'L' if mx < 0 else 'R'}",
               segs=5)
    C.ellipsoid("Helm", (0, -0.32, 1.53), (0.16, 0.17, 0.11), "metal", "head")
    C.box("Visor", (0, -0.47, 1.52), (0.24, 0.05, 0.045), "metal2", "head", bevel=0.4)
    C.tube("Crest", [V((0, -0.42, 1.62)), V((0, -0.28, 1.72)), V((0, -0.08, 1.64))], [0.05, 0.065, 0.02], "plume", "head")
    for side, sx in (("L", -1), ("R", 1)):
        C.ellipsoid(f"Greave{side}", (0.25 * sx, -0.08, 0.3), (0.17, 0.13, 0.17), "metal", f"shin.{side}")
        for k in (-1, 0, 1):
            C.cone(f"Toe{side}{k}", (0.25 * sx + 0.09 * k, -0.2, 0.05), (0.25 * sx + 0.1 * k, -0.25, 0.02), 0.03, "beak"
                   if "beak" in C.mats else "stone", f"shin.{side}", segs=5)
    hl = V(C.anch["hdL"])
    sc = hl + V((-0.08, -0.2, 0.2))
    props.shield(C, tuple(sc), 0.46, "stone", "gold", "forearm.L", facing=(0, -1, 0), kite=True)
    C.ellipsoid("ShieldSun", tuple(sc + V((0, -0.07, 0.1))), (0.12, 0.03, 0.12), "sun", "forearm.L")
    for k in range(8):
        a = 2 * math.pi * k / 8
        C.cone(f"Ray{k}", tuple(sc + V((math.cos(a) * 0.13, -0.07, 0.1 + math.sin(a) * 0.13))),
               tuple(sc + V((math.cos(a) * 0.25, -0.07, 0.1 + math.sin(a) * 0.25))), 0.03, "gold", "forearm.L", segs=4)
    props.blade(C, C.anch["hdR"], "metal", "gold", "forearm.R", length=0.6, width=0.1, direction=(0, -0.3, -1),
                guard=0.22)
