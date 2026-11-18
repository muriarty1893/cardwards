extends TestCase
## Board look 2, spec 1.3: lane separator ribbons follow the curves and appear when the board splits after the intro.

const LANDS: Array[Array] = [[4, 4, 4, 4], [4, 4, 4, 4]]


func _board(lay: BoardLayout) -> Board:
	var b := Board.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	b.build(LANDS, lay)
	return b


func test_hidden_before_reveal() -> bool:
	var b: Board = _board(BoardLayout.make(3))
	assert_true(not b.split_revealed, "not split before the reveal")
	assert_eq(b.separators.reveal, 0.0, "ribbons hidden before the reveal")
	assert_eq(b.separators.ribbon_count(), 3, "three ribbons, one per inner border")
	b.free()
	return true


func test_reveal_instant() -> bool:
	var b: Board = _board(BoardLayout.make(3))
	var done: Array[bool] = [false]
	b.split_done.connect(func() -> void: done[0] = true)
	b.reveal_split(false)
	assert_true(b.split_revealed, "split after reveal_split")
	assert_eq(b.separators.reveal, 1.0, "ribbons fully drawn")
	assert_true(done[0], "split_done fired")
	for p: int in 2:
		for l: int in 4:
			assert_eq(b.island(p, l).position.y, 0.0, "tile p%d l%d at rest height" % [p, l])
	b.free()
	return true


func test_reveal_animated_ends_drawn() -> bool:
	var b: Board = _board(BoardLayout.make(11))
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	assert_true(b.is_inside_tree(), "board in the tree")
	b.reveal_split(true)
	assert_true(b.separators.reveal < 0.5, "an animated reveal starts hidden")
	await b.split_done
	assert_eq(b.separators.reveal, 1.0, "ribbons fully drawn when done")
	await tree.create_timer(0.2).timeout
	for p: int in 2:
		for l: int in 4:
			assert_true(absf(b.island(p, l).position.y) < 0.001, "tile p%d l%d settled" % [p, l])
	b.free()
	return true


func test_ribbon_follows_curve() -> bool:
	var lay: BoardLayout = BoardLayout.make(21)
	var b: Board = _board(lay)
	for i: int in 3:
		var pts: PackedVector3Array = b.separators.centre_line(i)
		assert_true(pts.size() >= 48, "ribbon %d sampled finely" % i)
		assert_true(pts[0].z <= -BoardLayout.Z_END and pts[pts.size() - 1].z >= BoardLayout.Z_END, "ribbon %d spans the board" % i)
		for v: Vector3 in pts:
			assert_true(absf(v.x - lay.border_x(i, v.z)) < 0.001, "ribbon %d on its curve at z %.2f" % [i, v.z])
			assert_true(v.y > Island.TOP_Y, "ribbon %d above the tiles" % i)
	b.free()
	return true
