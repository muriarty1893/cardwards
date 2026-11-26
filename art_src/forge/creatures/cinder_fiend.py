"""Cinder Fiend (Ember Flats, 7, legend): a winged fire demon. Sculpted: a hulking, hunched brute with a
huge chest and shoulders over a narrow waist, digitigrade goat legs, long clawed arms, charcoal hide split
by glowing magma veins, a burning skull-face under heavy ram horns, ember bat wings and a whip tail tipped
with flame. A fireball gathers over one palm."""
import math
from mathutils import Vector as V
from forge import kits, props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(vein="ff5a1a", hot="ffc83a", horn="1a1416", horn2="3a2a26", bone="d8c8b0", wing="5a1a14",
              wingbone="2a1c1c", eye="fff2a0", claw="140f10", socket="1a0404")
    C.plan, C.attack = "biped", "cast"
    # ---- skeleton (faces -y), hunched forward
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.04, 0.9), (0, -0.02, 1.14), "root")
    C.bone("chest", (0, -0.02, 1.14), (0, -0.14, 1.46), "hips")
    C.bone("neck", (0, -0.14, 1.46), (0, -0.24, 1.58), "chest")
    C.bone("head", (0, -0.24, 1.58), (0, -0.26, 1.84), "neck")
    C.bone("jaw", (0, -0.28, 1.6), (0, -0.4, 1.56), "head")
    C.spine, C.neck, C.head, C.jaw = ["hips", "chest"], ["neck"], "head", "jaw"
    for side, sx in (("L", -1), ("R", 1)):
        sh, el, hd = (0.4 * sx, -0.1, 1.44), (0.56 * sx, -0.06, 1.12), (0.6 * sx, -0.22, 0.86)
        C.bone(f"arm.{side}", sh, el, "chest")
        C.bone(f"forearm.{side}", el, hd, f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
        C.anch["hd" + side] = hd
        # goat legs: thigh forward, shin back to a raised heel, then down to the hoof
        C.bone(f"leg.{side}", (0.17 * sx, 0.04, 0.88), (0.2 * sx, -0.12, 0.5), "hips")
        C.bone(f"shin.{side}", (0.2 * sx, -0.12, 0.5), (0.2 * sx, 0.04, 0.06), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    tail = [(0, 0.14, 0.88), (0, 0.46, 0.66), (0, 0.76, 0.5), (0, 0.98, 0.6)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.028)
    cl.add((0, -0.1, 1.34), (0.34, 0.24, 0.24), rot=(-15, 0, 0), group="hide")         # massive ribcage
    cl.mirror((0.15, -0.26, 1.34), (0.15, 0.1, 0.13), rot=(0, 0, 12), group="hide")    # pectorals
    cl.mirror((0.32, -0.08, 1.46), (0.16, 0.16, 0.14), group="hide")                    # deltoids
    cl.mirror((0.16, 0.02, 1.5), (0.18, 0.14, 0.1), rot=(0, -20, 0), group="hide")     # trapezius hump
    cl.add((0, 0.0, 1.1), (0.18, 0.14, 0.16), group="hide")                             # narrow waist
    cl.mirror((0.07, -0.13, 1.1), (0.055, 0.04, 0.12), group="hide")                    # abs
    cl.add((0, 0.04, 0.92), (0.22, 0.16, 0.14), group="hide")                           # pelvis
    for sx in (-1, 1):
        # arms: thick upper arm, forearm swelling below the elbow, a big clawed hand
        cl.chain([(0.4 * sx, -0.1, 1.44), (0.56 * sx, -0.06, 1.12)], [0.11, 0.085], group="hide")
        cl.chain([(0.56 * sx, -0.06, 1.12), (0.58 * sx, -0.12, 1.0), (0.6 * sx, -0.22, 0.88)], [0.08, 0.095, 0.07],
                 group="hide")
        cl.add((0.6 * sx, -0.26, 0.82), (0.075, 0.08, 0.07), group="dark")
        # goat legs: heavy thigh, thin shin, hoof
        cl.chain([(0.17 * sx, 0.04, 0.88), (0.2 * sx, -0.12, 0.5)], [0.14, 0.1], group="hide")
        cl.chain([(0.2 * sx, -0.12, 0.5), (0.2 * sx, 0.0, 0.3), (0.2 * sx, 0.06, 0.1)], [0.085, 0.065, 0.055],
                 group="dark")
        cl.add((0.2 * sx, 0.02, 0.05), (0.07, 0.09, 0.05), group="dark")
    # head: skull face pushed forward out of the shoulders
    cl.add((0, -0.24, 1.58), (0.1, 0.1, 0.1), group="hide")                             # neck stump
    cl.add((0, -0.32, 1.7), (0.14, 0.14, 0.14), group="bone")                           # cranium
    cl.add((0, -0.38, 1.6), (0.1, 0.1, 0.07), group="bone")                             # jaw/muzzle
    cl.mirror((0.075, -0.42, 1.73), (0.08, 0.05, 0.03), rot=(0, 25, 0), group="dark")   # heavy brow
    cl.mirror((0.06, -0.44, 1.69), (0.038, 0.04, 0.03), group="bone", neg=True)         # eye sockets
    cl.add((0, -0.48, 1.57), (0.07, 0.04, 0.018), group="bone", neg=True)               # mouth slit
    cl.chain(tail, [0.09, 0.06, 0.035, 0.018], group="hide")
    body = cl.build({"hide": "2a1e20", "dark": "140e10", "bone": "b8a88a"}, voxel=0.015, budget=11000,
                    texture={"type": 'VORONOI', "scale": 0.04, "strength": 0.012})
    # magma veins: thin glowing cracks across the hide, hottest in the chest
    def veins(p, n):
        if p.z < 0.45 or (abs(p.x) < 0.17 and p.y < -0.28 and p.z > 1.5):
            return 0.0
        return cracks(p, 0.13, 0.06) * smoothstep(0.45, 0.8, p.z)
    recolor(body, veins, "ff6a1a")
    recolor(body, lambda p, n: smoothstep(0.24, 0.0, (V((p.x * 0.8, p.y, p.z)) - V((0, -0.3, 1.32))).length) * 0.8,
            "ff8a2a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, -0.46, 1.69), (0.026, 0.012, 0.018), "eye", "head")
        horn = [(0.11 * mx, -0.28, 1.8), (0.26 * mx, -0.18, 1.9), (0.34 * mx, -0.08, 1.76),
                (0.28 * mx, -0.18, 1.64), (0.33 * mx, -0.3, 1.7)]
        C.tube(f"Horn{mx}", [V(p) for p in horn], [0.065, 0.055, 0.045, 0.028, 0.004], "horn", "head")
        for k in range(4):
            p = V(horn[0]).lerp(V(horn[1]), 0.5) if k == 0 else V(horn[k])
            C.ellipsoid(f"HornRing{mx}{k}", tuple(p), (0.05 - 0.007 * k,) * 2 + (0.014,), "horn2", "head")
        C.cone(f"Fang{mx}", (0.04 * mx, -0.47, 1.59), (0.045 * mx, -0.48, 1.5), 0.016, "bone", "jaw", segs=5)
        C.cone(f"Tusk{mx}", (0.08 * mx, -0.42, 1.58), (0.13 * mx, -0.46, 1.68), 0.018, "bone", "jaw", segs=5)
        # shoulder spikes
        for k in range(3):
            b = V((0.34 * mx, -0.04 + 0.06 * k, 1.56 - 0.03 * k))
            C.cone(f"ShSpike{mx}{k}", tuple(b), tuple(b + V((0.06 * mx, 0.04, 0.14 - 0.03 * k))), 0.03, "horn",
                   "chest", segs=5)
    C.ellipsoid("Maw", (0, -0.47, 1.575), (0.06, 0.02, 0.016), "vein", "head")
    props.flame(C, (0, -0.28, 1.82), 0.2, "head", "vein", "hot", n=5, lean=(0, 0.5, 0))
    for k, (y, z) in enumerate([(0.08, 1.46), (0.12, 1.32), (0.12, 1.18), (0.1, 1.04)]):
        C.cone(f"Back{k}", (0, y, z), (0, y + 0.12, z + 0.06), 0.035, "horn", "chest" if z > 1.14 else "hips", segs=5)
    kits.wings(C, "wingbone", "wing", shoulder=(0.2, 0.1, 1.42), span=0.9, up=0.75, sweep=0.35, r=0.05, droop=0.65)
    props.flame(C, (0, 0.99, 0.62), 0.12, "tail3", "vein", "hot", n=3, lean=(0, 0.6, 0.2), name="TailFire")
    for side, mx in (("L", -1), ("R", 1)):
        hd = V(C.anch["hd" + side])
        for k in (-1, 0, 1):
            C.cone(f"Claw{side}{k}", hd + V((0.03 * k, -0.07, -0.04)), hd + V((0.04 * k, -0.13, -0.16)), 0.018,
                   "claw", f"forearm.{side}", segs=5)
    hl = V(C.anch["hdL"])
    C.ellipsoid("Fireball", hl + V((0, -0.12, 0.14)), (0.1, 0.1, 0.1), "hot", "forearm.L")
    props.flame(C, hl + V((0, -0.12, 0.18)), 0.12, "forearm.L", "vein", "hot", n=4, name="Palm")
