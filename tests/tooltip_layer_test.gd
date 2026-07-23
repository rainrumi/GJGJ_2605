extends SceneTree

const TOOLTIP_LAYER := 100

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_left_tooltip()
	await _check_seed_tooltip()
	await _check_enemy_tooltip()
	quit(_failures)


func _check_left_tooltip() -> void:
	var packed := load("res://scene/ui/battle_ui/tooltip/left/left_tooltip.tscn") as PackedScene
	_expect(packed != null, "LeftTooltip scene loads")
	if packed == null:
		return
	var tooltip := packed.instantiate() as LeftTooltip
	root.add_child(tooltip)
	await process_frame
	_expect(tooltip.layer == TOOLTIP_LAYER, "LeftTooltip uses the foreground canvas layer")
	tooltip.set_title("Tooltip")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "LeftTooltip can be shown")
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	mouse_drag_state.begin_drag(self)
	_expect(not tooltip.visible, "LeftTooltip closes when dragging starts")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(not tooltip.visible, "LeftTooltip stays hidden while dragging")
	mouse_drag_state.end_drag(self)
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "LeftTooltip can be shown after dragging ends")
	_dispose(tooltip)


func _check_seed_tooltip() -> void:
	var packed := load("res://scene/ui/seed/tooltip/seed_tooltip.tscn") as PackedScene
	_expect(packed != null, "SeedTooltip scene loads")
	if packed == null:
		return
	var tooltip := packed.instantiate() as SeedTooltip
	root.add_child(tooltip)
	await process_frame
	_expect(tooltip.layer == TOOLTIP_LAYER, "SeedTooltip uses the foreground canvas layer")
	tooltip.set_text("Tooltip")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "SeedTooltip can be shown")
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	mouse_drag_state.begin_drag(self)
	_expect(not tooltip.visible, "SeedTooltip closes when dragging starts")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(not tooltip.visible, "SeedTooltip stays hidden while dragging")
	mouse_drag_state.end_drag(self)
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "SeedTooltip can be shown after dragging ends")
	_dispose(tooltip)


func _check_enemy_tooltip() -> void:
	var packed := load("res://scene/object/enemy/tooltip/enemy_tooltip.tscn") as PackedScene
	_expect(packed != null, "EnemyTooltip scene loads")
	if packed == null:
		return
	var tooltip := packed.instantiate() as EnemyTooltip
	root.add_child(tooltip)
	await process_frame
	_expect(tooltip.layer == TOOLTIP_LAYER, "EnemyTooltip inherits the foreground canvas layer")
	_dispose(tooltip)


func _dispose(node: Node) -> void:
	root.remove_child(node)
	node.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("TooltipLayerTest: %s" % message)
