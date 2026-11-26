"""Nocturna, Velvet Queen (Dark Moon, 6, legend): a vampire bat matriarch. Sculpted: a sleek, upright body
in velvet-black fur with a plush ruby ruff, tall pointed ears lined in crimson, a pinched leaf-nosed snout
with long fangs and blood-red eyes, clawed feet tucked beneath her, vast crimson-lined wings and a
delicate silver crown between the ears."""
import math
from mathutils import Vector as V
from forge import kits, props
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(fur="1e1020", wing="3a0a1c", lining="a8102a", bone="3a2030", silver="d8d8e8", gem="ff2a4a",
              eye="ff2a3a", fang="ffffff", claw="0a0408", dark="0a0408")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.5
    # ---- skeleton (faces -y), body upright
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.06, 0.72), (0, 0.0, 0.94), "root")
    C.bone("chest", (0, 0.0, 0.94), (0, -0.04, 1.14), "hips")
    C.bone("neck", (0, -0.04, 1.14), (0, -0.08, 1.22), "chest")
    C.bone("head", (0, -0.08, 1.22), (0, -0.12, 1.46), "neck")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"leg.{side}", (0.1 * sx, 0.06, 0.7), (0.13 * sx, 0.02, 0.5), "hips")
        C.bone(f"shin.{side}", (0.13 * sx, 0.02, 0.5), (0.12 * sx, 0.06, 0.36), f"leg.{side}")
        C.legs.append((f"leg.{side}", f"shin.{side}", 0.0 if side == "L" else 0.5))

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.022)
    cl.add((0, 0.0, 1.0), (0.2, 0.17, 0.22), group="fur")                       # chest
    cl.add((0, 0.04, 0.78), (0.16, 0.14, 0.14), group="fur")                    # belly
    for k in range(10):                                                         # plush ruby ruff
        a = 2 * math.pi * k / 10
        cl.add((math.cos(a) * 0.17, -0.02 + math.sin(a) * 0.14, 1.12), (0.09, 0.09, 0.08), group="ruff")
    cl.add((0, -0.08, 1.04), (0.12, 0.08, 0.12), group="ruff")
    for sx in (-1, 1):
        cl.chain([(0.1 * sx, 0.06, 0.7), (0.13 * sx, 0.02, 0.5), (0.12 * sx, 0.06, 0.36)], [0.065, 0.04, 0.03],
                 group="fur")
        cl.add((0.12 * sx, 0.02, 0.34), (0.04, 0.06, 0.025), group="skin")
    # head: round skull, pinched snout with a nose-leaf, tall ears with deep hollows
    cl.add((0, -0.1, 1.3), (0.15, 0.14, 0.13), group="fur")
    cl.chain([(0, -0.18, 1.28), (0, -0.28, 1.25)], [(0.08, 0.07, 0.07), (0.055, 0.05, 0.05)], group="fur")
    cl.add((0, -0.32, 1.27), (0.035, 0.02, 0.05), group="skin")                 # nose-leaf
    cl.add((0, -0.3, 1.22), (0.045, 0.03, 0.006), group="skin", neg=True)       # mouth line
    cl.mirror((0.065, -0.21, 1.33), (0.03, 0.025, 0.025), group="fur", neg=True)
    for sx in (-1, 1):
        cl.chain([(0.1 * sx, -0.08, 1.38), (0.17 * sx, -0.06, 1.56), (0.21 * sx, -0.04, 1.74)],
                 [(0.08, 0.04, 0.08), (0.075, 0.035, 0.07), (0.02, 0.02, 0.03)], group="fur",
                 rot=None)
        cl.add((0.16 * sx, -0.09, 1.54), (0.05, 0.02, 0.1), rot=(0, -20 * sx, 0), group="lining", neg=True)
    cl.add((0, 0.1, 0.62), (0.05, 0.06, 0.08), group="fur")                     # tail stub
    body = cl.build({"fur": "1e1020", "ruff": "8a0a2a", "skin": "5a3a4a", "lining": "a8102a"}, voxel=0.011,
                    budget=11000, texture={"type": 'CLOUDS', "scale": 0.03, "strength": 0.012})
    # velvet sheen across the top; crimson inside the ears
    recolor(body, lambda p, n: smoothstep(0.5, 0.95, n.z) * 0.4, "4a2a4a")
    recolor(body, lambda p, n: (smoothstep(-0.2, -0.7, n.y) * smoothstep(1.4, 1.5, p.z)
                                * (1.0 if abs(p.x) > 0.12 else 0.0) * 0.8), "8a0a22")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.068 * mx, -0.225, 1.33), (0.028, 0.015, 0.02), "eye", "head", rot=(0, 0, 25 * mx))
        C.box(f"Brow{mx}", (0.07 * mx, -0.22, 1.37), (0.07, 0.03, 0.016), "fur", "head", rot=(0, 25 * mx, 0), bevel=0.4)
        C.cone(f"Fang{mx}", (0.025 * mx, -0.3, 1.22), (0.025 * mx, -0.31, 1.13), 0.015, "fang", "head", segs=5)
        for k in (-1, 0, 1):
            C.cone(f"Claw{mx}{k}", (0.12 * mx + 0.02 * k, -0.02, 0.34), (0.12 * mx + 0.025 * k, -0.06, 0.28), 0.01,
                   "claw", f"shin.{'L' if mx < 0 else 'R'}", segs=4)
    props.crown(C, (0, -0.1, 1.42), 0.075, "silver", "head", points=5, height=0.08, m_gem="gem")
    kits.wings(C, "bone", "wing", shoulder=(0.16, 0.0, 1.06), span=1.0, up=0.6, sweep=0.3, r=0.04, droop=0.85,
               fingers=4, thick=0.02)
    for side, mx in (("L", -1), ("R", 1)):
        el = V(C.bones[f"wing2.{side}"]["head"])
        C.cone(f"Thumb{side}", tuple(el), tuple(el + V((0.02 * mx, -0.08, 0.1))), 0.02, "silver", f"wing2.{side}", segs=4)
    C.ellipsoid("Pendant", (0, -0.17, 0.98), (0.04, 0.02, 0.05), "gem", "chest")
