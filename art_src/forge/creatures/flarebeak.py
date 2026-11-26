"""Flarebeak (Ember Flats, 3): a fighting fire-cock of the lava fields. Sculpted: a proud, puffed-out
breast and a strutting upright carriage, layered crimson-and-gold hackles, a comb of living flame, a
hooked molten beak and wattles, strong scaled legs with black spurs, and a sweeping sickle tail whose
feathers trail sparks."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(plume="b8201a", plume2="ffb03a", beak="ffd23a", eye="1a0a08", ring="fff4c0", leg="ffb03a", spur="2a1a14",
              fire="ff6a1a", hot="ffd03a", wattle="ff3a2a")
    C.attack = "bite"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.12, 0.62), (0, -0.05, 0.74), "root")
    C.bone("chest", (0, -0.05, 0.74), (0, -0.16, 0.9), "hips")
    C.bone("neck", (0, -0.16, 0.9), (0, -0.2, 1.08), "chest")
    C.bone("head", (0, -0.2, 1.08), (0, -0.4, 1.12), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    tail = [(0, 0.2, 0.74), (0, 0.38, 0.98), (0, 0.5, 1.08)]
    for i in range(2):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.1 * sx, 0.06, 0.58), (0.12 * sx, -0.02, 0.34), "hips")
        C.bone(f"shin.{side}", (0.12 * sx, -0.02, 0.34), (0.12 * sx, 0.0, 0.04), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))
    skulpt.wing_bones(C, (0.18, -0.02, 0.86), (0.28, 0.12, 0.8), (0.28, 0.34, 0.74))
    cl = Clay(C, "Body", res=0.018)
    cl.add((0, -0.12, 0.8), (0.2, 0.2, 0.22), rot=(-20, 0, 0), group="plume")          # puffed breast
    cl.add((0, 0.08, 0.7), (0.18, 0.24, 0.16), group="dark")                            # body
    cl.chain([(0, -0.14, 0.92), (0, -0.2, 1.06), (0, -0.24, 1.12)], [0.12, 0.09, 0.09], group="plume2")  # neck
    for k in range(7):                                                                   # hackles
        a = math.pi * (0.15 + 0.7 * k / 6)
        cl.add((math.cos(a) * 0.11, -0.12 + math.sin(a) * 0.08, 0.96), (0.05, 0.05, 0.11),
               rot=(25, -math.degrees(math.cos(a)) * 0.6, 0), group="plume2")
    cl.add((0, -0.26, 1.13), (0.08, 0.09, 0.08), group="plume")                         # head
    for sx in (-1, 1):
        cl.chain([(0.17 * sx, -0.02, 0.84), (0.22 * sx, 0.12, 0.78), (0.2 * sx, 0.3, 0.7)],
                 [(0.06, 0.1, 0.1), (0.06, 0.12, 0.09), (0.03, 0.08, 0.04)], group="plume")   # folded wings
        cl.chain([(0.1 * sx, 0.06, 0.58), (0.12 * sx, -0.02, 0.38)], [0.08, 0.05], group="plume")  # thighs
    body = cl.build({"plume": "plume", "plume2": "plume2", "dark": "spur"}, voxel=0.009, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.1, 0.5, math.sin(p.z * 80 + p.y * 30)) * 0.3 * (1.0 if p.z > 0.9 else 0.0), "plume")
    for mx in (-1, 1):
        C.ellipsoid(f"Ring{mx}", (0.055 * mx, -0.3, 1.15), (0.02, 0.018, 0.02), "ring", "head")
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, -0.31, 1.15), (0.01, 0.01, 0.012), "eye", "head")
        C.tube(f"Shin{mx}", [V((0.12 * mx, -0.02, 0.36)), V((0.12 * mx, 0.0, 0.04))], [0.025, 0.02], "leg",
               f"shin.{'L' if mx < 0 else 'R'}")
        for k in (-1, 0, 1):
            C.tube(f"Toe{mx}{k}", [V((0.12 * mx, 0.0, 0.03)), V((0.12 * mx + 0.05 * k, -0.1, 0.01))], [0.016, 0.008],
                   "leg", f"shin.{'L' if mx < 0 else 'R'}")
        C.cone(f"Spur{mx}", (0.12 * mx, 0.01, 0.14), (0.12 * mx, 0.08, 0.1), 0.014, "spur", f"shin.{'L' if mx < 0 else 'R'}",
               segs=5)
        C.ellipsoid(f"Wattle{mx}", (0.02 * mx, -0.31, 1.05), (0.02, 0.025, 0.04), "wattle", "head")
    C.cone("Beak", (0, -0.32, 1.13), (0, -0.42, 1.09), 0.035, "beak", "head", segs=8, smooth=True)
    C.cone("BeakHook", (0, -0.4, 1.1), (0, -0.43, 1.06), 0.015, "beak", "head", segs=6)
    for k in range(4):
        props.flame(C, (0, -0.32 + 0.05 * k, 1.2 - 0.01 * k), 0.09 - 0.01 * k, "head", "fire", "hot", n=3,
                    lean=(0, 0.2, 0.2), name=f"Comb{k}")
    for k in range(5):                                                                   # sickle tail
        a = math.radians(-30 + 15 * k)
        pts = [V((0, 0.18, 0.74)), V((math.sin(a) * 0.1, 0.36, 1.02)), V((math.sin(a) * 0.2, 0.56, 1.06)),
               V((math.sin(a) * 0.24, 0.66, 0.86 - 0.04 * k))]
        C.tube(f"TailFeather{k}", pts, [0.04, 0.045, 0.03, 0.006], "plume" if k % 2 else "plume2", None,
               allowed=["tail1", "tail2"])
        C.ellipsoid(f"TailSpark{k}", tuple(pts[-1]), (0.02,) * 3, "hot", "tail2")
