# Writes the "Legends & Grudges" batch (2026-11-25): Drain on-play leeches, cards that grow
# with the game (EffectData.scale, core/scaling.gd), "whenever a creature dies" creatures,
# and eight new legendaries.
#   python3 tools/data/gen_legends_cards.py data/cards
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import gen_dark_moon_cards as g
from gen_dark_moon_cards import e, card, M, E, C, F, N, D, CR, SP

g.OUT = sys.argv[1] if len(sys.argv) > 1 else "data/cards"
g.SN = g.SN + ("scale",)
g.INT = g.INT + ("scale_per",)

CARDS = [
    # --- Drain (leech on play)
    card("bog_biter", "Bog Biter", CR, M, 2, 2, 2, tribe="beast", effects=[e("on_play", "drain", 1, "opposing")]),
    card("bloodbow_ranger", "Bloodbow Ranger", CR, N, 3, 2, 3, tribe="spirit", effects=[e("on_play", "drain", 2, "opposing")]),
    card("nocturna_velvet_queen", "Nocturna, Velvet Queen", CR, N, 6, 3, 5, level=2, tribe="flyer", legendary=True,
         effects=[e("on_play", "drain", 2, "all_enemy_creatures")]),

    # --- Whenever a creature dies
    card("carrion_hound", "Carrion Hound", CR, M, 3, 2, 3, tribe="beast", effects=[e("on_any_death", "buff", 1, "self", amount2=1)]),
    card("mawra_grave_glutton", "Mawra, the Grave Glutton", CR, N, 5, 1, 2, level=2, tribe="beast", legendary=True,
         effects=[e("on_any_death", "double_stats", 0, "self")]),
    card("the_rot_king", "The Rot King", CR, M, 6, 4, 5, level=2, tribe="spirit", legendary=True,
         effects=[e("on_play", "damage", 1, "all_enemy_creatures"), e("on_any_death", "buff", 2, "self", amount2=2)]),

    # --- Grudges: grow each time your hero was hurt
    card("grudge_bolt", "Grudge Bolt", SP, E, 2, effects=[e("on_play", "damage", 1, "chosen_creature", scale="hero_hits")]),
    card("vexa_grudgekeeper", "Vexa, the Grudgekeeper", CR, E, 7, 5, 5, level=3, tribe="spirit", legendary=True,
         effects=[e("on_play", "damage", 1, "enemy_hero", scale="hero_hits")]),
    card("last_stand", "Last Stand", SP, N, 4, effects=[e("on_play", "armour", 3, scale="hero_hits")]),

    # --- Armour turned into damage
    card("shield_bash", "Shield Bash", SP, D, 1, effects=[e("on_play", "damage", 0, "chosen_enemy_creature", scale="armour")]),
    card("bastion_last_wall", "Bastion, the Last Wall", CR, D, 6, 3, 7, level=2, tribe="beast", kw=["sturdy"], legendary=True,
         effects=[e("on_play", "armour", 4), e("on_play", "damage", 0, "chosen_enemy_creature", scale="armour")]),

    # --- Other growers
    card("sugar_hoarder", "Sugar Hoarder", CR, C, 4, 2, 2, level=2, tribe="flyer", effects=[e("on_play", "buff", 0, "self", scale="hand")]),
    card("duchess_bonbonpaw", "Duchess Bonbonpaw", CR, C, 7, 4, 4, level=3, tribe="beast", legendary=True,
         effects=[e("on_play", "add_to_hand", 2, card_id="sweet_treat"), e("on_play", "buff", 0, "self", scale="hand")]),
    card("grand_fence", "Grand Fence", CR, D, 4, 3, 3, level=2, tribe="spirit", effects=[e("on_play", "steal_hand", 1), e("on_play", "buff", 0, "self", scale="stolen")]),
    card("snowball", "Snowball", SP, F, 2, effects=[e("on_play", "damage", 1, "chosen_creature", scale="spells")]),
    card("hailmother_ysra", "Hailmother Ysra", CR, F, 8, 5, 6, level=3, tribe="spirit", legendary=True,
         effects=[e("start_of_turn", "split_damage", 0, scale="self_atk")]),
    card("pyrrhos_spellstorm", "Pyrrhos, Spellstorm Stallion", CR, E, 8, 6, 6, level=3, tribe="beast", legendary=True,
         effects=[e("on_play", "split_damage", 0, scale="spells")]),
    card("mourning_toll", "Mourning Toll", SP, M, 6, effects=[e("on_play", "damage", 0, "all_enemy_creatures", scale="own_deaths")]),
]

if __name__ == "__main__":
    for c in CARDS:
        g.write(c)
    print("wrote", len(CARDS), "cards")
