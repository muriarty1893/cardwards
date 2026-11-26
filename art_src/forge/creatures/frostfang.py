"""Frostfang (Frost Peaks, 3): a sabre-toothed ice cat, pale blue-grey coat flecked with frost, a frost
mark on the brow, mist trailing from shoulders and tail, and two long icicle sabres. Built on the Moonlit
Stalker's body."""
from forge.creatures import moonlit_stalker


def build(C):
    C.palette(fur="8a9ab0", fur2="5a6a80", moon="e0faff", eye="3ad8ff", star="ffffff", wisp="cfeaff", claw="ffffff",
              mouth="2a3a5a", sabre="f0fcff")
    moonlit_stalker.build(C, sabres=True)
