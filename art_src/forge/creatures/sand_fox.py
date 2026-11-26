"""Sand Fox (Sunny Dunes, 2): a lean fennec raider. Dressed from Quaternius's CC0 Fox: pale gold fur, dark
desert-hunter eyes, enormous fennec ears and a black-tipped brush of a tail."""
from mathutils import Vector as V

DRESS = dict(src="fox", height=0.8, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "e8c07a", "Main_Light": "fff4e0", "Black": "8a6a3a", "Grey": "c8a060", "Eyes": "2a1a08"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack", "HitReact": "Idle_HitReact_Left", "Death": "Death", "Yes": "Idle_2"})


def dress(C, D):
    C.palette(fur="e8c07a", inner="fff0d8", tip="1a1208")
    for side, sx in (("L", 1), ("R", -1)):
        b = D.at(f"Ear1.{side}", 0.0)
        t = D.at(D.last(f"Ear") if False else f"Ear4.{side}", 1.0)
        d = (t - b)
        C.cone(f"BigEar{side}", tuple(b), tuple(b + d * 1.9), 0.075, "fur", f"Ear1.{side}", segs=6, smooth=True)
        C.cone(f"BigEarIn{side}", tuple(b + V((0, -0.01, 0.0))), tuple(b + d * 1.7 + V((0, -0.01, 0))), 0.05, "inner",
               f"Ear1.{side}", segs=6, smooth=True)
    tb = D.last("Tail")
    C.ellipsoid("TailTip", tuple(D.at(tb, 0.85)), (0.05, 0.07, 0.05), "tip", tb)
