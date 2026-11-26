"""Cakequake Behemoth (Candy Hills, 9): a hulking beast of layered cake. Sculpted: a massive quadruped
whose body is stacked sponge and chocolate layers, a back built up like a tiered wedding cake with lit
candles, pink frosting dripping down its sides, horns of hardened icing and a crushing chocolate jaw full
of sugar teeth, cherries studding the tiers."""
import math
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(sponge="e8b070", choc="4a2014", frost="fff0f8", pink="ff7ab8", cherry="e01a3a", candle="7ad8ff", flame="ffb03a",
              hot="fff0a0", tooth="ffffff", eye="ff2a6a", dark="1a0a08")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.34, 0.86), chest=(-0.3, 0.92), r_chest=(0.38, 0.36, 0.34), r_belly=(0.38, 0.36, 0.32),
                         r_hips=(0.34, 0.3, 0.3), leg_x=0.28, r_thigh=0.16, r_shin=0.14, r_paw=0.15, paw_len=1.0,
                         neck=((-0.54, 0.92),), r_neck=(0.26,), head=(-0.68, 0.82), r_head=(0.26, 0.24, 0.2),
                         snout=(-0.92, 0.72), r_snout=(0.2, 0.14), tail=((0.62, 0.8),), r_tail=(0.08, 0.04),
                         digi=False, group="sponge", jaw=True)
    h = at["head"]
    cl.add((0, 0.02, 1.28), (0.32, 0.4, 0.1), group="frost")                     # tier 1
    cl.add((0, 0.06, 1.44), (0.22, 0.26, 0.1), group="pink")                     # tier 2
    cl.add((0, 0.08, 1.58), (0.13, 0.15, 0.08), group="frost")                   # tier 3
    for k in range(14):                                                          # frosting drips
        a = 2 * math.pi * k / 14
        cl.add((math.cos(a) * 0.38, 0.02 + math.sin(a) * 0.44, 1.12 - 0.04 * (k % 3)), (0.05, 0.05, 0.12), group="pink")
    cl.add((0, -0.84, 0.66), (0.22, 0.2, 0.1), group="choc")                       # chocolate jaw
    body = cl.build({"sponge": "sponge", "frost": "frost", "pink": "pink", "choc": "choc"}, voxel=0.018, budget=11000,
                    relax=2, texture={"type": 'CLOUDS', "scale": 0.04, "strength": 0.01})
    recolor(body, lambda p, n: smoothstep(0.1, 0.4, math.sin(p.z * 26)) * (1.0 if 0.62 < p.z < 1.15 else 0.0), "choc")
    skulpt.eyes(C, [(0.16, h.y - 0.18, h.z + 0.06)], 0.035, "eye", "dark")
    for mx in (-1, 1):
        C.tube(f"Horn{mx}", [h + V((0.16 * mx, 0.0, 0.14)), h + V((0.28 * mx, -0.06, 0.3)), h + V((0.26 * mx, -0.2, 0.42))],
               [0.06, 0.045, 0.006], "frost", "head")
    for k in range(9):
        a = math.pi * (0.08 + 0.84 * k / 8)
        x, y = math.cos(a) * 0.2, -0.82 - math.sin(a) * 0.16
        C.cone(f"Tooth{k}", (x, y, 0.72), (x, y - 0.01, 0.82 + 0.03 * (k % 2)), 0.03, "tooth", "jaw", segs=4)
    for k, (x, y, z) in enumerate([(-0.24, -0.2, 1.36), (0.24, -0.2, 1.36), (-0.24, 0.28, 1.36), (0.24, 0.28, 1.36),
                                   (0, -0.14, 1.52), (0, 0.24, 1.52), (0, 0.08, 1.66)]):
        bone = "chest" if y < 0.05 else "hips"
        C.tube(f"Candle{k}", [V((x, y, z)), V((x, y, z + 0.16))], [0.025, 0.025], "candle", bone)
        props.flame(C, (x, y, z + 0.17), 0.06, bone, "flame", "hot", n=3, name=f"Wick{k}")
    for k in range(6):
        a = 2 * math.pi * k / 6
        C.ellipsoid(f"Cherry{k}", (math.cos(a) * 0.2, 0.06 + math.sin(a) * 0.24, 1.53), (0.04,) * 3, "cherry",
                    "chest" if math.sin(a) < 0 else "hips")
