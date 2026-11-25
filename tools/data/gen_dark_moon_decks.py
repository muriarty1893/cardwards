# Writes the deck .tres files for the Dark Moon expansion (5 reworked starter decks + Moonlit Bandits).
#   python3 tools/data/gen_dark_moon_decks.py
M, E, C, F, D = 0, 1, 2, 3, 5
DECKS = {
    "grove_guard": ("Grove Guard", [M, M, F, M], {
        "sporeling": 2, "mossback": 2, "glimmer_morel": 2, "rootstalker": 1, "elder_shroomhulk": 2, "spore_hut": 2,
        "rain_of_spores": 2, "snowmite": 1, "iceling": 2, "ice_wall": 1, "cold_snap": 1, "spore_bloom": 1, "barkbeetle": 2,
        "thorn_lash": 1, "deep_roots": 1,
        "grave_toad": 2, "spore_drifter": 2, "mycel_gravekeeper": 1, "moss_ape_matriarch": 1, "fungal_feast": 1}),
    "blaze_rush": ("Blaze Rush", [E, E, C, E], {
        "cinderpup": 2, "flarebeak": 2, "magmaw": 2, "blazehorn": 1, "inferno_drake": 2, "kiln_tower": 1, "fireball": 2,
        "ember_rain": 1, "gumdrop": 2, "lollibat": 1, "sugar_shack": 1, "volcano": 1, "emberkit": 2, "stoke": 1, "hot_head": 1,
        "ember_hornet": 2, "cinder_barrage": 2, "firestorm": 1, "magma_chieftain": 1, "overcharge": 1, "kindle_pups": 1}),
    "sugar_storm": ("Sugar Storm", [C, C, M, C], {
        "gumdrop": 2, "taffy_snail": 2, "lollibat": 1, "sugar_sprite": 2, "jellywobble": 1, "bonbon_behemoth": 1,
        "sugar_shack": 1, "candy_mill": 1, "sugar_rush": 2, "sporeling": 2, "mossback": 1, "rain_of_spores": 1,
        "cotton_puff": 2, "jawbreaker": 2,
        "sprinkle_sprite": 1, "gumdrop_baker": 2, "bakery_rush": 1, "sugar_shiv": 1, "taffy_wolf_matron": 1, "cookie_jar": 1, "twinstripe_peppermare": 1, "party_favors": 1}),
    "deep_freeze": ("Deep Freeze", [F, F, E, F], {
        "iceling": 2, "frostfang": 2, "glacier_tortoise": 2, "rimewing": 1, "blizzard_titan": 2, "ice_wall": 1,
        "cold_snap": 2, "avalanche": 1, "cinderpup": 2, "fireball": 2, "snowstorm": 1, "snow_pup": 1, "icicle": 2,
        "rime_dart": 2, "snowdrift_sage": 2, "glacier_shark": 1, "blizzard_echo": 1, "hoarfrost": 1, "tundra_stomper": 1, "permafrost": 1}),
    "sun_fortress": ("Sun Fortress", [D, D, M, D], {
        "sand_scuttler": 2, "meerkeep": 2, "sand_fox": 2, "sun_scarab": 2, "dune_raptor": 1, "sandwraith": 2,
        "oasis_alpaca": 2, "lamp_djinn": 1, "sun_obelisk": 2, "sandstone_watchtower": 1, "sun_shield": 2, "sandstorm": 1,
        "sporeling": 2, "mossback": 2,
        "caravan_master": 1, "mirage_army": 1, "sand_pickpocket": 2, "twin_guardians": 1, "dune_leviathan": 1}),
    "moonlit_bandits": ("Moonlit Bandits", [D, D, E, D], {
        "sand_pickpocket": 2, "dune_bandit": 2, "alpaking_thief_king": 1, "sandglider_sphinx": 1, "caravan_master": 1,
        "dune_leviathan": 1, "swindle": 1, "lure_of_gold": 1, "grand_heist": 1, "hex_of_the_dunes": 1, "sand_fox": 2,
        "sand_scuttler": 2, "dark_moon": 1, "shadow_peddler": 2, "ember_hornet": 2, "cinder_barrage": 2,
        "sandwraith": 2, "sun_scarab": 2, "dusk_wasp": 2, "meerkeep": 1}),
}


def write(did, name, lands, counts):
    assert sum(counts.values()) == 30, (did, sum(counts.values()))
    ids = list(counts)
    lines = ['[gd_resource type="Resource" script_class="DeckData" format=3]', '',
             '[ext_resource type="Script" path="res://core/deck_data.gd" id="1_deck"]']
    for i, cid in enumerate(ids):
        lines.append('[ext_resource type="Resource" path="res://data/cards/%s.tres" id="%d_%s"]' % (cid, i + 2, cid))
    refs = []
    for i, cid in enumerate(ids):
        refs += ['ExtResource("%d_%s")' % (i + 2, cid)] * counts[cid]
    lines += ['', '[resource]', 'script = ExtResource("1_deck")', 'id = &"%s"' % did, 'display_name = "%s"' % name,
              'lands = Array[int]([%s])' % ", ".join(map(str, lands)), 'cards = Array[Resource]([%s])' % ", ".join(refs)]
    open("data/decks/%s.tres" % did, "w").write("\n".join(lines) + "\n")


for did, (name, lands, counts) in DECKS.items():
    write(did, name, lands, counts)
print("wrote", len(DECKS), "decks")
