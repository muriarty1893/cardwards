"""Frostwisp (Frost Peaks, 2): a drifting spirit of the blizzard, a core of blue ice crystal wrapped in
whirling streamers of snow, two cold slit eyes and frost crystals orbiting it."""
import math
from mathutils import Vector as V
from forge import props


def build(C):
    C.palette(ice="7ad8ff", ice2="e0faff", core="ffffff", mist="cfeaff", eye="0a2a4a", crystal="aef4ff")
    C.plan, C.attack, C.hover = "hover", "cast", 0.4
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.3), (0, 0, 0.65), "root")
    C.bone("chest", (0, 0, 0.65), (0, 0, 0.95), "hips")
    C.bone("head", (0, 0, 0.95), (0, -0.2, 0.95), "chest", deform=False)
    C.bone("tail1", (0, 0, 0.3), (0, 0.05, 0.05), "hips")
    C.spine, C.head, C.tail = ["hips", "chest"], "head", ["tail1"]
    C.cone("CoreTop", (0, 0, 0.7), (0, 0, 1.15), 0.18, "ice", "chest", segs=6)
    C.cone("CoreBot", (0, 0, 0.72), (0, 0, 0.38), 0.17, "ice", "hips", segs=6)
    C.ellipsoid("Glow", (0, -0.08, 0.72), (0.1, 0.06, 0.1), "core", "chest")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, -0.17, 0.8), (0.035, 0.012, 0.012), "eye", "chest", rot=(0, -20 * mx, 0))
    # whirling snow streamers
    for k in range(5):
        a = 2 * math.pi * k / 5
        pts = []
        for j in range(5):
            b = a + j * 0.7
            r = 0.34 - j * 0.04
            pts.append(V((math.cos(b) * r, math.sin(b) * r, 0.95 - j * 0.16)))
        C.tube(f"Streamer{k}", pts, [0.05, 0.045, 0.035, 0.025, 0.006], "mist" if k % 2 else "ice2", None,
               allowed=["chest", "hips", "tail1"])
    C.bone("orbit", (0, 0, 0.7), (0, 0, 0.9), "root")
    for k in range(4):
        a = 2 * math.pi * k / 4
        p = V((math.cos(a) * 0.48, math.sin(a) * 0.48, 0.75))
        C.cone(f"Crystal{k}", tuple(p - V((0, 0, 0.07))), tuple(p + V((0, 0, 0.09))), 0.04, "crystal", "orbit", segs=4)
    C.extra_idle.append(lambda P, t: P.r("orbit", 'Z', -90 * t))
