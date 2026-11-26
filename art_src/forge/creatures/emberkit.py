"""Emberkit (Ember Flats, 2): a sly fire fox kit. Dressed from Quaternius's CC0 Fox (proper anatomy and
animation): ember-orange fur with a cream chest and soot-black legs, glowing ember eyes, two more bushy
tails fanned out beside its own, and all three burning at the tips."""
import math
from mathutils import Vector as V
from forge import props

DRESS = dict(src="fox", height=0.85, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "e8682a", "Main_Light": "fff0d8", "Black": "2a1a14", "Grey": "3a2418", "Eyes": "ffe23a"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack", "HitReact": "Idle_HitReact_Left", "Death": "Death", "Yes": "Idle_2"})


def dress(C, D):
    C.palette(fur="e8682a", tip="ffd03a", fire_m="ff6a1a", hot="ffd03a")
    tb = D.last("Tail")
    root, tip = D.at("Tail1", 0.0), D.at(tb, 1.0)
    for k, a in enumerate((-35, 35)):
        r = math.radians(a)
        d = tip - root
        d = V((d.x * math.cos(r) - d.y * math.sin(r), d.x * math.sin(r) + d.y * math.cos(r), d.z))
        pts = [root, root + d * 0.35 + V((0, 0, 0.06)), root + d * 0.75 + V((0, 0, 0.08)), root + d]
        C.tube(f"Tail{k}", pts, [0.03, 0.06, 0.05, 0.015], "fur", "Tail1")
        props.flame(C, tuple(root + d), 0.11, "Tail1", "fire_m", "hot", n=3, lean=tuple(d.normalized() * 0.5), name=f"TailFire{k}")
    props.flame(C, tuple(tip), 0.12, tb, "fire_m", "hot", n=3, lean=(0, 0.3, 0.3), name="TailFireMain")
