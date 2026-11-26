"""Snow Wolf (Frost Peaks, 3): a gaunt white wolf of the high passes, a mane of jagged ice shards, frost-
blue eyes and fangs like icicles. Built like the Taffy Wolf Matron, in ice."""
from forge.creatures import taffy_wolf_matron


def build(C):
    C.palette(taffy="dfe8f0", cream="ffffff", shard="7ad8ff", shard2="e0f8ff", fang="ffffff", eye="3ad8ff",
              dark="2a3a4a", nose="1a2430")
    taffy_wolf_matron.build(C)
