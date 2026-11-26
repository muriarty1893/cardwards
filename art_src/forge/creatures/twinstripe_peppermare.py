"""Twinstripe Peppermare (Candy Hills, 5, legend): a peppermint warhorse. Sculpted: a muscular charger with
a glossy candy-white coat spiralled by twin red peppermint stripes that wrap the body, neck and legs, a
mane and tail of spun mint frosting, twin candy-cane horns curling forward like lances, an angry brow
and hooves of hard candy."""
import math
from mathutils import Vector as V
from forge.sculpt import Clay, recolor, smoothstep
from forge.creatures.pyrrhos_spellstorm import horse


def build(C):
    C.palette(white="f6f2f2", red="e8203a", mint="5affc0", dark="1a0a10", eye="3a1a2a", hoof="ff7aa8",
              gold="ffd23a")
    C.plan, C.attack = "quad", "ram"
    body, legs = horse(C, {"hide": "f6f2f2", "muzzle": "f0e0e4", "feather": "5affc0", "mane": "5affc0"}, mane=True,
                       texture={"type": 'CLOUDS', "scale": 0.06, "strength": 0.004})

    # twin peppermint stripes spiralling round the body's long axis, and round each leg
    def stripes(p, n):
        if p.z > 1.7 and p.y < -0.6 or (p - V((0, -0.55, 1.66))).length < 0.3 and abs(p.x) > 0.02 and p.z > 1.5:
            return 0.0
        if p.z < 0.75:
            return smoothstep(0.55, 0.75, math.sin(p.z * 26 + p.y * 4))
        a = math.atan2(p.z - 1.08, p.x)
        return smoothstep(0.5, 0.7, math.sin(2 * a + p.y * 11))
    recolor(body, stripes, "e8203a")
    recolor(body, lambda p, n: smoothstep(0.55, 0.95, n.z) * 0.35, "ffffff")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.895, 1.7), (0.026, 0.034, 0.022), "eye", "head", rot=(0, 0, 25 * mx))
        C.box(f"Brow{mx}", (0.09 * mx, -0.9, 1.75), (0.08, 0.05, 0.02), "red", "head", rot=(0, 20 * mx, -15 * mx),
              bevel=0.4)
        C.cone(f"Ear{mx}", (0.07 * mx, -0.76, 1.8), (0.1 * mx, -0.7, 1.96), 0.042, "white", "head", segs=5)
        C.ellipsoid(f"Nostril{mx}", (0.043 * mx, -1.2, 1.4), (0.018, 0.01, 0.015), "dark", "head")
        # twin candy-cane horns curling forward like lances
        base = V((0.07 * mx, -0.82, 1.82))
        pts = [base, base + V((0.06 * mx, 0.0, 0.24)), base + V((0.05 * mx, -0.14, 0.38)), base + V((0.02 * mx, -0.26, 0.3))]
        C.tube(f"Horn{mx}", pts, [0.042, 0.037, 0.032, 0.022], "white", "head")
        for k in range(5):
            t = k / 5
            seg = min(int(t * 3), 2)
            p = V(pts[seg]).lerp(V(pts[seg + 1]), t * 3 - seg)
            C.ellipsoid(f"HornStripe{mx}{k}", tuple(p), (0.047 - 0.003 * k,) * 2 + (0.014,), "red", "head",
                        rot=(25 + 25 * k, 0, 0))
    tail = Clay(C, "Tail", res=0.02)
    for k in range(5):
        t = k / 4
        tail.add((0.03 * math.sin(k * 2), 0.68 + 0.22 * t, 1.14 - 0.38 * t), (0.11 - 0.015 * k, 0.11, 0.11), group="m")
        tail.add((0.05 * math.sin(k * 2 + 1), 0.72 + 0.22 * t, 1.08 - 0.38 * t), (0.05, 0.05, 0.08), group="w")
    tail.build({"m": "5affc0", "w": "e8fff6"}, voxel=0.014, budget=2500,
               texture={"type": 'CLOUDS', "scale": 0.05, "strength": 0.02}, bone="tail1", allowed=["tail1", "tail2"])
    C.ellipsoid("Bell", (0, -0.66, 1.06), (0.06, 0.06, 0.07), "gold", "chest")
    C.ellipsoid("Collar", (0, -0.52, 1.2), (0.2, 0.2, 0.04), "red", "chest", rot=(-35, 0, 0))
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = V(legs[side][tag][3])
            C.ellipsoid(f"Hoof{tag}{side}", tuple(paw + V((0, -0.01, 0.02))), (0.07, 0.08, 0.05), "hoof",
                        f"shin_{tag}.{side}")
