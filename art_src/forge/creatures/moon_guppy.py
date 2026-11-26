"""Moon Guppy (Dark Moon, 2): a little deep-night fish that swims through the air. Sculpted: a plump
round fish with a big head and a toothy underbite, huge moon-silver eyes, a lantern lure dangling on a
stalk over its face, small fins and a long flowing veil tail whose edges glow."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(body="2a3a7a", belly="8ab0e8", glow="aef4ff", eye="f0f4ff", pupil="0a0a1a", tooth="ffffff", fin="5a7ad8",
              stalk="1a2a5a")
    C.plan, C.attack, C.hover = "swimmer", "bite", 0.5
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.06, 0.6), (0, -0.08, 0.62), "root")
    C.bone("head", (0, -0.08, 0.62), (0, -0.3, 0.6), "hips")
    C.bone("jaw", (0, -0.12, 0.52), (0, -0.3, 0.5), "head")
    C.bone("tail1", (0, 0.06, 0.6), (0, 0.26, 0.64), "hips")
    C.bone("tail2", (0, 0.26, 0.64), (0, 0.5, 0.66), "tail1")
    C.spine, C.head, C.jaw, C.tail = ["hips"], "head", "jaw", ["tail1", "tail2"]
    cl = Clay(C, "Body", res=0.014)
    cl.add((0, -0.04, 0.6), (0.17, 0.22, 0.17), group="body")
    cl.add((0, -0.1, 0.5), (0.13, 0.16, 0.07), group="belly")
    cl.add((0, -0.24, 0.5), (0.11, 0.08, 0.06), group="belly")                        # underbite jaw
    cl.add((0, -0.26, 0.56), (0.1, 0.06, 0.02), group="body", neg=True)
    cl.chain([(0, 0.14, 0.62), (0, 0.26, 0.64)], [0.08, 0.04], group="body")
    for sx in (-1, 1):
        cl.chain([(0.14 * sx, -0.06, 0.54), (0.24 * sx, 0.0, 0.48)], [(0.02, 0.05, 0.04), (0.01, 0.03, 0.02)], group="fin")
    cl.chain([(0, -0.04, 0.76), (0, 0.06, 0.84), (0, 0.16, 0.78)], [(0.02, 0.06, 0.04), (0.015, 0.06, 0.04), 0.01], group="fin")
    body = cl.build({"body": "body", "belly": "belly", "fin": "fin"}, voxel=0.007, budget=5000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.02, "strength": 0.003})
    recolor(body, lambda p, n: smoothstep(-0.2, -0.7, n.z) * 0.8, "belly")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.16, 0.64), (0.06, 0.05, 0.06), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", (0.12 * mx, -0.2, 0.64), (0.025, 0.02, 0.03), "pupil", "head")
    for k in range(7):
        a = math.pi * (0.1 + 0.8 * k / 6)
        x, y = math.cos(a) * 0.09, -0.24 - math.sin(a) * 0.06
        C.cone(f"Tooth{k}", (x, y, 0.53), (x, y - 0.005, 0.58 + 0.01 * (k % 2)), 0.01, "tooth", "jaw", segs=4)
    C.tube("Lure", [V((0, -0.16, 0.76)), V((0, -0.26, 0.86)), V((0, -0.36, 0.8)), V((0, -0.38, 0.72))],
           [0.012, 0.01, 0.008, 0.006], "stalk", "head")
    C.ellipsoid("Lantern", (0, -0.38, 0.69), (0.04, 0.04, 0.04), "glow", "head")
    for k in range(5):                                                          # flowing veil tail
        a = math.radians(-40 + 20 * k)
        pts = [(0, 0.26, 0.64), (math.sin(a) * 0.12, 0.42, 0.64 + math.cos(a) * 0.08), (math.sin(a) * 0.2, 0.6, 0.6 + math.cos(a) * 0.14)]
        C.tube(f"Veil{k}", [V(p) for p in pts], [0.03, 0.05, 0.012], "fin", None, allowed=["tail1", "tail2"])
        C.ellipsoid(f"VeilGlow{k}", pts[-1], (0.03, 0.03, 0.03), "glow", "tail2")
