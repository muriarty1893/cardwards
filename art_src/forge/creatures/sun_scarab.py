"""Sun Scarab (Sunny Dunes, 3): a sacred golden scarab in flight, its shell cases flung open over whirring
wings, a horned head, and between its forelegs it rolls a blazing miniature sun."""
import math
from mathutils import Vector as V
from forge import props


def build(C):
    C.palette(gold="e8b02a", gold2="ffe07a", dark="2a1a08", wing="ffe8b0", sun="ff8a1a", hot="fff0a0", eye="3ad8ff",
              gem="1a8aff")
    C.plan, C.attack, C.hover = "flyer", "dive", 0.5
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("chest", (0, 0.1, 0.75), (0, -0.15, 0.8), "root")
    C.bone("head", (0, -0.15, 0.8), (0, -0.35, 0.82), "chest")
    C.spine, C.head = ["chest"], "head"
    C.ellipsoid("Body", (0, 0.05, 0.75), (0.24, 0.32, 0.15), "dark", "chest")
    C.ellipsoid("Head", (0, -0.28, 0.8), (0.14, 0.12, 0.09), "gold", "head")
    C.cone("Horn", (0, -0.34, 0.85), (0, -0.4, 1.02), 0.04, "gold2", "head", segs=6, smooth=True)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.34, 0.83), (0.03, 0.025, 0.025), "eye", "head")
        C.cone(f"Prong{mx}", (0.08 * mx, -0.36, 0.82), (0.14 * mx, -0.44, 0.88), 0.025, "gold2", "head", segs=5)
        for k, y in enumerate((-0.15, 0.0, 0.15)):
            C.tube(f"Leg{mx}{k}", [V((0.12 * mx, y, 0.66)), V((0.24 * mx, y - 0.05, 0.58)), V((0.18 * mx, y - 0.15 * (k == 0), 0.44))],
                   [0.022, 0.018, 0.01], "dark", "chest")
    # shell cases flung open, gem markings
    for side, mx in (("L", -1), ("R", 1)):
        sh = (0.08 * mx, -0.05, 0.86)
        C.bone(f"wing.{side}", sh, (0.4 * mx, 0.05, 1.05), "chest")
        C.bone(f"wing2.{side}", (0.4 * mx, 0.05, 1.05), (0.7 * mx, 0.2, 1.1), f"wing.{side}")
        C.wings.append((f"wing.{side}", f"wing2.{side}", side))
        C.ellipsoid(f"Elytra{side}", (0.22 * mx, 0.08, 0.95), (0.16, 0.3, 0.05), "gold", None, rot=(0, -40 * mx, 0),
                    allowed=[f"wing.{side}"])
        C.ellipsoid(f"Gem{side}", (0.24 * mx, 0.02, 0.99), (0.04, 0.07, 0.02), "gem", None, rot=(0, -40 * mx, 0),
                    allowed=[f"wing.{side}"])
        C.membrane(f"Wing{side}", [(0.08 * mx, 0.0, 0.85), (0.55 * mx, -0.05, 0.98), (0.75 * mx, 0.2, 1.0), (0.4 * mx, 0.4, 0.9)][::(1 if mx > 0 else -1)],
                   "wing", None, thick=0.012, allowed=[f"wing.{side}", f"wing2.{side}"])
    # the little sun it rolls
    C.ellipsoid("Sun", (0, -0.42, 0.55), (0.14, 0.14, 0.14), "sun", "chest")
    C.ellipsoid("SunCore", (0, -0.5, 0.58), (0.08, 0.06, 0.08), "hot", "chest")
    for k in range(8):
        a = 2 * math.pi * k / 8
        C.cone(f"Ray{k}", (math.cos(a) * 0.12, -0.42, 0.55 + math.sin(a) * 0.12), (math.cos(a) * 0.24, -0.42, 0.55 + math.sin(a) * 0.24),
               0.035, "gold2", "chest", segs=4)
