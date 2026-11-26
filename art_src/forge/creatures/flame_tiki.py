"""Flame Tiki (Ember Flats, 3): a hovering carved war-totem. Sculpted: a tall wooden totem with deep-carved
tiers, a snarling tiki face with a bulging brow, wide flared nostrils and a furnace mouth full of fire and
square teeth, carved ear flaps, a crown of fire on top and two floating stone fists that orbit it."""
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(wood="6a3a1f", dark="3a1f12", carve="a8642f", fire="ff6a1a", hot="ffd03a", core="fff0a0", stone="4a4040",
              glow="ff8a2a", tooth="f0e0c0")
    C.plan, C.attack, C.hover = "hover", "cast", 0.3
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.4), (0, 0, 0.8), "root")
    C.bone("chest", (0, 0, 0.8), (0, 0, 1.1), "hips")
    C.bone("head", (0, 0, 1.1), (0, 0, 1.4), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.3 * sx, 0, 1.0), (0.5 * sx, -0.05, 0.85), "chest")
        C.bone(f"forearm.{side}", (0.5 * sx, -0.05, 0.85), (0.56 * sx, -0.2, 0.7), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    cl = Clay(C, "Body", res=0.02)
    cl.chain([(0, 0, 0.3), (0, 0, 0.7), (0, 0, 1.3)], [(0.2, 0.2, 0.2), (0.26, 0.24, 0.2), (0.27, 0.25, 0.2)],
             group="wood")
    for z in (0.42, 0.62):                                                         # carved tiers
        cl.add((0, 0, z), (0.27, 0.26, 0.04), group="carve")
    cl.add((0, -0.2, 1.12), (0.24, 0.08, 0.06), group="carve")                      # bulging brow
    cl.mirror((0.11, -0.22, 1.04), (0.07, 0.05, 0.06), group="dark", neg=True)      # eye pits
    cl.add((0, -0.27, 0.97), (0.06, 0.07, 0.08), group="wood")                       # nose
    cl.mirror((0.06, -0.3, 0.93), (0.035, 0.03, 0.03), group="dark", neg=True)
    cl.add((0, -0.24, 0.8), (0.17, 0.12, 0.09), group="dark", neg=True)              # furnace mouth
    cl.add((0, -0.16, 0.8), (0.15, 0.06, 0.08), group="fire")
    cl.mirror((0.27, -0.02, 0.98), (0.05, 0.1, 0.16), group="carve")                # ear flaps
    body = cl.build({"wood": "wood", "carve": "carve", "dark": "dark", "fire": "glow"}, voxel=0.011, budget=8000,
                    relax=1, texture={"type": 'STUCCI', "scale": 0.03, "strength": 0.012})
    recolor(body, lambda p, n: smoothstep(0.5, 1.0, abs(n.z)) * 0.3 * (1.0 if 0.4 < p.z < 0.7 else 0.0), "dark")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.11 * mx, -0.235, 1.04), (0.04, 0.015, 0.03), "hot", "head")
    for k in range(5):
        C.box(f"ToothU{k}", (-0.1 + 0.05 * k, -0.27, 0.86), (0.035, 0.03, 0.04), "tooth", "head", bevel=0.2)
        C.box(f"ToothL{k}", (-0.1 + 0.05 * k, -0.27, 0.74), (0.035, 0.03, 0.035), "tooth", "head", bevel=0.2)
    props.flame(C, (0, 0, 1.28), 0.36, "head", "fire", "hot", n=6, lean=(0, 0.2, 0), m_core="core")
    for side, mx in (("L", -1), ("R", 1)):
        c = V((0.56 * mx, -0.22, 0.68))
        C.ellipsoid(f"Fist{side}", tuple(c), (0.13, 0.14, 0.12), "stone", f"forearm.{side}")
        for k in range(3):
            C.box(f"Knuckle{side}{k}", tuple(c + V((0.04 * (k - 1), -0.12, 0.03))), (0.05, 0.05, 0.06), "stone",
                  f"forearm.{side}", bevel=0.4)
        C.ellipsoid(f"FistRune{side}", tuple(c + V((0.12 * mx, 0, 0.0))), (0.02, 0.06, 0.06), "glow", f"forearm.{side}")
