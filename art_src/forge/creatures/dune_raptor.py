"""Dune Raptor (Sunny Dunes, 3): a sand-striped desert raptor. Dressed from Quaternius's CC0 Velociraptor
(proper anatomy and animation): sand-gold hide with dark stripes, a crest of red quills down its neck and
back, and the killing sickle-claw raised on each foot."""
from mathutils import Vector as V

DRESS = dict(src="raptor", height=1.05, head_bone="Head", rear_bone="Tail3",
             colors={"LightBrown": "d8a45a", "Brown": "6a3a1a"},
             anims={"Idle": "Velociraptor_Idle", "Walk": "Velociraptor_Walk", "Punch": "Velociraptor_Attack",
                    "HitReact": "Velociraptor_Idle", "Death": "Velociraptor_Death", "Yes": "Velociraptor_Jump"})


def dress(C, D):
    C.palette(quill="b8301a", claw="1a1008")
    C.plan, C.attack = "biped", "bite"
    for k, (bone, t, h) in enumerate([("Head", 0.2, 0.1), ("Neck", 0.9, 0.12), ("Neck", 0.4, 0.13), ("Shoulders", 0.5, 0.12),
                                      ("Torso", 0.5, 0.1), ("Hips", 0.5, 0.08)]):
        top = D.top(bone, t) - V((0, 0, 0.01))
        C.cone(f"Quill{k}", tuple(top), tuple(top + V((0, 0.07, h))), 0.022, "quill", bone, segs=4)
