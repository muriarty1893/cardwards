"""The Rot King (Mushroom Forest, 6, legend): a dead king who will not lie down. Sculpted: a gaunt, hunched
body under heavy royal robes that rot green toward the tattered hem, wide bell sleeves over bony hands, a
skull with deep sockets lit green from within, a mantle overgrown with shelf fungus, a crown of rotten
antlers sprouting toadstools, and a scepter with a festering orb."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(gold="b8902a", gem="a8ff3a", glow="b8ff3a", dark="0a0c08", antler="4a5a2a", toad="b8241a",
              spot="f0e8d0", shelf="a8743a", wood="2a2018", rag="2e2238")
    C.plan, C.attack, C.hover = "hover", "cast", 0.35
    # ---- skeleton
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.04, 1.0), (0, 0.0, 1.32), "root")
    C.bone("chest", (0, 0.0, 1.32), (0, -0.06, 1.62), "hips")
    C.bone("neck", (0, -0.06, 1.62), (0, -0.1, 1.76), "chest")
    C.bone("head", (0, -0.1, 1.76), (0, -0.12, 2.05), "neck")
    C.bone("tail1", (0, 0.04, 1.0), (0, 0.12, 0.6), "hips")
    C.bone("tail2", (0, 0.12, 0.6), (0, 0.24, 0.2), "tail1")
    C.spine, C.neck, C.head, C.tail = ["hips", "chest"], ["neck"], "head", ["tail1", "tail2"]
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.3 * sx, -0.02, 1.6), (0.46 * sx, -0.06, 1.3), "chest")
        C.bone(f"forearm.{side}", (0.46 * sx, -0.06, 1.3), (0.56 * sx, -0.2, 1.06), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))

    # ---- sculpted body: robes, sleeves, hood and skull in one piece
    cl = Clay(C, "Body", res=0.026)
    cl.add((0, 0.0, 1.46), (0.22, 0.16, 0.22), group="robe")                     # narrow chest
    cl.add((0, 0.02, 1.22), (0.16, 0.13, 0.12), group="robe")                    # pinched waist
    cl.add((0, 0.05, 1.64), (0.42, 0.2, 0.09), group="rot")                      # broad mantle
    cl.mirror((0.3, 0.04, 1.62), (0.12, 0.13, 0.1), group="rot")                 # mantle shoulders
    for k in range(5):                                                           # tall collar behind the skull
        a = math.pi * (0.15 + 0.7 * k / 4)
        cl.add((math.cos(a) * 0.2, 0.08 + math.sin(a) * 0.05, 1.86 + 0.06 * (k % 2)), (0.07, 0.035, 0.18),
               rot=(-15, -math.degrees(math.cos(a)) * 0.5, 0), group="rot")
    cl.chain([(0, 0.02, 1.12), (0, 0.06, 0.8), (0, 0.12, 0.5), (0, 0.2, 0.2)],
             [(0.19, 0.16, 0.18), (0.27, 0.23, 0.2), (0.35, 0.3, 0.2), (0.42, 0.36, 0.12)], group="robe")   # bell robe
    for k in range(10):                                                          # deep folds down the robe
        a = 2 * math.pi * k / 10
        for j, (z, r) in enumerate([(0.95, 0.21), (0.65, 0.29), (0.35, 0.37)]):
            cl.add((math.cos(a) * r, 0.07 + 0.06 * j + math.sin(a) * r * 0.86, z), (0.05, 0.05, 0.2),
                   rot=(0, 0, math.degrees(a)), group="robe")
    for sx in (-1, 1):                                                           # bell sleeves
        cl.chain([(0.3 * sx, -0.02, 1.58), (0.46 * sx, -0.06, 1.3), (0.54 * sx, -0.16, 1.1)],
                 [0.085, 0.08, (0.14, 0.14, 0.08)], group="robe")
        cl.add((0.55 * sx, -0.18, 1.07), (0.08, 0.08, 0.06), group="robe", neg=True)          # hollow cuff
        cl.chain([(0.56 * sx, -0.2, 1.08), (0.58 * sx, -0.26, 0.97)], [0.04, 0.032], group="bone")   # bony wrist
    cl.add((0, 0.04, 1.88), (0.19, 0.19, 0.21), group="robe")                    # hood
    cl.add((0, -0.12, 1.87), (0.15, 0.12, 0.18), group="robe", neg=True)         # hood opening
    cl.add((0, -0.07, 1.88), (0.15, 0.16, 0.16), group="bone")                   # cranium
    cl.mirror((0.08, -0.17, 1.83), (0.055, 0.05, 0.045), group="bone")           # cheekbones
    cl.add((0, -0.16, 1.74), (0.085, 0.08, 0.05), group="bone")                  # jaw
    cl.mirror((0.055, -0.21, 1.89), (0.05, 0.05, 0.05), group="bone", neg=True)  # deep eye sockets
    cl.add((0, -0.22, 1.82), (0.022, 0.03, 0.035), group="bone", neg=True)       # nose hole
    body = cl.build({"robe": "3a2850", "rot": "4f6a26", "bone": "d8ccaa"}, voxel=0.013, budget=12000, relax=3,
                    texture={"type": 'CLOUDS', "scale": 0.08, "strength": 0.008})
    # rot creeping up the hem, a gold trim band low on the robe
    recolor(body, lambda p, n: smoothstep(0.75, 0.2, p.z) * (0.0 if p.z > 1.2 else 1.0) * 0.85, "3f5a22")
    recolor(body, lambda p, n: (1.0 if 0.88 < p.z < 0.94 and n.z < 0.6 else 0.0), "8a6a20")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Glow{mx}", (0.055 * mx, -0.215, 1.89), (0.026, 0.014, 0.026), "glow", "head")
        for k in range(4):
            C.tube(f"Finger{mx}{k}", [V((0.58 * mx + 0.015 * (k - 1.5), -0.27, 0.96)),
                                      V((0.6 * mx + 0.025 * (k - 1.5), -0.32, 0.88)),
                                      V((0.6 * mx + 0.03 * (k - 1.5), -0.3, 0.8))], [0.014, 0.011, 0.004], "spot",
                   f"forearm.{'L' if mx < 0 else 'R'}")
    for k in range(5):
        C.box(f"Tooth{k}", (-0.04 + 0.02 * k, -0.225, 1.765), (0.016, 0.012, 0.024), "spot", "head", bevel=0.3)
    props.crown(C, (0, -0.06, 1.98), 0.14, "gold", "head", points=5, height=0.12, m_gem="gem")
    for mx in (-1, 1):
        b = V((0.1 * mx, -0.04, 2.04))
        main = [b, b + V((0.16 * mx, 0.04, 0.2)), b + V((0.34 * mx, 0.0, 0.36)), b + V((0.44 * mx, 0.06, 0.52))]
        C.tube(f"Antler{mx}", main, [0.035, 0.028, 0.018, 0.004], "antler", "head")
        for k, (t, d) in enumerate([(1, (0.0, 0.1, 0.22)), (2, (0.12 * mx, -0.06, 0.16))]):
            p = V(main[t])
            C.tube(f"Tine{mx}{k}", [p, p + V(d)], [0.016, 0.003], "antler", "head")
        C.ellipsoid(f"Toad{mx}", tuple(V(main[2]) + V((0, 0, 0.04))), (0.07, 0.07, 0.035), "toad", "head")
        for k in range(3):
            C.ellipsoid(f"ToadSpot{mx}{k}", tuple(V(main[2]) + V((0.03 * (k - 1), 0.01 * k, 0.07))), (0.012,) * 3, "spot",
                        "head")
        # shelf fungus on the shoulders
        for k in range(3):
            C.ellipsoid(f"Shelf{mx}{k}", (0.34 * mx, 0.06 + 0.07 * k, 1.66 - 0.08 * k), (0.12 - 0.02 * k, 0.09, 0.03),
                        "shelf", "chest", rot=(0, -12 * mx, 0))
    # tattered hem trailing below the skirt
    for k in range(10):
        a = 2 * math.pi * k / 10
        top = V((math.cos(a) * 0.38, 0.2 + math.sin(a) * 0.32, 0.16))
        C.cone(f"Rag{k}", tuple(top), tuple(top + V((math.cos(a) * 0.05, 0.04, -0.2 - 0.08 * (k % 3)))), 0.07, "rag",
               "tail2", segs=4)
    # scepter with a festering orb in the right hand
    hr = V((0.585, -0.3, 0.9))
    C.tube("Scepter", [hr + V((0, 0.02, -0.5)), hr, hr + V((0, -0.04, 0.55))], [0.025, 0.025, 0.03], "wood", "forearm.R")
    C.ellipsoid("Orb", tuple(hr + V((0, -0.05, 0.66))), (0.09, 0.09, 0.09), "glow", "forearm.R")
    for k in range(3):
        a = 2 * math.pi * k / 3
        C.horn(f"OrbClaw{k}", tuple(hr + V((0, -0.04, 0.55))),
               tuple(hr + V((math.cos(a) * 0.1, -0.05 + math.sin(a) * 0.1, 0.76))), 0.02, "gold", "forearm.R")
