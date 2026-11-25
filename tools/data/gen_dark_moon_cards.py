# Writes the Dark Moon expansion's card .tres files (spec docs/superpowers/specs/2026-11-25-dark-moon-design.md).
#   python3 tools/data/gen_dark_moon_cards.py data/cards
import os, sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "data/cards"
M, E, C, F, N, D = 0, 1, 2, 3, 4, 5      # lands (N = Neutral)
CR, BU, SP = 0, 1, 2                     # kinds
INT = ("amount", "amount2", "filter_kind", "filter_land", "need")
SN = ("when", "op", "who", "keyword", "cond", "card_id", "tribe", "need_cond")


def e(when, op, amount=0, who="own_hero", **kw):
    d = dict(when=when, op=op, amount=amount, who=who)
    d.update(kw)
    return d


def card(id, name, kind, land, cost, atk=0, hp=0, level=None, kw=(), tribe="", sp=0, field=False,
         effects=(), legendary=False, curse=False, allows_40=False, follower="", collectible=True, deck_legal=True, note=""):
    return dict(id=id, name=name, kind=kind, land=land, cost=cost, atk=atk, hp=hp,
                level=(level if level is not None else (1 if kind == CR else 0)), kw=list(kw), tribe=tribe, sp=sp,
                field=field, effects=list(effects), legendary=legendary, curse=curse, allows_40=allows_40,
                follower=follower, collectible=collectible, deck_legal=deck_legal, note=note)


def write(c):
    lines = ['[gd_resource type="Resource" script_class="CardData" format=3]', '',
             '[ext_resource type="Script" path="res://core/card_data.gd" id="1_card"]',
             '[ext_resource type="Script" path="res://core/effect_data.gd" id="2_eff"]', '']
    subs = []
    for i, ef in enumerate(c["effects"]):
        rid = "eff_%s_%d" % (c["id"], i)
        subs.append(rid)
        lines.append('[sub_resource type="Resource" id="%s"]' % rid)
        lines.append('script = ExtResource("2_eff")')
        for k in SN:
            if k in ef and ef[k] != "":
                lines.append('%s = &"%s"' % (k, ef[k]))
        for k in INT:
            if k in ef:
                lines.append('%s = %d' % (k, ef[k]))
        for k in ("combo", "gift"):
            if ef.get(k):
                lines.append('%s = true' % k)
        lines.append('')
    lines += ['[resource]', 'script = ExtResource("1_card")', 'id = &"%s"' % c["id"], 'display_name = "%s"' % c["name"],
              'kind = %d' % c["kind"], 'land = %d' % c["land"], 'level = %d' % c["level"], 'cost = %d' % c["cost"]]
    if c["kind"] == CR:
        lines += ['attack = %d' % c["atk"], 'health = %d' % c["hp"]]
    if c["kw"]:
        lines.append('keywords = Array[StringName]([%s])' % ", ".join('&"%s"' % k for k in c["kw"]))
    if c["sp"]:
        lines.append('spell_power = %d' % c["sp"])
    if c["tribe"]:
        lines.append('tribe = &"%s"' % c["tribe"])
    if c["field"]:
        lines.append('field = true')
    if subs:
        lines.append('effects = Array[ExtResource("2_eff")]([%s])' % ", ".join('SubResource("%s")' % r for r in subs))
    if not c["collectible"]:
        lines.append('collectible = false')
    for k in ("legendary", "curse", "allows_40"):
        if c[k]:
            lines.append('%s = true' % k)
    if not c["deck_legal"]:
        lines.append('deck_legal = false')
    if c["note"]:
        lines.append('rules_note = "%s"' % c["note"])
    if c["follower"]:
        lines.append('follower_id = &"%s"' % c["follower"])
    with open(os.path.join(OUT, c["id"] + ".tres"), "w") as f:
        f.write("\n".join(lines) + "\n")


CARDS = [
    # --- Dark Moon (Neutral legendary) and its two direction choices
    card("dark_moon", "Dark Moon", SP, N, 4, effects=[e("on_play", "dark_moon")], legendary=True),
    card("moon_left", "Wane Left", SP, N, 0, collectible=False, deck_legal=False, note="Every creature moves to the next occupied land on its left, around the board."),
    card("moon_right", "Wax Right", SP, N, 0, collectible=False, deck_legal=False, note="Every creature moves to the next occupied land on its right, around the board."),

    # --- Mushroom Forest: Last Breath and deaths
    card("spore_drifter", "Spore Drifter", CR, M, 1, 1, 2, tribe="flyer",
         effects=[e("on_destroyed", "summon", 1, "self", card_id="sporeling")]),
    card("grave_toad", "Grave Toad", CR, M, 4, 4, 4, level=2, tribe="beast",
         effects=[e("on_destroyed", "damage", 2, "all_enemy_creatures")]),
    card("moss_ape_matriarch", "Moss Ape Matriarch", CR, M, 6, 5, 6, level=2, tribe="beast", follower="leaf_finch"),
    card("mycel_gravekeeper", "Mycel the Gravekeeper", CR, M, 5, 3, 6, level=2, tribe="sprout", legendary=True,
         effects=[e("aura", "echo_death", 0, "self")]),
    card("mycelia_spore_weaver", "Mycelia, Spore Weaver", CR, M, 9, 7, 9, level=3, tribe="sprout", legendary=True,
         effects=[e("on_destroyed", "resurrect", 4, "self", keyword="last_breath")]),
    card("ancient_hollowneck", "Ancient Hollowneck", CR, M, 10, 9, 10, level=3, tribe="beast",
         effects=[e("on_play", "summon", 3, "own_hero", card_id="sporeling")]),
    card("fungal_feast", "Fungal Feast", SP, M, 2, effects=[e("on_play", "destroy", 0, "chosen_own_creature"), e("on_play", "draw", 2)]),
    card("mycelium_call", "Mycelium Call", SP, M, 5, effects=[e("on_play", "summon", 3, card_id="sporeling")]),
    card("rot_harvest", "Rot Harvest", SP, M, 7, effects=[e("in_hand", "cost_per_death", 1), e("on_play", "damage", 3, "all_creatures")]),
    card("grave_bloom", "Grave Bloom", SP, M, 3, effects=[e("on_play", "resurrect", 1, "own_hero")]),
    card("necrospore", "Necrospore", SP, M, 4, effects=[e("on_play", "damage", 2, "all_creatures"),
                                                    e("on_play", "draw", 2, need_cond="deaths_at_least:4")]),
    card("spore_burst", "Spore Burst", SP, M, 1, effects=[e("on_play", "damage", 1, "all_creatures")]),

    # --- Ember Flats: split damage and burn
    card("ember_hornet", "Ember Hornet", CR, E, 2, 2, 2, tribe="flyer", effects=[e("on_play", "split_damage", 2)]),
    card("flame_tiki", "Flame Tiki", CR, E, 3, 2, 4, tribe="spirit", sp=1, effects=[e("on_boop", "split_damage", 2)]),
    card("ignis_ember_storm", "Ignis, the Ember Storm", CR, E, 9, 6, 6, level=3, tribe="flyer", legendary=True,
         effects=[e("on_play", "split_damage", 8), e("on_play", "split_damage", 8, need_cond="spells_of_land_at_least:1:5")]),
    card("cinder_fiend", "Cinder Fiend", CR, E, 7, 6, 5, level=3, tribe="spirit", sp=2, legendary=True,
         effects=[e("on_play", "next_spell_twice", 1)]),
    card("magma_chieftain", "Magma Chieftain", CR, E, 6, 5, 5, level=2, tribe="beast", follower="cinderpup"),
    card("molten_titan", "Molten Titan", CR, E, 10, 10, 10, level=3, tribe="beast", effects=[e("on_play", "damage", 3, "all_enemy_creatures")]),
    card("firestorm", "Firestorm", SP, E, 5, effects=[e("on_play", "split_damage", 6)]),
    card("cinder_barrage", "Cinder Barrage", SP, E, 2, effects=[e("on_play", "split_damage", 3)]),
    card("overcharge", "Overcharge", SP, E, 1, effects=[e("on_play", "next_spell_twice", 1)]),
    card("hex_of_cinders", "Hex of Cinders", SP, E, 2, effects=[e("on_play", "shuffle_into_deck", 2, "enemy_hero", card_id="smolder"),
                                                        e("on_play", "damage", 2, "enemy_hero")]),
    card("smolder", "Smolder", SP, E, 0, curse=True, collectible=False, deck_legal=False, effects=[e("on_draw", "damage", 3, "own_hero")]),
    card("lava_wave", "Lava Wave", SP, E, 3, effects=[e("on_play", "damage", 2, "all_enemy_creatures"),
                                                  e("on_play", "damage", 2, "enemy_hero", need_cond="holding_land:1")]),
    card("kindle_pups", "Kindle Pups", SP, E, 3, effects=[e("on_play", "summon", 2, card_id="cinderpup")]),

    # --- Candy Hills: hand buffs and card makers
    card("sprinkle_sprite", "Sprinkle Sprite", CR, C, 1, 1, 1, tribe="flyer", effects=[e("on_play", "buff_hand", 1, amount2=1)]),
    card("gumdrop_baker", "Gumdrop Baker", CR, C, 3, 2, 4, tribe="blob", effects=[e("on_play", "add_to_hand", 2, card_id="sweet_treat")]),
    card("bonbon_unicorn_queen", "Bonbon Unicorn Queen", CR, C, 7, 5, 7, level=2, tribe="beast", legendary=True,
         effects=[e("on_play", "summon", 3, card_id="taffy_snail", need_cond="start_no_dupes")]),
    card("twinstripe_peppermare", "Twinstripe Peppermare", CR, C, 5, 3, 5, level=2, tribe="beast", legendary=True,
         effects=[e("aura", "echo", 0, "self")]),
    card("taffy_wolf_matron", "Taffy Wolf Matron", CR, C, 6, 5, 6, level=2, tribe="beast", follower="gummy_cub"),
    card("cakequake_behemoth", "Cakequake Behemoth", CR, C, 9, 8, 9, level=3, tribe="beast", effects=[e("on_play", "buff_hand", 2, amount2=2)]),
    card("bakery_rush", "Bakery Rush", SP, C, 2, effects=[e("on_play", "buff_hand", 2, amount2=2)]),
    card("cookie_jar", "Cookie Jar", SP, C, 2, effects=[e("on_play", "add_to_hand", 3, card_id="sweet_treat")]),
    card("sweet_treat", "Sweet Treat", SP, C, 0, collectible=False, deck_legal=False, effects=[e("on_play", "heal", 3)]),
    card("cavity_hex", "Cavity Hex", SP, C, 1, effects=[e("on_play", "add_to_hand", 2, "enemy_hero", card_id="toothache")]),
    card("toothache", "Toothache", SP, C, 1, curse=True, collectible=False, deck_legal=False, effects=[e("on_play", "damage", 1, "own_hero")]),
    card("party_favors", "Party Favors", SP, C, 3, effects=[e("on_play", "add_to_hand", 1, card_id="sweet_treat"), e("on_play", "buff_hand", 1, amount2=1)]),
    card("gumdrop_parade", "Gumdrop Parade", SP, C, 4, effects=[e("on_play", "summon", 2, card_id="gumdrop")]),

    # --- Frostpeak: spell replays and holding Frost
    card("snowdrift_sage", "Snowdrift Sage", CR, F, 3, 2, 4, tribe="spirit", sp=1, effects=[e("on_play", "draw", 1, need_cond="holding_land:3")]),
    card("glacier_shark", "Glacier Shark", CR, F, 5, 5, 5, level=2, tribe="beast", effects=[e("on_play", "freeze", 0, "opposing", need_cond="holding_land:3")]),
    card("aurora_skywhale", "Aurora Skywhale", CR, F, 10, 7, 9, level=3, tribe="flyer", legendary=True,
         effects=[e("on_play", "replay_spells", 0, filter_land=F, need_cond="max_magic_at_least:10")]),
    card("glacial_archmage", "Glacial Archmage", CR, F, 7, 5, 7, level=3, tribe="spirit", sp=1, legendary=True,
         effects=[e("on_play", "next_spell_twice", 2)]),
    card("tundra_stomper", "Tundra Stomper", CR, F, 7, 6, 7, level=2, tribe="beast", follower="snow_pup"),
    card("rimeback_stegosaur", "Rimeback Stegosaur", CR, F, 9, 8, 9, level=3, tribe="beast", effects=[e("on_play", "freeze", 0, "all_enemy_creatures")]),
    card("rime_dart", "Rime Dart", SP, F, 1, effects=[e("on_play", "damage", 2, "chosen_enemy_creature"), e("on_play", "freeze", 0, "same_target")]),
    card("hoarfrost", "Hoarfrost", SP, F, 2, effects=[e("on_play", "draw", 1), e("on_play", "draw", 1, need_cond="holding_land:3")]),
    card("blizzard_echo", "Blizzard Echo", SP, F, 3, effects=[e("on_play", "freeze", 0, "all_enemy_creatures"),
                                                          e("on_play", "damage", 2, "all_enemy_creatures", need_cond="spells_of_land_at_least:3:3")]),
    card("permafrost", "Permafrost", SP, F, 6, effects=[e("on_play", "damage", 3, "all_enemy_creatures"), e("on_play", "freeze", 0, "all_enemy_creatures")]),
    card("snow_call", "Snow Call", SP, F, 4, effects=[e("on_play", "summon", 2, card_id="iceling")]),

    # --- Sunny Dunes: thieves
    card("sand_pickpocket", "Sand Pickpocket", CR, D, 2, 2, 2, tribe="blob", effects=[e("on_play", "copy_rival", 1)]),
    card("dune_bandit", "Dune Bandit", CR, D, 3, 3, 3, tribe="spirit", effects=[e("on_play", "steal_hand", 1, combo=True)]),
    card("alpaking_thief_king", "Alpaking, Thief King", CR, D, 8, 6, 7, level=3, tribe="beast", legendary=True,
         effects=[e("on_play", "steal_hand", 2, amount2=1)]),
    card("sandglider_sphinx", "Sandglider Sphinx", CR, D, 6, 5, 5, level=2, tribe="flyer", legendary=True,
         effects=[e("on_play", "steal_creature", 4, "chosen_enemy_creature")]),
    card("caravan_master", "Caravan Master", CR, D, 6, 5, 6, level=2, tribe="beast", follower="sand_fox"),
    card("dune_leviathan", "Dune Leviathan", CR, D, 9, 8, 9, level=3, tribe="beast", kw=["sturdy"], effects=[e("on_play", "steal_hand", 1)]),
    card("swindle", "Swindle", SP, D, 2, effects=[e("on_play", "copy_rival", 2)]),
    card("lure_of_gold", "Lure of Gold", SP, D, 4, effects=[e("on_play", "steal_creature", 2, "chosen_enemy_creature")]),
    card("hex_of_the_dunes", "Hex of the Dunes", SP, D, 2, effects=[e("on_play", "shuffle_into_deck", 3, "enemy_hero", card_id="cursed_coin")]),
    card("cursed_coin", "Cursed Coin", SP, D, 0, curse=True, collectible=False, deck_legal=False, effects=[e("on_draw", "damage", 2, "own_hero")]),
    card("grand_heist", "Grand Heist", SP, D, 5, effects=[e("on_play", "steal_hand", 2)]),
    card("mirage_army", "Mirage Army", SP, D, 5, effects=[e("on_play", "summon", 3, card_id="sand_scuttler")]),

    # --- Neutral (any deck)
    card("gluttonous_dreamer", "Gluttonous Dreamer", CR, N, 6, 6, 6, tribe="beast", legendary=True, allows_40=True,
         effects=[e("on_play", "buff_hand", 2, amount2=2, need_cond="start_40"), e("on_play", "draw", 2, need_cond="start_40")]),
    card("shadow_peddler", "Shadow Peddler", CR, N, 3, 2, 3, tribe="spirit", effects=[e("on_play", "dream_up", 0, gift=True)]),
    card("shiba_shepherd", "Shiba Shepherd", CR, N, 4, 3, 4, tribe="beast", follower="cotton_puff"),
    card("sleeper_beneath", "The Sleeper Beneath", CR, N, 10, 12, 12, tribe="flyer", legendary=True, effects=[e("in_hand", "cost_per_death", 1)]),
    card("herald_of_the_sleeper", "Herald of the Sleeper", CR, N, 3, 2, 3, tribe="blob",
         effects=[e("on_play", "buff", 2, "self", amount2=2, need_cond="started_with:sleeper_beneath"),
                  e("on_play", "give_keyword", 0, "same_target", keyword="guard", need_cond="started_with:sleeper_beneath")]),
    card("moonlit_stalker", "Moonlit Stalker", CR, N, 4, 4, 3, tribe="spirit", kw=["hidden"], effects=[e("on_destroyed", "dream_up", 0, gift=True)]),
    card("dusk_wasp", "Dusk Wasp", CR, N, 2, 2, 1, tribe="flyer", kw=["dash"], effects=[e("on_destroyed", "split_damage", 2)]),
    card("moon_guppy", "Moon Guppy", CR, N, 2, 1, 2, tribe="blob", effects=[e("on_play", "grow_magic", 1)]),
    card("night_market", "Night Market", SP, N, 2, effects=[e("on_play", "dream_up", 0, gift=True)]),
    card("bad_dream", "Bad Dream", SP, N, 3, effects=[e("on_play", "shuffle_into_deck", 2, "enemy_hero", card_id="nightmare"), e("on_play", "draw", 1)]),
    card("nightmare", "Nightmare", SP, N, 0, curse=True, collectible=False, deck_legal=False,
         effects=[e("on_draw", "damage", 3, "own_hero"), e("on_draw", "draw", 1)]),
    card("lullaby", "Lullaby", SP, N, 2, effects=[e("on_play", "hush", 0, "chosen_enemy_creature"), e("on_play", "draw", 1)]),
    card("shooting_stars", "Shooting Stars", SP, N, 3, effects=[e("on_play", "split_damage", 4)]),
    card("moon_elixir", "Moon Elixir", SP, N, 3, effects=[e("on_play", "double_stats", 0, "chosen_own_creature")]),
    card("moonwell", "Moonwell", SP, N, 3, effects=[e("on_play", "grow_magic", 2)]),
    card("twin_guardians", "Twin Guardians", SP, N, 3, effects=[e("on_play", "summon", 2, card_id="mossback")]),
]

if __name__ == "__main__":
    for c in CARDS:
        write(c)
    print("wrote", len(CARDS), "cards")
