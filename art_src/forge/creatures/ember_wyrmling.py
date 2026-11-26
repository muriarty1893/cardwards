"""Ember Wyrmling (Ember Flats, 3): a young fire dragon, all elbows and attitude. Sculpted: a lanky,
big-headed young dragon with an oversized skull and jaw, stubby horns and a crest of nubs, bony elbows,
oversized clawed feet, orange scales over a lighter ridged belly, small leathery wings and a long tail,
smoke curling from its nostrils."""
from mathutils import Vector as V
from forge import kits, props, skulpt
from forge.sculpt import recolor, smoothstep


def build(C):
    C.palette(scale="e85a1a", belly="ffd08a", horn="3a2a24", wing="ff8a3a", wingbone="8a2a10", eye="fff2a0",
              pupil="1a0a08", fire="ff6a1a", hot="ffd03a", smoke="6a5a5a", tooth="fff4e0", dark="a83a10")
    C.attack = "dive"
    C.plan, C.hover = "flyer", 0.4
    cl, at = skulpt.quad(C, hip=(0.26, 0.5), chest=(-0.16, 0.56), r_chest=(0.18, 0.2, 0.19), r_belly=(0.15, 0.2, 0.15),
                         r_hips=(0.16, 0.16, 0.16), leg_x=0.16, r_thigh=0.08, r_shin=0.045, r_paw=0.07, paw_len=1.4,
                         neck=((-0.26, 0.72), (-0.32, 0.86)), r_neck=(0.1, 0.085), head=(-0.42, 0.94),
                         r_head=(0.14, 0.15, 0.12), snout=(-0.66, 0.88), r_snout=(0.09, 0.07),
                         tail=((0.46, 0.46), (0.68, 0.38), (0.86, 0.44)), r_tail=(0.08, 0.02), group="scale",
                         belly_group="belly", jaw=True)
    h, s = at["head"], at["snout"]
    for sx in (-1, 1):
        cl.add((0.08 * sx, h.y - 0.08, h.z + 0.07), (0.07, 0.07, 0.035), rot=(0, 0, -15 * sx), group="dark")  # brow
        cl.add((0.085 * sx, h.y - 0.1, h.z + 0.03), (0.035, 0.035, 0.03), group="scale", neg=True)
        cl.add((0.1 * sx, h.y + 0.0, h.z - 0.05), (0.06, 0.07, 0.06), group="scale")                       # cheek
        cl.mirror((0.16, -0.18, 0.52), (0.04, 0.04, 0.04), group="scale")                                   # elbows
    cl.add(tuple(s + V((0, 0.06, -0.07))), (0.08, 0.12, 0.04), group="belly")                                 # jaw
    cl.add(tuple(s + V((0, 0.0, -0.035))), (0.075, 0.1, 0.008), group="scale", neg=True)
    for k in range(6):
        cl.add((0, -0.34 + 0.15 * k, 0.76 - 0.03 * abs(k - 1)), (0.03, 0.03, 0.04), group="dark")               # nubs
    body = cl.build({"scale": "scale", "belly": "belly", "dark": "dark"}, voxel=0.01, budget=9000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.02, "strength": 0.008})
    recolor(body, lambda p, n: smoothstep(-0.3, -0.75, n.z) * (1.0 if p.z > 0.3 else 0.0), "belly")
    skulpt.eyes(C, [(0.09, h.y - 0.115, h.z + 0.03)], 0.03, "eye", "pupil", slit=True)
    for mx in (-1, 1):
        C.cone(f"Horn{mx}", (0.07 * mx, h.y + 0.02, h.z + 0.1), (0.12 * mx, h.y + 0.12, h.z + 0.22), 0.035, "horn", "head",
               segs=6)
        C.cone(f"Fang{mx}", tuple(s + V((0.05 * mx, -0.02, -0.02))), tuple(s + V((0.05 * mx, -0.025, -0.07))), 0.012,
               "tooth", "head", segs=4)
        C.ellipsoid(f"Smoke{mx}", tuple(s + V((0.04 * mx, -0.08, 0.06 + 0.04))), (0.03, 0.03, 0.04), "smoke", "head")
    kits.wings(C, "wingbone", "wing", shoulder=(0.12, -0.1, 0.7), span=0.6, up=0.45, sweep=0.25, r=0.03, droop=0.45)
    props.flame(C, tuple(at["tail"][-1]), 0.1, "tail3", "fire", "hot", n=3, lean=(0, 0.4, 0.3), name="TailFire")
