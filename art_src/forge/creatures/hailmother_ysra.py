"""Hailmother Ysra (Frost Peaks, 8, legend): a floating storm-witch of the peaks. Sculpted: a tall, regal
woman with pale blue skin whose gown thins into a twisting tail of mist, a great mane of wind-whipped white
hair streaming behind her, a stern face under a crown of hailstones, wings of jagged ice shards and a
storm of hail orbiting her."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(eye="ffffff", dark="0a1a3a", ice="aef4ff", ice2="e8fbff", hail="e8f8ff", lips="2a3a8a", trim="d8f0ff")
    C.plan, C.attack, C.hover = "hover", "cast", 0.45
    # ---- skeleton
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.04, 1.02), (0, 0.0, 1.3), "root")
    C.bone("chest", (0, 0.0, 1.3), (0, -0.02, 1.56), "hips")
    C.bone("neck", (0, -0.02, 1.56), (0, -0.03, 1.68), "chest")
    C.bone("head", (0, -0.03, 1.68), (0, -0.03, 1.96), "neck")
    tail = [(0, 0.04, 1.02), (0, 0.12, 0.7), (0.08, 0.24, 0.42), (-0.02, 0.38, 0.22)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.2 * sx, 0.0, 1.52), (0.36 * sx, -0.02, 1.3), "chest")
        C.bone(f"forearm.{side}", (0.36 * sx, -0.02, 1.3), (0.48 * sx, -0.18, 1.14), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.022)
    cl.add((0, 0.0, 1.42), (0.16, 0.11, 0.15), group="dress")                  # ribcage
    cl.mirror((0.065, -0.085, 1.4), (0.065, 0.055, 0.055), group="dress")      # bust
    cl.add((0, 0.01, 1.22), (0.1, 0.085, 0.1), group="dress")                  # waist
    cl.add((0, 0.03, 1.06), (0.18, 0.14, 0.1), group="dress")                  # hips
    cl.mirror((0.18, 0.0, 1.5), (0.065, 0.065, 0.06), group="skin")            # shoulders
    cl.add((0, -0.01, 1.52), (0.12, 0.08, 0.05), group="skin")                 # collarbones
    # gown thinning into a twisting tail of mist
    cl.chain(tail, [(0.2, 0.16, 0.12), (0.22, 0.18, 0.16), (0.14, 0.12, 0.12), (0.04, 0.04, 0.06)], group="dress")
    for k in range(8):
        a = 2 * math.pi * k / 8
        cl.add((math.cos(a) * 0.19, 0.12 + math.sin(a) * 0.15, 0.74), (0.045, 0.045, 0.2),
               rot=(0, 0, math.degrees(a)), group="dress")
    for sx in (-1, 1):
        cl.chain([(0.2 * sx, 0.0, 1.5), (0.36 * sx, -0.02, 1.3), (0.48 * sx, -0.18, 1.14)], [0.045, 0.038, 0.032],
                 group="skin")
        cl.add((0.5 * sx, -0.2, 1.12), (0.035, 0.045, 0.03), group="skin")
    cl.add((0, -0.02, 1.62), (0.045, 0.045, 0.06), group="skin")               # neck
    cl.add((0, -0.04, 1.76), (0.095, 0.1, 0.115), group="skin")                # head
    cl.add((0, -0.1, 1.69), (0.05, 0.05, 0.04), group="skin")                  # jaw
    cl.mirror((0.05, -0.12, 1.75), (0.03, 0.03, 0.025), group="skin")          # cheekbones
    cl.add((0, -0.14, 1.77), (0.012, 0.02, 0.03), group="skin")                # nose
    cl.mirror((0.04, -0.13, 1.79), (0.022, 0.016, 0.014), group="skin", neg=True)
    # a great mane of hair streaming back and up in the storm
    for k in range(7):
        a = math.pi * (0.05 + 0.9 * k / 6)
        b = V((math.cos(a) * 0.09, 0.0, 1.8 + math.sin(a) * 0.06))
        cl.chain([b, b + V((math.cos(a) * 0.1, 0.2, 0.06)), b + V((math.cos(a) * 0.2, 0.42, 0.0 + 0.06 * (k % 3))),
                  b + V((math.cos(a) * 0.26, 0.62, -0.1 + 0.08 * (k % 3)))], [0.07, 0.06, 0.04, 0.012], group="hair")
    cl.add((0, 0.02, 1.82), (0.11, 0.1, 0.1), group="hair")
    body = cl.build({"dress": "2a4a8a", "skin": "9ac8e8", "hair": "f4faff"}, voxel=0.011, budget=12000, relax=3,
                    texture={"type": 'CLOUDS', "scale": 0.06, "strength": 0.005})
    # the gown fades to white mist toward the tail; frost lace at the neckline
    recolor(body, lambda p, n: smoothstep(0.85, 0.3, p.z) * 0.9, "dcefff")
    recolor(body, lambda p, n: (1.0 if 1.46 < p.z < 1.5 and p.y < 0.05 and abs(p.x) < 0.17 else 0.0), "e8f8ff")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.04 * mx, -0.135, 1.79), (0.022, 0.008, 0.012), "eye", "head", rot=(0, 15 * mx, 0))
        C.box(f"Brow{mx}", (0.045 * mx, -0.135, 1.82), (0.05, 0.014, 0.01), "dark", "head", rot=(0, 18 * mx, 0),
              bevel=0.4)
    C.box("Lips", (0, -0.142, 1.71), (0.036, 0.008, 0.01), "lips", "head", bevel=0.4)
    for k in range(7):                                                         # hailstone crown
        a = math.pi * (0.1 + 0.8 * k / 6)
        b = V((math.cos(a) * 0.11, -0.04 - math.sin(a) * 0.05, 1.86))
        C.cone(f"Crown{k}", tuple(b), tuple(b + V((math.cos(a) * 0.03, 0.02, 0.14 + 0.12 * (k == 3)))), 0.03, "ice",
               "head", segs=5)
        C.ellipsoid(f"CrownHail{k}", tuple(b + V((0, 0, 0.01))), (0.022,) * 3, "hail", "head")
    # wings of jagged ice shards fanning from the shoulder blades
    for side, sx in (("L", -1), ("R", 1)):
        sh = V((0.08 * sx, 0.1, 1.42))
        el = V((0.4 * sx, 0.24, 1.72))
        C.bone(f"wing.{side}", tuple(sh), tuple(el), "chest")
        C.bone(f"wing2.{side}", tuple(el), tuple(el + V((0.3 * sx, 0.1, 0.12))), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))
        for k in range(6):
            a = math.radians(70 - 26 * k)
            ln = 0.75 - 0.08 * abs(k - 2)
            tip = el + V((math.cos(a) * ln * sx, 0.12 + 0.03 * k, math.sin(a) * ln))
            C.cone(f"Shard{side}{k}", tuple(el.lerp(sh, 0.3)), tuple(tip), 0.06 - 0.005 * k,
                   "ice" if k % 2 else "ice2", f"wing2.{side}" if k < 3 else f"wing.{side}", segs=4)
    C.bone("orbit", (0, 0, 1.1), (0, 0, 1.35), "root")
    for k in range(8):
        a = 2 * math.pi * k / 8
        r = 0.6 + 0.08 * (k % 2)
        C.ellipsoid(f"Hail{k}", (math.cos(a) * r, math.sin(a) * r, 1.0 + 0.3 * math.sin(2 * a)), (0.06,) * 3,
                    "hail", "orbit")
        C.cone(f"HailTrail{k}", (math.cos(a) * r, math.sin(a) * r, 1.0 + 0.3 * math.sin(2 * a)),
               (math.cos(a - 0.35) * r, math.sin(a - 0.35) * r, 1.0 + 0.3 * math.sin(2 * a - 0.7)), 0.05, "ice",
               "orbit", segs=4)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', 45 * t))
    for side, sx in (("L", -1), ("R", 1)):
        hd = V((0.5 * sx, -0.22, 1.12))
        C.ellipsoid(f"Orb{side}", tuple(hd + V((0, -0.08, 0.08))), (0.08,) * 3, "ice", f"forearm.{side}")
        for k in range(3):
            a = 2 * math.pi * k / 3
            C.cone(f"OrbSpike{side}{k}", tuple(hd + V((0, -0.08, 0.08))),
                   tuple(hd + V((math.cos(a) * 0.14, -0.08, 0.08 + math.sin(a) * 0.14))), 0.02, "ice2",
                   f"forearm.{side}", segs=4)
