extends SceneTree
func _initialize() -> void:
	var all: Array[DeckData] = CardDB.all_decks()
	var seed: int = 1016
	var s: GameState = Rules.setup(all[0], all[0], seed)
	var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, seed * 2), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, seed * 2 + 1)]
	Rules.start_turn(s)
	var steps: int = 0
	while s.phase != GameState.Phase.OVER and steps < 4000:
		steps += 1
		var who: int = s.pending_player if s.phase == GameState.Phase.CHOOSING else s.active
		var a: Action = ais[who].choose_action(s)
		if a.type == Action.Type.ATTACK:
			a.hit = ais[who].roll_hit()
			a.blocked = ais[1 - who].roll_block() if a.target_lane >= 0 else false
		if Rules.validate(s, a) != "":
			print("rejected ", a, " ", Rules.validate(s, a))
			a = Action.end_turn(who) if s.phase == GameState.Phase.MAIN else Action.choose(who, 0)
		Rules.apply(s, a)
		if steps % 400 == 0:
			print("step %d turn %d hp %d/%d armour %d/%d deck %d/%d hand %d/%d" % [steps, s.turn, s.players[0].hero_hp, s.players[1].hero_hp, s.players[0].armour, s.players[1].armour, s.players[0].deck.size(), s.players[1].deck.size(), s.players[0].hand.size(), s.players[1].hand.size()])
	print("end steps %d phase %d winner %d turn %d" % [steps, s.phase, s.winner, s.turn])
	quit()
