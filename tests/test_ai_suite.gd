extends TestCase
## Seeded AI-vs-AI matches (Rules 2.0 spec section 7): every match ends legally, and the
## stronger difficulty wins most of the time. Decks rotate through all 4 × 4 pairings.

const MATCHES := 40


## Plays one match step by step; returns [winner, rejected_actions].
func _match(seed: int, diffs: Array, decks: Array[DeckData]) -> Array:
	var s: GameState = Rules.setup(decks[0], decks[1], seed)
	var ais: Array[AIPlayer] = [AIPlayer.new(0, diffs[0], seed * 2), AIPlayer.new(1, diffs[1], seed * 2 + 1)]
	Rules.start_turn(s)
	var rejected: int = 0
	var steps: int = 0
	while s.phase != GameState.Phase.OVER and steps < 4000:
		steps += 1
		var who: int = s.pending_player if s.phase == GameState.Phase.CHOOSING else s.active
		var a: Action = ais[who].choose_action(s)
		if a.type == Action.Type.ATTACK:
			a.hit = ais[who].roll_hit()
			a.blocked = ais[1 - who].roll_block() if a.target_lane >= 0 else false
		if Rules.validate(s, a) != "":
			rejected += 1
			a = Action.end_turn(who) if s.phase == GameState.Phase.MAIN else Action.choose(who, 0)
		Rules.apply(s, a)
	return [s.winner if s.phase == GameState.Phase.OVER else -1, rejected]


func _decks(i: int) -> Array[DeckData]:
	var all: Array[DeckData] = CardDB.all_decks()
	return [all[i % 4], all[(i / 4) % 4]]


func test_matches_finish_legally() -> bool:
	for i: int in MATCHES:
		var r: Array = _match(1000 + i, [AIPlayer.Difficulty.MEDIUM, AIPlayer.Difficulty.MEDIUM], _decks(i))
		assert_true(r[0] >= 0, "match %d finished" % i)
		assert_eq(r[1], 0, "match %d only legal actions" % i)
	return true


## Wins of `strong` over `weak` across MATCHES, alternating seats.
func _wins(strong: AIPlayer.Difficulty, weak: AIPlayer.Difficulty) -> int:
	var wins: int = 0
	for i: int in MATCHES:
		var seat: int = i % 2
		var diffs: Array = [strong, weak] if seat == 0 else [weak, strong]
		var r: Array = _match(2000 + i, diffs, _decks(i))
		if r[0] == seat:
			wins += 1
	return wins


func test_hard_beats_easy() -> bool:
	var w: int = _wins(AIPlayer.Difficulty.HARD, AIPlayer.Difficulty.EASY)
	print("hard vs easy: %d/%d" % [w, MATCHES])
	assert_true(w >= ceili(MATCHES * 0.7), "hard wins >= 70%% (%d/%d)" % [w, MATCHES])
	return true


func test_medium_beats_easy() -> bool:
	var w: int = _wins(AIPlayer.Difficulty.MEDIUM, AIPlayer.Difficulty.EASY)
	print("medium vs easy: %d/%d" % [w, MATCHES])
	assert_true(w >= ceili(MATCHES * 0.6), "medium wins >= 60%% (%d/%d)" % [w, MATCHES])
	return true
