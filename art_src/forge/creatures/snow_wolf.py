"""Snow Wolf (Frost Peaks, 3): a gaunt white wolf of the high passes. Dressed from Quaternius's CC0 Wolf:
a white coat, frost-blue eyes and a mane of jagged ice shards."""
from forge.creatures.taffy_wolf_matron import mane

DRESS = dict(src="wolf", height=1.05, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "dfe8f0", "Main_Light": "ffffff", "Nose": "1a2430", "Eyes_Black": "3ad8ff"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack", "HitReact": "Idle_HitReact_Left", "Death": "Death", "Yes": "Idle_2"})


def dress(C, D):
    C.palette(shard="7ad8ff", shard2="e0f8ff")
    mane(C, D, "shard", "shard2")
