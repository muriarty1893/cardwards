"""Taffy Wolf Matron (Candy Hills, 6): a big alpha she-wolf of pulled caramel taffy. Dressed from
Quaternius's CC0 Wolf (proper anatomy and animation): caramel coat with a cream belly, glowing cherry
eyes, and a shaggy mane of hardened sugar shards bristling over her neck and shoulders."""
import math
from mathutils import Vector as V

DRESS = dict(src="wolf", height=1.15, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "d8843a", "Main_Light": "ffe2b0", "Nose": "3a1a10", "Eyes_Black": "ff1a3a"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack", "HitReact": "Idle_HitReact_Left", "Death": "Death", "Yes": "Idle_2"})


def mane(C, D, m1, m2):
    k = 0
    for bone in ("Neck1", "Neck2", "Neck3", "Torso3", "Torso2"):
        for t in (0.2, 0.7):
            for sx in (-1, 0, 1):
                p = D.top(bone, t)
                d = V((0.5 * sx, 0.55, 0.85)).normalized()
                C.cone(f"Shard{k}", tuple(p - d * 0.03 + V((0.035 * sx, 0, 0))), tuple(p + d * (0.16 - 0.03 * abs(sx))),
                       0.032, m1 if k % 2 else m2, bone, segs=4)
                k += 1


def dress(C, D):
    C.palette(shard="ff6aa0", shard2="ffd0e8")
    mane(C, D, "shard", "shard2")
