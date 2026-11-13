# SDD ledger — plan: docs/superpowers/plans/2026-11-13-dream-isles-v1.md
Setup: Ruling: work on branch feat/dream-isles-v1 in the main checkout instead of a worktree — repo is brand new and holds only docs, so a branch gives enough isolation — cost if wrong: none, master is untouched.
Pre-flight:
- T3 Produces Rules.start_turn/END_TURN vs T6 tightening END_TURN to ATTACK-only: T3 test_second_turn_draws must go via BEGIN_ATTACKS after T6 (plan already says so). OK.
- T3/T4 stub hooks (_run_lane_triggers, Abilities.run) vs T5 Produces Abilities.run(state,p,lane,card,targets,events): same signature. OK.
- T5 effective_attack used by T6 Combat and T8 AI evaluate: consistent. OK.
- T8 AIRunner.play_match used by T10 --demo-board: T10 needs partial play (6 turns). Ruling: add max_turns param use (play_match(state, ais, 6)) and accept -1 return — no interface change.
- T9 Board.lane_at_screen consumed by T11 InputController: OK.
- T12 EventPlayer events = T3 event list: OK.
- T13 TimingBar uses Action.Hit from T3: OK.
- T14 Session uses AIPlayer.Difficulty from T8: OK.
Task 1: complete (commits 14e126f..8e826c7, tests: godot --headless --path . --script res://tests/run_tests.gd → Results: 1 passed, 0 failed)
Task 2: Ruling: .tres files generated once by an untracked script (.superpowers/tools/gen_data.py) from the spec tables — the .tres files are the source of truth as the spec says — cost if wrong: none. Also fixed runner to count non-compiling test files as failures (it hung before).
Task 2: complete (commits 8e826c7..ffab90e, tests: timeout 120 godot --headless --path . --script res://tests/run_tests.gd → Results: 238 passed, 0 failed)
Task 3: Ruling: implemented BEGIN_ATTACKS now (phase switch only) so test_second_turn_draws can go MAIN→ATTACK→END_TURN as Task 6 requires — avoids rewriting the test later — cost if wrong: none.
Task 3: complete (commits ffab90e..139ed39, tests: timeout 120 godot --headless --path . --script res://tests/run_tests.gd → Results: 272 passed, 0 failed)
Task 4: complete (commits 139ed39..515812a, tests: timeout 120 godot --headless --path . --script res://tests/run_tests.gd → Results: 290 passed, 0 failed)
Task 5: Ruling: added validate message 'No such creature' for BOOP on an empty lane (plan's list had none for it) — needed for a clear UI message — cost if wrong: one string. Added Rules.freeze and Rules.has_ice_wall helpers (used by Abilities/Combat).
Task 5: complete (commits 515812a..7ee6843, tests: timeout 120 godot --headless --path . --script res://tests/run_tests.gd → Results: 357 passed, 0 failed)
Task 6: complete (commits 7ee6843..7e05efe, tests: timeout 120 godot --headless --path . --script res://tests/run_tests.gd → Results: 398 passed, 0 failed)
Task 7: complete (commits 7e05efe..9e5f04f, tests: timeout 120 godot --headless --path . --script res://tests/run_tests.gd → Results: 402 passed, 0 failed)
Task 8: Ruling: test_ai_takes_lethal uses enemy hero 2 HP (plan said 3) so a GLANCE roll (4→2) is still lethal and the test is deterministic — cost if wrong: none. Balance from 100 AI matches: blaze_rush 33/49, deep_freeze 33/50, grove_guard 18/50, sugar_storm 16/51 (none >70%).
Task 8: complete (commits 9e5f04f..7da2a34, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 509 passed, 0 failed)
Task 9: Ruling: Screenshot autoload is always registered (no-op without --shot) and renders into a fixed 1280x720 SubViewport, because Hyprland tiling ignores --resolution — cost if wrong: none at runtime. Added view/palette.gd (shared colours/mesh helpers) and Board.hero_point() for attack lunges.
Task 9: complete (commits 7da2a34..90a8bcf, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 509 passed, 0 failed)
Task 10: Ruling: human creatures turned 0.82*PI (not a full PI) so their faces show in 3/4 view from the camera — the mockup's back view hid them — cost if wrong: one constant. Badge text is 'ATK ♥HP' (no sword glyph; default font lacks it).
Task 10: complete (commits 90a8bcf..5fc6c4f, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 509 passed, 0 failed)
Task 11: Ruling: Toast method is show_message() not show() — show() would override CanvasItem.show() — cost if wrong: none.
Task 11: Ruling: Regrowth auto-picks the most recently discarded creature (no discard browser in v1); the rules engine still accepts any discard index — cost if wrong: player can't choose which creature returns; a picker can be added later.
Task 11: Ruling: added tests/test_input_flow.gd driving the real match scene (drag, drop rejection, spell targeting by click, boop by click) because I can't click a real window; tests were written after the controller, verified they fail (4/7) when island picking is broken.
Task 11: Ruling: human always goes first in the view for now (state.first_player forced) until Task 13 handles an AI-first opening — cost if wrong: Task 13 must remove it.
Task 11: complete (commits 5fc6c4f..d0a977d, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 530 passed, 0 failed)
Task 12: Ruling: spell_cast shows a toast with the spell name plus a burst at board centre instead of a flying card widget — simpler, same information — cost if wrong: less flashy spell moment.
Task 12: Ruling: attack return tween runs in the background so damage plays at the moment of impact; Swap Trick's paired creature_moved events are de-duplicated in EventPlayer — cost if wrong: none.
Task 12: Ruling: damage-number colours are boosted x1.6 to survive ACES tonemapping (gold looked olive) — cost if wrong: one constant.
Task 12: Ruling: MatchController.verify_views() resyncs from state if playback ever disagrees (spec §8 robustness).
Task 12: complete (commits d0a977d..860bbc6, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 530 passed, 0 failed)
Task 13: Ruling: TimingBar uses simulate_attack(hit)/simulate_block(blocked) (plan's single simulate(result)) — two typed methods are clearer — cost if wrong: none. Removed Task 11's forced human-first; the coin flip now decides and the AI opens if it wins.
Task 13: Ruling: added test-only hooks (TimingBar.auto_stop, MatchController.pace, EventPlayer.speed) and tests/test_full_match.gd, which plays a whole match through the real scene with an AI on the human side (I can't click a real window) — finished on turn 5 with views matching state.
Task 13: complete (commits 860bbc6..25e4e9d, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 553 passed, 0 failed)
Task 14: Ruling: added view/ui/menu_buttons.gd (shared chunky button style) and a --demo-results dev flag for screenshots; scene tests pin Session deck/seed so they don't depend on menu defaults — cost if wrong: none.
Task 14: complete (commits 25e4e9d..caff0cb, tests: timeout 300 godot --headless --path . --script res://tests/run_tests.gd → Results: 553 passed, 0 failed)
Post-plan (user request): replaced islands with lane strips, added Quaternius CC0 models (assets/, see assets/CREDITS.md), sky/cloud/islet setting, and a tray HUD laid out like the user's reference screenshot (layout only, own art). Suite 555/555.
Final review: NOT DONE — reviewer agent stopped by the account usage limit; must be re-run on the current HEAD.
Final review: fresh reviewer on f5e90b1 — 0 Critical, 1 Important, 7 Minor.
Final: fixed pause menu not blocking hand/board input — test_pause_blocks_play RED→GREEN, suite 561/561. Overlay moved above the hand; hand and board input off while paused.
Final: Ruling: Ice Wall's "minimum 1" does not survive a block (hit → Ice Wall → block, so 1 can become 0) — the spec doesn't order them and blocking should always be worth something — cost if wrong: one line in Combat.attack_damage.
Final: minor (deferred): in targeting mode a click on a non-valid lane is sent and rejected, dropping you out of targeting (input_controller.gd).
Final: minor (deferred): freezing your OWN creature on your turn lasts that turn plus its next turn (spec says next turn only).
Final: minor (deferred): pause button only works during your own main phase; Escape doesn't open/close the pause menu.
Final: minor (deferred): spells look playable on cost alone even with no legal target (rejected on drop).
Final: minor (deferred): "-0" damage numbers on 0-damage hits.
Final: minor (deferred): results screen counts each player's turn separately (10 rounds reads "20 turns").
Final: minor (deferred): AI hit/block rolls use the AI's own seeded RNG, not GameState.rng (still deterministic and replay-safe).
