"""Dusk Wasp (Dark Moon, 2): the hornet's night cousin, violet-black chitin banded with moonlight, pale
glassy wings, a long silver stinger and cold white eyes. Same build as Ember Hornet, its own colours."""
from forge.creatures import ember_hornet


def build(C):
    # colours set first win: ember_hornet.build's palette() keeps these
    C.palette(chitin="1a1028", stripe="c8c8ff", hot="f0f4ff", wing="8a7ad8", eye="e8f0ff", leg="2a1a3a")
    ember_hornet.build(C)
    C.cone("Stinger2", (0, 1.05, 0.3), (0, 1.25, 0.08), 0.03, "hot", "tail2", segs=6)
