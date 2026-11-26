"""Alpaking, Thief King (Sunny Dunes, 7, legend): a towering alpaca king of thieves. Sculpted: a big body in
a magnificent shaggy fleece, a long neck held haughtily high with a ruff of wool, a sly narrow face behind a
bandit mask, banana ears with gold hoops, a crooked crown over his topknot and a velvet cape lined with
stolen coins draped over his back."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(face="c8a888", mask="1a1020", eye="ffd23a", cape="5a0a3a", lining="ffcf3a", gold="ffd23a",
              gem="3affb0", hoof="3a2a20", dark="1a1008")
    C.plan, C.attack = "quad", "ram"
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.36, 1.0), (0, 0.0, 1.02), "root")
    C.bone("chest", (0, 0.0, 1.02), (0, -0.3, 1.06), "hips")
    C.bone("neck", (0, -0.32, 1.12), (0, -0.42, 1.48), "chest")
    C.bone("neck2", (0, -0.42, 1.48), (0, -0.46, 1.8), "neck")
    C.bone("head", (0, -0.46, 1.8), (0, -0.76, 1.8), "neck2")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck", "neck2"], "head"
    C.bone("tail1", (0, 0.56, 1.06), (0, 0.66, 0.92), "hips")
    C.tail = ["tail1"]
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        legs[side] = dict(f=[(0.2 * sx, -0.3, 0.9), (0.2 * sx, -0.32, 0.46), (0.2 * sx, -0.34, 0.04)],
                          b=[(0.21 * sx, 0.38, 0.9), (0.21 * sx, 0.42, 0.46), (0.21 * sx, 0.38, 0.04)])
        f, b = legs[side]["f"], legs[side]["b"]
        C.bone(f"leg_f.{side}", f[0], f[1], "chest")
        C.bone(f"shin_f.{side}", f[1], f[2], f"leg_f.{side}")
        C.bone(f"leg_b.{side}", b[0], b[1], "hips")
        C.bone(f"shin_b.{side}", b[1], b[2], f"leg_b.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    # ---- sculpted body: a shaggy fleece built of many wool lumps
    cl = Clay(C, "Body", res=0.03)
    cl.add((0, 0.04, 1.02), (0.34, 0.5, 0.3), group="wool")
    for k in range(14):                                                        # fleece clumps over the body
        a = 2 * math.pi * k / 7
        y = -0.32 + 0.64 * (k // 7) + 0.1 * math.sin(k * 1.7)
        cl.add((math.cos(a) * 0.3, y + 0.1 * (k % 2), 1.02 + math.sin(a) * 0.26), (0.14, 0.17, 0.14), group="wool")
    cl.add((0, 0.54, 1.06), (0.12, 0.12, 0.12), group="wool")                  # tail puff
    # long neck with a great ruff
    cl.chain([(0, -0.32, 1.12), (0, -0.42, 1.48), (0, -0.46, 1.76)], [0.17, 0.13, 0.11], group="wool")
    for k in range(6):
        a = 2 * math.pi * k / 6
        cl.add((math.cos(a) * 0.14, -0.36 + math.sin(a) * 0.12, 1.26 + 0.05 * (k % 2)), (0.09, 0.09, 0.12),
               group="wool")
    # head: wool topknot, narrow face, soft muzzle, banana-ear roots, eye sockets under the mask
    cl.add((0, -0.5, 1.84), (0.12, 0.13, 0.11), group="face")
    cl.add((0, -0.48, 1.94), (0.12, 0.12, 0.09), group="wool")
    cl.chain([(0, -0.56, 1.82), (0, -0.68, 1.78), (0, -0.76, 1.74)], [(0.085, 0.08, 0.085), (0.07, 0.07, 0.07),
                                                                     (0.065, 0.06, 0.06)], group="face")
    cl.add((0, -0.78, 1.71), (0.055, 0.04, 0.045), group="muzzle")
    cl.add((0, -0.8, 1.69), (0.04, 0.03, 0.005), group="muzzle", neg=True)
    for sx in (-1, 1):
        f, b = legs["L" if sx < 0 else "R"]["f"], legs["L" if sx < 0 else "R"]["b"]
        for leg in (f, b):
            cl.chain(leg, [0.13, 0.1, 0.06], group="wool")
            cl.add(leg[1], (0.12, 0.12, 0.13), group="wool")                    # fluffy knee
            cl.add((leg[2][0], leg[2][1], 0.12), (0.07, 0.07, 0.08), group="leg")
    body = cl.build({"wool": "f0e6d4", "face": "c8a888", "muzzle": "a88868", "leg": "c8a888"}, voxel=0.017,
                    budget=11000, texture={"type": 'CLOUDS', "scale": 0.045, "strength": 0.035})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.8, n.z) * 0.5, "c8b498")

    # ---- crisp details
    C.box("Mask", (0, -0.6, 1.86), (0.25, 0.06, 0.065), "mask", "head", bevel=0.45)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.07 * mx, -0.635, 1.865), (0.026, 0.01, 0.017), "eye", "head")
        C.tube(f"Ear{mx}", [V((0.08 * mx, -0.48, 1.96)), V((0.13 * mx, -0.5, 2.08)), V((0.12 * mx, -0.56, 2.18))],
               [0.035, 0.035, 0.008], "face", "head")
        C.lathe(f"Hoop{mx}", [(0.035, 0.0), (0.04, 0.005), (0.035, 0.01)], "gold", "head", segs=12)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0.12 * mx, -0.5, 2.0)) @
                                      __import__("mathutils").Matrix.Rotation(1.57, 4, 'Y'))
        C.ellipsoid(f"Nostril{mx}", (0.022 * mx, -0.82, 1.73), (0.01, 0.006, 0.008), "dark", "head")
    C.box("Smirk", (0.01, -0.81, 1.685), (0.05, 0.012, 0.008), "dark", "head", rot=(0, -12, 0), bevel=0.4)
    for k in (-1, 1):
        C.box(f"Tooth{k}", (0.012 * k, -0.815, 1.68), (0.014, 0.008, 0.016), "lining", "head", bevel=0.2)
    props.crown(C, (0.02, -0.48, 2.0), 0.1, "gold", "head", points=5, height=0.11, m_gem="gem", tilt=-15)
    # velvet cape draped over the back, coin-lined hem, a gem clasp at the neck
    cape = Clay(C, "Cape", res=0.018)
    for k in range(11):                                                        # a sheet draped over the back
        a = math.radians(-80 + 16 * k)
        cape.add((math.sin(a) * 0.46, 0.04, 1.02 + math.cos(a) * 0.4), (0.1, 0.56, 0.03), rot=(0, math.degrees(a), 0),
                 group="cape")
    for mx in (-1, 1):                                                         # heavy folds at the sides
        for k in range(5):
            cape.add((0.47 * mx, -0.28 + 0.14 * k, 0.98), (0.035, 0.045, 0.12), group="cape")
    cb = cape.build({"cape": "5a0a3a"}, voxel=0.014, relax=2, budget=4000, ao=0.3)
    recolor(cb, lambda p, n: smoothstep(1.0, 0.94, p.z), "ffcf3a")
    for mx in (-1, 1):
        for k in range(6):
            C.ellipsoid(f"Coin{mx}{k}", (0.47 * mx, -0.34 + 0.14 * k, 0.94), (0.012, 0.04, 0.04), "gold", "chest")
    C.ellipsoid("Clasp", (0, -0.5, 1.28), (0.06, 0.03, 0.06), "gem", "neck")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = V(legs[side][tag][2])
            C.ellipsoid(f"Hoof{tag}{side}", (paw.x, paw.y - 0.02, 0.04), (0.07, 0.09, 0.05), "hoof", f"shin_{tag}.{side}")
