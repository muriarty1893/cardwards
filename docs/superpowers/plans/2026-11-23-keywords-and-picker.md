# Keywords, Dream Up picker and loose ends — plan

Spec: `docs/superpowers/specs/2026-11-23-keywords-and-picker-design.md`. Branch `feat/keywords-picker`.
Execution: native, self-approved per the user's standing instruction (design approved in chat).
Ledger: `.superpowers/sdd/2026-11-23-keywords-picker/progress.md`.

Suite: `bash -c 'set -o pipefail; timeout 1500 godot --headless --path . --script res://tests/run_tests.gd 2>&1 | grep -E "^(Results|ERROR: FAIL)"'`
Single file: add `-- --only=<name>`. After any change to `core/*.gd`: `godot --headless --path . --script res://tools/stamp_rules.gd`.

Each task: failing test → implement → targeted tests → commit. Full suite at stage ends.

## Stage A: rules and small fixes

1. **40 life** — `core/game_state.gd` START_HP/MAX_HP 40; HUD initial label; update tests that
   hard-code 25 (test_turns, test_cards, test_effects_ops, test_keywords, test_combat,
   test_tribes, test_armour); restamp. Quick balance sim (tools/deck_balance.gd) recorded in ledger.
2. **Glyph icons** — heart / swords / star SVGs; `card_widget._gem` takes an icon texture;
   HUD hero HP shows a heart icon + number; `CreatureView.heart()` uses a Sprite3D; flying_card star
   uses an icon. Test: no "♥", "⚔", "✦" left in view/menus scripts; icons load.
3. **Online panel gap** — `menus/online_panel.gd`: the status row collapses when empty. Test on
   the panel's idle height / the row's visibility.
4. **Room creation limit** — `server/src/gate.ts` (Durable Object: per-IP sliding windows 5/min,
   30/h), `index.ts` checks it for `/host` and `/quick` before claiming; 429 + JSON message.
   vitest. Game: a refused connect shows "Too many rooms — try again in a minute"
   (net/ws_transport or online.gd error mapping). Deploy with wrangler; live e2e.

## Stage B: keyword readability

5. **Keyword icons** — download game-icons SVGs (bubble, sprint, poison drop, heart drip/leech,
   double slash, hood, halo, spark); `VisualDB.KEYWORD_ICONS`; credits. Test icons load + credited.
6. **Card text + tooltips + Combo glow + Star Shard frame** — CardWidget uses RichTextLabel with
   `CardText.render(c, true)`; `tooltip_text` lists keyword rules; `CardWidget.set_combo(on)`; hand
   calls it from `state.players[HUMAN].cards_played`; gold frame for star_shard.
7. **Tags: keyword row, spell power, hover grow** — UnitOverlay entry gets `keywords`, `spell_power`,
   `name`; icon row under the bar; hovered / targeted tag scales 1.5x and shows a name + keyword
   names panel. Tests on entry content and the grown state.
8. **Lasting effects** — `view/fx/keyword_fx.gd`, `bubble.gdshader`, `hidden_shimmer.gdshader`;
   `MatchController.refresh_pieces` syncs them. Test attach/detach per keyword; compile both renderers.
9. **One-shot moments** — EventPlayer handlers for bubble_popped, revealed, second_wind sparkle,
   hushed, keyword_gained, buffed, leeched, venom kill. Playback tests on real matches.

## Stage C: Dream Up picker

10. **Picker** — `view/ui/dream_up_picker.gd` (open → awaitable index, force(i), peek button);
    `MatchController._human_dream_up` uses it; rival display of 3 backs; online clock keeps running
    while open and forces the first card at 0. Tests in test_input_flow / test_online*.

## Stage D: finish

11. Full suite, shader compile on both renderers, screenshots of every keyword + picker + tags,
    fps on Low, code review of the branch diff, fixes, ledger + memory update.
