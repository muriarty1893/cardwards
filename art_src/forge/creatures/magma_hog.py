"""Magma Hog (Ember Flats, 4): a lava-forged war boar. Sculpted: a wedge-shaped brute, all shoulders, with
a hide of cooled black rock split by glowing magma cracks, a heavy low head with a flat snout, curved
obsidian tusks, small furious eyes and a bristling ridge of fire down its spine."""
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep, cracks, crease


def build(C):
    C.palette(rock="2e2624", magma="ff5a14", hot="ffc23a", tusk="1a1418", eye="ffd03a", snout="4a3a38", pupil="1a0a04")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.32, 0.56), chest=(-0.22, 0.66), r_chest=(0.3, 0.3, 0.32), r_belly=(0.25, 0.3, 0.25),
                         r_hips=(0.22, 0.22, 0.22), leg_x=0.2, r_thigh=0.11, r_shin=0.065, r_paw=0.07, paw_len=1.0,
                         neck=((-0.42, 0.66),), r_neck=(0.24,), head=(-0.56, 0.58), r_head=(0.19, 0.2, 0.18),
                         snout=(-0.84, 0.46), r_snout=(0.13, 0.11), tail=((0.52, 0.56), (0.58, 0.46)),
                         r_tail=(0.03, 0.015), digi=False, hump=(0.2, 0.24, 0.14), group="rock")
    h, s = at["head"], at["snout"]
    cl.add(tuple(s + V((0, -0.04, 0.0))), (0.11, 0.05, 0.09), group="snout")                  # flat snout disc
    for sx in (-1, 1):
        cl.add((0.04 * sx, s.y - 0.09, s.z + 0.01), (0.025, 0.02, 0.03), group="snout", neg=True)   # nostrils
        cl.add((0.12 * sx, h.y - 0.1, h.z + 0.06), (0.07, 0.06, 0.04), rot=(0, 0, -20 * sx), group="rock")  # brow
        cl.add((0.12 * sx, h.y - 0.12, h.z + 0.02), (0.03, 0.025, 0.025), group="rock", neg=True)
        cl.chain([(0.12 * sx, h.y + 0.04, h.z + 0.12), (0.18 * sx, h.y + 0.08, h.z + 0.2)], [0.05, 0.015],
                 group="rock")
    body = cl.build({"rock": "rock", "snout": "snout"}, voxel=0.014, budget=10000,
                    texture={"type": 'VORONOI', "scale": 0.05, "strength": 0.016})
    recolor(body, lambda p, n: 0.9 * cracks(p, 0.3, 0.05, seed=17), "magma")
    crease(body, "magma", 0.62, 0.86)
    recolor(body, lambda p, n: smoothstep(0.2, 0.04, p.z) * 0.7, "magma")
    skulpt.eyes(C, [(0.12, h.y - 0.14, h.z + 0.02)], 0.022, "eye", "pupil")
    for mx in (-1, 1):
        b = s + V((0.09 * mx, 0.04, -0.06))
        C.tube(f"Tusk{mx}", [b, b + V((0.06 * mx, -0.06, 0.04)), b + V((0.07 * mx, -0.04, 0.18))], [0.035, 0.025, 0.004],
               "tusk", "head")
    for k in range(7):
        y = -0.42 + 0.13 * k
        z = 1.0 - 0.06 * abs(k - 2)
        props.flame(C, (0, y, z - 0.06), 0.16 - 0.012 * abs(k - 2), "chest" if y < 0.05 else "hips", "magma", "hot",
                    n=3, lean=(0, 0.5, 0.3), name=f"Ridge{k}")
