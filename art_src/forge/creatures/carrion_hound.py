"""Carrion Hound (Mushroom Forest, 3): a gaunt grave-hound. Dressed from Quaternius's CC0 Wolf: rotting
dark hide, a bare skull over its face with sickly glowing eyes, bone spines down its back and a ragged
moss mane."""
from mathutils import Vector as V

DRESS = dict(src="wolf", height=1.05, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "2f3a2d", "Main_Light": "4a5240", "Nose": "12150f", "Eyes_Black": "c6ff3a"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack", "HitReact": "Idle_HitReact_Left", "Death": "Death", "Yes": "Idle_2"})


def dress(C, D):
    C.palette(bone="e3d7b8", moss="5f8f2e", dark="12150f", glow="c6ff3a")
    k = 0
    for bone in ("Torso3", "Torso2", "Torso", "Back"):
        for t in (0.3, 0.8):
            p = D.top(bone, t)
            C.cone(f"Spine{k}", tuple(p - V((0, 0, 0.02))), tuple(p + V((0, 0.05, 0.12))), 0.02, "bone", bone, segs=5)
            k += 1
    for k, bone in enumerate(("Neck1", "Neck2", "Neck3")):
        C.ellipsoid(f"Moss{k}", tuple(D.top(bone, 0.5)), (0.07, 0.06, 0.04), "moss", bone)
