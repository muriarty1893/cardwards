"""Sun Scarab (Sunny Dunes, 3): a sacred golden scarab in flight. Sculpted: a heavy, rounded golden
beetle with a ridged pronotum and a horned, toothed head, its shell cases flung open above whirring
wings, and between its spiny forelegs it rolls a blazing miniature sun."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(gold="e8b02a", gold2="ffe07a", dark="2a1a08", wing="ffe8b0", sun="ff8a1a", hot="fff0a0", eye="3ad8ff", gem="1a8aff")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.5
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.14, 0.62), (0, -0.06, 0.66), "root")
    C.bone("head", (0, -0.06, 0.66), (0, -0.3, 0.66), "hips")
    C.spine, C.head = ["hips"], "head"
    skulpt.wing_bones(C, (0.1, 0.0, 0.8), (0.34, 0.12, 0.94), (0.6, 0.24, 0.92), parent="hips")
    cl = Clay(C, "Body", res=0.016)
    cl.add((0, 0.14, 0.62), (0.2, 0.24, 0.15), group="gold")
    cl.add((0, -0.08, 0.66), (0.18, 0.12, 0.12), group="gold2")                       # pronotum
    cl.add((0, -0.08, 0.76), (0.03, 0.1, 0.03), group="gold")
    cl.add((0, -0.22, 0.64), (0.12, 0.08, 0.06), group="gold")                        # head
    for k in range(5):
        cl.add((-0.08 + 0.04 * k, -0.29, 0.62), (0.025, 0.03, 0.02), group="gold2")    # toothed clypeus
    body = cl.build({"gold": "gold", "gold2": "gold2"}, voxel=0.008, budget=6000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.012, "strength": 0.004})
    recolor(body, lambda p, n: smoothstep(0.85, 1.0, n.z) * 0.6, "gold2")
    C.cone("Horn", (0, -0.24, 0.68), (0, -0.3, 0.84), 0.035, "dark", "head", segs=6)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.08 * mx, -0.24, 0.66), (0.025,) * 3, "eye", "head")
        side = "L" if mx < 0 else "R"
        C.ellipsoid(f"Elytra{side}", (0.14 * mx, 0.18, 0.84), (0.1, 0.24, 0.035), "gold", f"wing.{side}", rot=(-20, 30 * mx, 15 * mx))
        pts = [(0.08 * mx, 0.04, 0.78), (0.3 * mx, 0.06, 0.96), (0.6 * mx, 0.2, 0.94), (0.5 * mx, 0.36, 0.82),
               (0.2 * mx, 0.3, 0.74)]
        if mx < 0:
            pts = pts[::-1]
        C.membrane(f"Wing{side}", pts, "wing", None, thick=0.008, allowed=[f"wing.{side}", f"wing2.{side}"])
        for k, y in enumerate((-0.08, 0.06, 0.18)):
            C.tube(f"Leg{side}{k}", [V((0.12 * mx, y, 0.56)), V((0.22 * mx, y - 0.04, 0.5)), V((0.18 * mx, y - 0.12 * (k == 0), 0.36))],
                   [0.02, 0.016, 0.006], "dark", "hips")
    C.ellipsoid("Sun", (0, -0.3, 0.4), (0.12, 0.12, 0.12), "sun", "hips")
    props.flame(C, (0, -0.3, 0.46), 0.12, "hips", "sun", "hot", n=6, name="Corona")
    C.ellipsoid("SunGem", (0, -0.2, 0.74), (0.03, 0.02, 0.03), "gem", "head")
