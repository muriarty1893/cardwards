"""Glacier Tortoise (Frost Peaks, 3): an ancient tortoise carrying a glacier on its back, the shell a
dome of packed snow and blue ice, crystal spires where ferns would grow, frost-rimed stubby legs.
Built like Mossback, in ice."""
from forge.creatures import mossback


def build(C):
    C.palette(skin="6a8aa0", shell="cfe0f0", rock="7ab8e0", moss="ffffff", moss2="e8f4ff", fern="9ee8ff",
              beak="d8e0e8", eye="3ad8ff", dark="0a1a2a", flower="aef4ff")
    mossback.build(C)
