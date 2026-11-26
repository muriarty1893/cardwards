"""Taffy Wolf Matron (Candy Hills, 6): a big alpha she-wolf of pulled caramel taffy. Sculpted: a powerful,
deep-chested wolf with long legs, a long muzzle with rock-candy fangs, a shaggy mane of hardened sugar
shards bristling over her neck and shoulders, a bushy tail, glowing cherry eyes and rock-candy claws.
Snow Wolf reuses her in ice (the palette decides the look)."""
import math
from mathutils import Vector as V
from forge import skulpt
from forge.sculpt import Clay, recolor, smoothstep


def build(C):
    C.palette(taffy="d8843a", cream="ffe2b0", shard="ff6aa0", shard2="ffd0e8", fang="fff6fa", eye="ff1a3a", dark="2a120a",
              nose="3a1a10")
    C.attack = "bite"
    cl, at = skulpt.quad(C, hip=(0.34, 0.74), chest=(-0.26, 0.82), r_chest=(0.22, 0.28, 0.28), r_belly=(0.17, 0.3, 0.17),
                         r_hips=(0.18, 0.2, 0.2), leg_x=0.17, r_thigh=0.1, r_shin=0.05, r_paw=0.07, paw_len=1.4,
                         neck=((-0.44, 0.96),), r_neck=(0.15,), head=(-0.56, 1.02), r_head=(0.13, 0.15, 0.12),
                         snout=(-0.86, 0.96), r_snout=(0.08, 0.055), tail=((0.56, 0.74), (0.76, 0.6)),
                         r_tail=(0.08, 0.05), group="taffy", belly_group="cream", jaw=True)
    h, s = at["head"], at["snout"]
    for sx in (-1, 1):
        cl.chain([(0.08 * sx, h.y + 0.04, h.z + 0.1), (0.11 * sx, h.y + 0.06, h.z + 0.22)], [(0.05, 0.025, 0.05), 0.01],
                 group="taffy")
        cl.add((0.08 * sx, h.y - 0.1, h.z + 0.06), (0.05, 0.04, 0.025), rot=(0, 0, -15 * sx), group="taffy")
    cl.add(tuple(s + V((0, 0.06, -0.05))), (0.06, 0.12, 0.035), group="cream")
    cl.chain([(0, 0.56, 0.74), (0, 0.72, 0.64), (0, 0.84, 0.5)], [0.08, 0.1, 0.05], group="taffy")    # bushy tail
    body = cl.build({"taffy": "taffy", "cream": "cream"}, voxel=0.012, budget=10000, relax=2,
                    texture={"type": 'CLOUDS', "scale": 0.025, "strength": 0.015})
    recolor(body, lambda p, n: smoothstep(0.5, 0.9, math.sin(p.y * 22 + p.z * 14)) * 0.25, "cream")
    skulpt.eyes(C, [(0.07, h.y - 0.12, h.z + 0.04)], 0.024, "eye", None)
    C.ellipsoid("Nose", tuple(s + V((0, -0.06, 0.02))), (0.03, 0.022, 0.022), "nose", "head")
    for mx in (-1, 1):
        C.cone(f"Fang{mx}", tuple(s + V((0.035 * mx, -0.02, -0.03))), tuple(s + V((0.035 * mx, -0.025, -0.1))), 0.014,
               "fang", "head", segs=4)
        for tag in ("f", "b"):
            p = V(at["legs"]["L" if mx < 0 else "R"][tag][-1])
            for k in (-1, 0, 1):
                C.cone(f"Claw{tag}{mx}{k}", tuple(p + V((0.03 * k, -0.08, 0.01))), tuple(p + V((0.035 * k, -0.13, -0.01))),
                       0.012, "fang", f"shin_{tag}.{'L' if mx < 0 else 'R'}", segs=4)
    # mane of sugar shards bristling from the neck and shoulders
    for k in range(13):
        a = math.pi * (0.1 + 0.8 * (k % 7) / 6)
        y = -0.5 + 0.1 * (k // 7) + 0.04 * (k % 2)
        z = 1.0 - 0.1 * (k // 7)
        b = V((math.cos(a) * 0.14, y + 0.05, z + math.sin(a) * 0.08 - 0.04))
        d = V((math.cos(a) * 0.5, 0.6, math.sin(a) * 0.8)).normalized()
        C.cone(f"Shard{k}", tuple(b), tuple(b + d * (0.2 - 0.03 * (k % 3))), 0.04, "shard" if k % 2 else "shard2",
               "neck" if y < -0.42 else "chest", segs=4)
