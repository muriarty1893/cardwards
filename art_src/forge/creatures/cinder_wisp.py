"""Cinder Wisp (Ember Flats, 2): a burning skull drifting on a tail of smoke and sparks. Sculpted: a
cracked horned skull with deep sockets lit from within, a heavy brow and a loose rattling jaw, wreathed in
fire, trailing a long twisting tail of smoke that thins into sparks."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def build(C):
    C.palette(bone="e0d4b8", crack="2a1a14", fire="ff6a1a", hot="ffd03a", core="fff4c0", smoke="4a3a3a", dark="140a08")
    C.plan, C.attack, C.hover = "hover", "dive", 0.35
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.1, 0.62), (0, 0.0, 0.8), "root")
    C.bone("head", (0, 0.0, 0.8), (0, -0.2, 1.0), "hips")
    C.bone("jaw", (0, -0.02, 0.76), (0, -0.2, 0.66), "head")
    tail = [(0, 0.1, 0.62), (0.08, 0.3, 0.46), (-0.06, 0.48, 0.32), (0.04, 0.62, 0.2)]
    for i in range(3):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    C.spine, C.head, C.jaw = ["hips"], "head", "jaw"
    cl = Clay(C, "Body", res=0.018)
    cl.add((0, 0.0, 0.92), (0.17, 0.19, 0.17), group="bone")                           # cranium
    cl.mirror((0.08, -0.13, 0.86), (0.06, 0.05, 0.05), group="bone")                   # cheekbones
    cl.add((0, -0.14, 0.94), (0.14, 0.06, 0.04), group="bone")                         # brow
    cl.mirror((0.065, -0.18, 0.88), (0.045, 0.04, 0.04), group="dark", neg=True)       # sockets
    cl.add((0, -0.2, 0.83), (0.02, 0.03, 0.03), group="dark", neg=True)                # nose hole
    cl.add((0, -0.12, 0.72), (0.11, 0.08, 0.04), group="bone")                         # jaw
    cl.chain(tail, [0.13, 0.1, 0.06, 0.02], group="smoke")
    body = cl.build({"bone": "bone", "dark": "bone", "smoke": "smoke"}, voxel=0.009, budget=7000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.01})
    recolor(body, lambda p, n: cracks(p, 0.06, 0.06, seed=37) * (1.0 if p.z > 0.7 else 0.0), "crack")
    recolor(body, lambda p, n: smoothstep(0.7, 0.55, p.z) * 0.7, "fire")
    for mx in (-1, 1):
        C.ellipsoid(f"Glow{mx}", (0.065 * mx, -0.19, 0.88), (0.025, 0.012, 0.022), "core", "head")
        C.cone(f"Horn{mx}", (0.1 * mx, -0.04, 1.04), (0.2 * mx, 0.04, 1.2), 0.035, "dark", "head", segs=6)
    for k in range(5):
        C.box(f"Tooth{k}", (-0.04 + 0.02 * k, -0.19, 0.78), (0.015, 0.012, 0.024), "bone", "head", bevel=0.3)
        C.box(f"ToothL{k}", (-0.04 + 0.02 * k, -0.18, 0.745), (0.015, 0.012, 0.02), "bone", "jaw", bevel=0.3)
    props.flame(C, (0, 0.02, 1.0), 0.3, "head", "fire", "hot", n=6, lean=(0, 0.5, 0), m_core="core")
    for k in range(6):
        p = V(tail[min(3, k // 2 + 1)]) + V((0.06 * math.sin(k * 2), 0.04 * k, 0.05 * math.cos(k)))
        C.ellipsoid(f"Spark{k}", tuple(p), (0.015,) * 3, "hot", f"tail{min(3, k // 2 + 1)}")
