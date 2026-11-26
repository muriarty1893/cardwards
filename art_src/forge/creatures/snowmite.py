"""Snowmite (Frost Peaks, 2): a bloated snow tick the size of a dog. Sculpted: a swollen, segmented
abdomen covered in a fluffy white back that hides it in drifts, a small hard blue head with red eyes and
icicle mandibles, and six spindly frost-rimed legs."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fluff="f4f8ff", fluff2="d8e4f0", head="2a5a8a", leg="1a3a5a", ice="cff4ff", eye="ff3a5a")
    C.plan, C.attack = "quad", "bite"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.2, 0.42), (0, -0.05, 0.42), "root")
    C.bone("chest", (0, -0.05, 0.42), (0, -0.28, 0.38), "hips")
    C.bone("head", (0, -0.28, 0.38), (0, -0.5, 0.34), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    legs = []
    for side, sx in (("L", -1), ("R", 1)):
        for k, y in enumerate((-0.2, 0.0, 0.2)):
            up, lo = f"leg{k}.{side}", f"shin{k}.{side}"
            C.bone(up, (0.2 * sx, y, 0.36), (0.38 * sx, y - 0.04, 0.44), "chest" if y < 0 else "hips")
            C.bone(lo, (0.38 * sx, y - 0.04, 0.44), (0.46 * sx, y - 0.02, 0.03), up)
            if k != 1:
                C.legs.append((up, lo, (0.0 if side == "L" else 0.5) if k == 0 else (0.5 if side == "L" else 0.0)))
    cl = Clay(C, "Body", res=0.02)
    cl.add((0, 0.12, 0.46), (0.34, 0.4, 0.3), group="fluff")
    for k in range(12):
        a = 2 * math.pi * k / 12
        cl.add((math.cos(a) * 0.24, 0.12 + math.sin(a) * 0.3, 0.66), (0.12, 0.12, 0.1), group="fluff")
    for k in range(3):
        cl.add((0, 0.12, 0.46), (0.35, 0.03, 0.31), rot=(0, 0, 0), group="fluff2")
    cl.add((0, -0.3, 0.38), (0.13, 0.13, 0.11), group="head")
    cl.add((0, -0.4, 0.36), (0.09, 0.08, 0.07), group="head")
    body = cl.build({"fluff": "fluff", "fluff2": "fluff2", "head": "head"}, voxel=0.01, budget=8000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.03})
    recolor(body, lambda p, n: smoothstep(-0.1, -0.7, n.z) * 0.8 * (1.0 if p.y > -0.2 else 0.0), "fluff2")
    for mx in (-1, 1):
        for k in range(2):
            C.ellipsoid(f"Eye{mx}{k}", (0.07 * mx, -0.4 - 0.02 * k, 0.43 - 0.03 * k), (0.018,) * 3, "eye", "head")
        C.tube(f"Mandible{mx}", [V((0.05 * mx, -0.46, 0.32)), V((0.07 * mx, -0.56, 0.3)), V((0.02 * mx, -0.62, 0.28))],
               [0.025, 0.02, 0.004], "ice", "head")
        side = "L" if mx < 0 else "R"
        for k, y in enumerate((-0.2, 0.0, 0.2)):
            C.tube(f"Leg{side}{k}", [V((0.2 * mx, y, 0.36)), V((0.38 * mx, y - 0.04, 0.46)), V((0.46 * mx, y - 0.02, 0.03))],
                   [0.03, 0.022, 0.01], "leg", None, allowed=[f"leg{k}.{side}", f"shin{k}.{side}"])
            C.ellipsoid(f"Rime{side}{k}", (0.38 * mx, y - 0.04, 0.46), (0.035,) * 3, "ice", f"leg{k}.{side}")
