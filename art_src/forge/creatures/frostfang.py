"""Frostfang (Frost Peaks, 3): a sabre-toothed ice cat, pale blue-grey coat flecked with frost, a frost
mark on the brow, mist trailing from shoulders and tail, and two long icicle sabres. Built on the Moonlit
Stalker's body."""
from forge.creatures import moonlit_stalker


def build(C):
    C.palette(fur="8a9ab0", fur2="5a6a80", moon="e0faff", eye="3ad8ff", star="ffffff", wisp="cfeaff", claw="ffffff",
              mouth="2a3a5a", sabre="f0fcff")
    moonlit_stalker.build(C)
    at = C.at
    for mx in (-1, 1):
        C.cone(f"Sabre{mx}", at("snout", 0.055, -0.05, -0.04, mx), at("snout", 0.06, -0.08, -0.3, mx), 0.03, "sabre",
               "head", segs=6, smooth=True)
