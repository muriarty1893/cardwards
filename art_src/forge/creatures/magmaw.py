"""Magmaw (Ember Flats, 4): a hovering blob of living magma that is mostly mouth, a crust of black rock
cracking over a molten interior, rows of obsidian fangs and two small smouldering eyes above the maw."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(magma="ff5a14", hot="ffc23a", core="fff0a0", crust="2a2224", fang="140f12", eye="fff4a0", mouth="8a1a0a")
    C.attack = "bite"
    C.plan, C.hover = "hover", 0.35
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.25), (0, 0, 0.6), "root")
    C.bone("chest", (0, 0, 0.6), (0, 0, 0.95), "hips")
    C.bone("head", (0, 0, 0.95), (0, -0.3, 1.0), "chest")
    C.bone("jaw", (0, 0.05, 0.55), (0, -0.35, 0.45), "hips")
    C.bone("tail1", (0, 0, 0.25), (0, 0.05, 0.02), "hips")
    C.spine, C.head, C.jaw, C.tail = ["hips", "chest"], "head", "jaw", ["tail1"]
    C.relax = 1.0
    C.skin("Body", {"top": (0, 0.0, 0.85, 0.45), "mid": (0, 0.0, 0.6, 0.5), "bot": (0, 0.03, 0.32, 0.32),
                    "drip": (0, 0.05, 0.08, 0.08)}, [("top", "mid"), ("mid", "bot"), ("bot", "drip")], "magma")
    # crust plates
    for k in range(10):
        a = 2 * math.pi * k / 10 + 0.3
        z = 0.7 + 0.18 * (k % 2)
        loc, nor = C.surf(math.cos(a) * 0.2, z, dir=(-math.cos(a), -math.sin(a), 0), y=math.sin(a) * 0.2)
        if loc is None:
            continue
        if loc.y < -0.25 and z < 0.8:
            continue
        C.box(f"Crust{k}", tuple(loc + nor * 0.02), (0.22, 0.2, 0.06), "crust", "chest" if z > 0.75 else "hips",
              rot=(0, 0, math.degrees(a)), bevel=0.3)
    # the maw
    C.ellipsoid("Mouth", (0, -0.36, 0.55), (0.34, 0.16, 0.16), "mouth", "hips")
    C.ellipsoid("Lip", (0, -0.32, 0.43), (0.36, 0.2, 0.08), "crust", "jaw")
    for k in range(7):
        x = -0.24 + 0.08 * k
        C.cone(f"FangU{k}", (x, -0.48 + abs(x) * 0.3, 0.68), (x, -0.5 + abs(x) * 0.3, 0.52), 0.035, "fang", "hips", segs=4)
        C.cone(f"FangL{k}", (x * 0.9, -0.46 + abs(x) * 0.3, 0.44), (x * 0.9, -0.48 + abs(x) * 0.3, 0.56), 0.03, "fang",
               "jaw", segs=4)
    C.ellipsoid("Core", (0, -0.3, 0.55), (0.18, 0.08, 0.08), "core", "hips")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.14 * mx, -0.4, 0.86), (0.05, 0.03, 0.035), "eye", "chest", rot=(0, -20 * mx, 0))
        C.box(f"Brow{mx}", (0.14 * mx, -0.41, 0.91), (0.1, 0.04, 0.03), "crust", "chest", rot=(0, 25 * mx, 0), bevel=0.4)
    top = C.surf(0, 5, dir=(0, 0, -1), y=0.05)[0]
    props.flame(C, top - V((0, 0, 0.04)), 0.18, "chest", "magma", "hot", n=5, lean=(0, 0.3, 0), name="Crown")
