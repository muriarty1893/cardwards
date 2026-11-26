"""Shiba Shepherd (Dark Moon, 4): a stout guardian hound who herds lost dreams home. Dressed from
Quaternius's CC0 Shiba Inu: russet coat and cream mask, a night-blue mantle over its shoulders clasped
with a moon brooch, and a shepherd's lantern hanging from its collar."""
from mathutils import Vector as V

DRESS = dict(src="shiba", height=0.95, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "c8642a", "Main_Light": "fff0d8"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack", "HitReact": "Idle_HitReact_Left", "Death": "Death", "Yes": "Idle_2"})


def dress(C, D):
    C.palette(mantle="1a2a5a", trim="d8c8ff", moon="f0f4ff", lamp="ffe08a", metal="8a8aa0")
    t = D.top("Torso3", 0.5)
    for k, (dy, w, l) in enumerate([(0.0, 0.2, 0.2), (0.12, 0.19, 0.16)]):
        C.ellipsoid(f"Mantle{k}", tuple(t + V((0, dy, -0.05))), (w, l, 0.09), "mantle", "Torso3")
    C.ellipsoid("MantleTrim", tuple(t + V((0, -0.16, -0.06))), (0.19, 0.035, 0.07), "trim", "Torso3")
    n = D.at("Neck1", 0.2)
    C.ellipsoid("Brooch", tuple(n + V((0, -0.08, -0.02))), (0.03, 0.012, 0.03), "moon", "Neck1")
    C.tube("LampHook", [n + V((0, -0.08, -0.05)), n + V((0, -0.1, -0.14))], [0.005, 0.005], "metal", "Neck1")
    C.ellipsoid("Lantern", tuple(n + V((0, -0.1, -0.18))), (0.035, 0.035, 0.045), "lamp", "Neck1")
