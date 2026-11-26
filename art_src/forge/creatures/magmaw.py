"""Magmaw (Ember Flats, 4): a hovering blob of living magma that is mostly mouth. Sculpted: a heavy molten
drop with a crust of black rock plates cracking over its glowing interior, a huge gaping maw splitting it
from side to side ringed with obsidian fangs, a molten tongue, two small smouldering eyes above, and
dripping lava below."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep, cracks, crease


def build(C):
    C.palette(magma="ff5a14", hot="ffc23a", core="fff0a0", crust="2a2224", fang="140f12", eye="fff4a0", mouth="8a1a0a")
    C.plan, C.attack, C.hover = "hover", "bite", 0.35
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.5), (0, 0, 0.8), "root")
    C.bone("chest", (0, 0, 0.8), (0, -0.05, 1.05), "hips")
    C.bone("head", (0, -0.05, 1.05), (0, -0.3, 1.1), "chest")
    C.bone("jaw", (0, 0.05, 0.75), (0, -0.4, 0.6), "hips")
    C.bone("tail1", (0, 0, 0.5), (0, 0.05, 0.2), "hips")
    C.spine, C.head, C.jaw, C.tail = ["hips", "chest"], "head", "jaw", ["tail1"]
    cl = Clay(C, "Body", res=0.024)
    cl.add((0, 0, 0.82), (0.42, 0.4, 0.38), group="crust")
    cl.add((0, 0.02, 0.5), (0.3, 0.28, 0.26), group="magma")                           # sagging drip
    cl.add((0, 0.04, 0.26), (0.12, 0.12, 0.16), group="magma")
    cl.add((0, -0.3, 0.76), (0.36, 0.22, 0.13), group="mouth", neg=True)                # the maw
    cl.add((0, -0.18, 0.76), (0.3, 0.14, 0.1), group="mouth")
    for k in range(8):                                                                   # crust plates
        a = 2 * math.pi * k / 8
        cl.add((math.cos(a) * 0.3, 0.05 + math.sin(a) * 0.28, 1.0 + 0.05 * (k % 2)), (0.16, 0.16, 0.06),
               rot=(math.degrees(math.sin(a)) * 0.5, -math.degrees(math.cos(a)) * 0.5, 0), group="crust")
    cl.mirror((0.12, -0.32, 1.02), (0.04, 0.035, 0.03), group="crust", neg=True)
    body = cl.build({"crust": "crust", "magma": "magma", "mouth": "mouth"}, voxel=0.013, budget=9000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.05, "strength": 0.02})
    recolor(body, lambda p, n: 0.9 * cracks(p, 0.3, 0.05, seed=31) * (1.0 if p.z > 0.6 else 0.0), "magma")
    crease(body, "magma", 0.62, 0.86)
    recolor(body, lambda p, n: smoothstep(0.6, 0.35, p.z), "hot")
    recolor(body, lambda p, n: (1.0 if p.y < -0.12 and abs(p.z - 0.76) < 0.1 else 0.0) * 0.8, "core")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.12 * mx, -0.345, 1.02), (0.035, 0.015, 0.022), "eye", "head")
    for k in range(9):
        a = math.pi * (0.06 + 0.88 * k / 8)
        x, y = math.cos(a) * 0.33, -0.08 - math.sin(a) * 0.3
        C.cone(f"FangU{k}", (x, y, 0.87), (x * 0.95, y - 0.01, 0.76 - 0.02 * (k % 2)), 0.03, "fang", "head", segs=4)
        C.cone(f"FangL{k}", (x * 0.92, y + 0.02, 0.66), (x * 0.9, y + 0.01, 0.76 + 0.02 * (k % 2)), 0.026, "fang", "jaw",
               segs=4)
    C.tube("Tongue", [V((0, -0.1, 0.7)), V((0, -0.3, 0.68)), V((0.04, -0.46, 0.6))], [0.09, 0.07, 0.03], "magma", "jaw")
