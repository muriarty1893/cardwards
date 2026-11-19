class_name BotBrain
extends RefCounted
## Plays one seat of an online match with the AI (headless tests and tools/online_bot.gd): applies
## the room's moves, answers block requests with a roll, and sends the next move on its turn.

var rng := RandomNumberGenerator.new()
var ai: AIPlayer
## A move of ours is on its way to the room (wait for its echo or a rejection).
var waiting: bool = false
var moves_sent: int = 0


func _init(brain_seed: int) -> void:
	rng.seed = brain_seed


func step(s: OnlineSession) -> void:
	if s.state == null:
		return
	if ai == null or ai.player != s.seat:
		ai = AIPlayer.new(s.seat, AIPlayer.Difficulty.MEDIUM, rng.randi())
	while true:
		var msg: Dictionary = s.next()
		if msg.is_empty():
			break
		match String(msg["t"]):
			"move":
				s.apply_move(msg)
				if int((msg["a"] as Dictionary)["player"]) == s.seat and not msg.get("auto", false):
					waiting = false
			"block_wanted":
				s.send_block(rng.randf() < 0.3)
			"rejected", "over":
				waiting = false
	if waiting or not s.is_my_turn():
		return
	var st: GameState = s.state
	var a: Action = Action.choose(s.seat, 0) if st.phase == GameState.Phase.CHOOSING else ai.choose_action(st)
	if a.type == Action.Type.ATTACK:
		s.send_attack(a.lane, a.target_lane, int(ai.roll_hit()))
	else:
		s.send_act(a)
	waiting = true
	moves_sent += 1
