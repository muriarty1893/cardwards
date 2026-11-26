"""Spore Drifter (Mushroom Forest, 1): a drifting fungal jelly, a ragged toxic cap with glowing gills
and a single slit eye, trailing barbed spore tendrils."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(cap="3b2a52", rim="6b3f8a", gill="9cff6a", eye="d4ff3a", pupil="10140c", tendril="4c3a5e",
              barb="b6ff5a")
    C.plan, C.attack, C.hover = "hover", "dive", 0.35
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("chest", (0, 0, 0.75), (0, 0, 1.25), "root")
    C.bone("head", (0, 0, 1.25), (0, -0.3, 1.25), "chest", deform=False)
    C.bone("tail1", (0, 0, 0.75), (0, 0.05, 0.42), "chest")
    C.bone("tail2", (0, 0.05, 0.42), (0, 0.12, 0.05), "tail1")
    C.spine, C.head, C.tail = ["chest"], "head", ["tail1", "tail2"]
    C.lathe("Cap", [(0.001, 0.82), (0.5, 0.8), (0.62, 0.84), (0.58, 0.98), (0.46, 1.15), (0.26, 1.28),
                    (0.001, 1.32)], "cap", "chest", segs=28, wave=(7, 0.12, 0.45))
    C.lathe("Gills", [(0.12, 0.8), (0.4, 0.82), (0.58, 0.83)], "gill", "chest", segs=28)
    # torn rim flaps
    for k in range(7):
        a = 2 * math.pi * k / 7 + 0.3
        b = V((math.cos(a) * 0.55, math.sin(a) * 0.55, 0.86))
        C.cone(f"Flap{k}", b, b + V((math.cos(a) * 0.12, math.sin(a) * 0.12, -0.18)), 0.09, "rim", "chest", segs=5)
    # one big slit eye on the front of the cap
    C.ellipsoid("Eye", (0, -0.5, 1.03), (0.16, 0.08, 0.1), "eye", "chest", rot=(-20, 0, 0))
    C.ellipsoid("Pupil", (0, -0.565, 1.04), (0.025, 0.03, 0.085), "pupil", "chest", rot=(-20, 0, 0))
    C.box("Lid", (0, -0.5, 1.13), (0.36, 0.12, 0.06), "rim", "chest", rot=(-20, 0, 0), bevel=0.5)
    # glowing spots on the cap
    for k in range(6):
        a = 2 * math.pi * k / 6 + 0.9
        C.decal(f"Spot{k}", math.cos(a) * 0.28, 1.2, (0.07, 0.07, 0.025), "gill", "chest", part="Cap",
                dir=(0, 0, -1), y=math.sin(a) * 0.28)
    # trailing tendrils with barbs
    for k in range(7):
        a = 2 * math.pi * k / 7
        r = 0.22 + 0.12 * (k % 2)
        top = V((math.cos(a) * r, math.sin(a) * r, 0.8))
        ln = 0.55 + 0.15 * (k % 3)
        pts = [top, top + V((math.cos(a) * 0.08, math.sin(a) * 0.08 + 0.05, -ln * 0.5)),
               top + V((math.cos(a) * 0.02, math.sin(a) * 0.02 + 0.14, -ln))]
        C.tube(f"Tendril{k}", pts, [0.05, 0.035, 0.008], "tendril", None, allowed=["tail1", "tail2"])
        C.ellipsoid(f"Barb{k}", tuple(pts[1]), (0.045, 0.045, 0.045), "barb", None, allowed=["tail1", "tail2"])
