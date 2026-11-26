"""Snow Pup (Frost Peaks, 2): a frost-hound pup, white fur with ice-blue frost cracks, cold blue eyes and a
tail that ends in a plume of freezing mist. Built like Cinderpup, in frost."""
from forge.creatures import cinderpup


def build(C):
    C.palette(fur="eef4fa", fur2="b8c8d8", crack="5ad8ff", eye="8af4ff", nose="1a2a3a", fire="aef4ff", hot="ffffff",
              fang="ffffff")
    cinderpup.build(C)
