extends Node2D

signal battle_finished(won: bool)

const START_HOUR := 23
const END_HOUR := 30
const STEP_MINUTES := 30
const REST_MINUTES := 60
const MAX_HP := 100
const REST_HP := 50
const DIGEST_DAMAGE := 200
const STOMACH_COLUMNS := 4
const STOMACH_ROWS := 5
const MAX_FULLNESS := STOMACH_COLUMNS * STOMACH_ROWS
const STOMACH_GRID_EDGE_OVERLAP := 1.0
const START_MESSAGE := "６時までにすべての悪夢を消化しましょう"
const ENEMY_TEXTURES: Array[Texture2D] = [
	preload("res://art/enemy/tex_enemy_1000_No_100.png"),
	preload("res://art/enemy/tex_enemy_1000_No_200.png"),
	preload("res://art/enemy/tex_enemy_1000_No_300.png"),
]
const ENEMY_START_POSITIONS: Array[Vector2] = [
	Vector2(850, 500),
	Vector2(1000, 280),
	Vector2(1150, 500),
]
const ENEMY_STOMACH_TOP_LEFT_CELLS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 2),
	Vector2i(2, 0),
]
const ENEMY_STOMACH_SIZES: Array[Vector2i] = [
	Vector2i(2, 3),
	Vector2i(3, 3),
	Vector2i(2, 2),
]

@onready var ui: CanvasLayer = $UI
@onready var time_text: Label = $UI/TimeBar/TimeText
@onready var hp_text: Label = $UI/HPBar/HPText
@onready var message_text: Label = get_node_or_null("UI/StatusPanel/MessageText") as Label
@onready var passive_guide_text: Label = get_node_or_null("UI/PassiveGuideFrame/PassiveGuideText") as Label
@onready var digestion_frame: TextureRect = $UI/DigestionFrame
@onready var digestion_label: Label = $UI/DigestionFrame/DigestionLabel
@onready var stomach: Node2D = $Stomach
@onready var stomach_frame: NinePatchRect = $Stomach/frame
@onready var stomach_grid_frame: NinePatchRect = $Stomach/grid_frame
@onready var enemy_nodes: Array[Node2D] = [
	$EnemyLeft as Node2D,
	$EnemyCenter as Node2D,
	$EnemyRight as Node2D,
]

var minutes: int = START_HOUR * 60
var hp: int = MAX_HP
var enemies: Array[Dictionary] = []
var dragging_enemy_index := -1
var drag_offset := Vector2.ZERO
var original_enemy_positions: Array[Vector2] = []
var battle_active := false
var stomach_grid_origin := Vector2.ZERO
var stomach_grid_cell_size := 0.0
var stomach_grid_step := 0.0


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_prepare_mouse_filters()
	_configure_stomach_grid()
	_sync_ui_visibility()
	start_battle()


func start_battle() -> void:
	minutes = START_HOUR * 60
	hp = MAX_HP
	battle_active = true
	dragging_enemy_index = -1
	enemies = [
		_create_enemy("大人に追われる悪夢", 1400, 6, 2),
		_create_enemy("落下する悪夢", 1000, 5, 3),
		_create_enemy("仕事が終わらない悪夢", 2000, 3, 5),
	]
	original_enemy_positions.clear()
	for i in range(enemy_nodes.size()):
		var start_position: Vector2 = ENEMY_START_POSITIONS[i] as Vector2
		original_enemy_positions.append(start_position)
		enemy_nodes[i].position = start_position
		enemy_nodes[i].visible = true
	_apply_enemy_textures()
	_update_enemy_labels()
	_update_ui(START_MESSAGE)


func _input(event: InputEvent) -> void:
	if not battle_active:
		return
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_handle_press(mouse_button.position)
		else:
			_handle_release(mouse_button.position)
	elif event is InputEventMouseMotion:
		var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
		if dragging_enemy_index != -1:
			enemy_nodes[dragging_enemy_index].global_position = mouse_motion.position + drag_offset


func _handle_press(mouse_position: Vector2) -> void:
	var digestion_rect := _get_global_rect(digestion_frame)
	if digestion_rect.has_point(mouse_position):
		_advance_digest_turn()
		return
	for i in range(enemy_nodes.size() - 1, -1, -1):
		if not _can_drag_enemy(i):
			continue
		if _get_enemy_rect(i).has_point(mouse_position):
			dragging_enemy_index = i
			drag_offset = enemy_nodes[i].global_position - mouse_position
			return


func _handle_release(mouse_position: Vector2) -> void:
	if dragging_enemy_index == -1:
		return
	var enemy_index := dragging_enemy_index
	dragging_enemy_index = -1
	if _get_stomach_rect().has_point(mouse_position):
		_try_start_digesting(enemy_index)
	else:
		_return_enemy_to_origin(enemy_index)


func _create_enemy(name: String, hp_value: int, size: int, damage: int) -> Dictionary:
	return {
		"name": name,
		"max_hp": hp_value,
		"remaining_hp": hp_value,
		"size": size,
		"damage": damage,
		"digesting": false,
		"digested": false,
	}


func _prepare_mouse_filters() -> void:
	digestion_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digestion_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if message_text != null:
		message_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if passive_guide_text != null:
		passive_guide_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_panel := get_node_or_null("UI/StatusPanel") as Control
	if status_panel != null:
		status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var passive_guide_frame := get_node_or_null("UI/PassiveGuideFrame") as Control
	if passive_guide_frame != null:
		passive_guide_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_bar := get_node_or_null("UI/HPBar") as Control
	if hp_bar != null:
		hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var time_bar := get_node_or_null("UI/TimeBar") as Control
	if time_bar != null:
		time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enemy_node in enemy_nodes:
		var label := enemy_node.get_node_or_null("HPText") as Label
		if label != null:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _can_drag_enemy(enemy_index: int) -> bool:
	var enemy := enemies[enemy_index]
	return not bool(enemy["digesting"]) and not bool(enemy["digested"])


func _try_start_digesting(enemy_index: int) -> void:
	var enemy := enemies[enemy_index]
	var next_fullness := _current_fullness() + int(enemy["size"])
	if next_fullness > MAX_FULLNESS:
		_return_enemy_to_origin(enemy_index)
		_update_ui("胃袋がいっぱいです")
		return
	enemy["digesting"] = true
	enemies[enemy_index] = enemy
	_place_enemy_in_stomach(enemy_index)
	_update_ui("%s の消化を開始しました" % String(enemy["name"]))


func _advance_digest_turn() -> void:
	if _active_digest_count() == 0:
		_update_ui("消化中の悪夢がありません")
		return
	_digest_nightmares()
	_apply_digest_damage()
	_advance_time(STEP_MINUTES)
	if hp <= 0:
		hp = REST_HP
		_advance_time(REST_MINUTES)
		_update_ui("体力が尽きたため休憩しました")
	else:
		_update_ui("30分が経過しました")
	_check_battle_end()


func _digest_nightmares() -> void:
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if not bool(enemy["digesting"]) or bool(enemy["digested"]):
			continue
		enemy["remaining_hp"] = maxi(0, int(enemy["remaining_hp"]) - DIGEST_DAMAGE)
		if int(enemy["remaining_hp"]) == 0:
			enemy["digested"] = true
			enemy["digesting"] = false
			enemy_nodes[i].visible = false
		enemies[i] = enemy
	_update_enemy_labels()


func _apply_digest_damage() -> void:
	var damage := 0
	for raw_enemy in enemies:
		var enemy: Dictionary = raw_enemy
		if bool(enemy["digesting"]) and not bool(enemy["digested"]):
			damage += int(enemy["damage"])
	hp -= damage


func _check_battle_end() -> void:
	if _all_enemies_digested():
		battle_active = false
		_update_ui("勝利。すべての悪夢を消化しました")
		battle_finished.emit(true)
		return
	if minutes >= END_HOUR * 60:
		battle_active = false
		_update_ui("敗北。朝までに消化しきれませんでした")
		battle_finished.emit(false)


func _all_enemies_digested() -> bool:
	for raw_enemy in enemies:
		var enemy: Dictionary = raw_enemy
		if not bool(enemy["digested"]):
			return false
	return true


func _active_digest_count() -> int:
	var count := 0
	for raw_enemy in enemies:
		var enemy: Dictionary = raw_enemy
		if bool(enemy["digesting"]) and not bool(enemy["digested"]):
			count += 1
	return count


func _current_fullness() -> int:
	var fullness := 0
	for raw_enemy in enemies:
		var enemy: Dictionary = raw_enemy
		if bool(enemy["digesting"]) and not bool(enemy["digested"]):
			fullness += int(enemy["size"])
	return fullness


func _advance_time(amount_minutes: int) -> void:
	minutes += amount_minutes


func _update_ui(message: String) -> void:
	time_text.text = _format_time()
	hp_text.text = "%d/%d" % [maxi(0, hp), MAX_HP]
	if message_text != null:
		message_text.text = message
	_update_digestion_label()


func _update_digestion_label() -> void:
	if _active_digest_count() == 0:
		digestion_label.text = "消化開始！"
	else:
		digestion_label.text = "30分進める"


func _update_enemy_labels() -> void:
	for i in range(enemy_nodes.size()):
		var label := enemy_nodes[i].get_node_or_null("HPText") as Label
		if label == null or i >= enemies.size():
			continue
		label.text = str(int(enemies[i]["remaining_hp"]))


func _apply_enemy_textures() -> void:
	for i in range(enemy_nodes.size()):
		if i >= ENEMY_TEXTURES.size():
			return
		var sprite := enemy_nodes[i].get_node_or_null("Sprite2D") as Sprite2D
		if sprite == null:
			continue
		sprite.texture = ENEMY_TEXTURES[i] as Texture2D
		_resize_enemy_to_stomach_grid(i, sprite)


func _configure_stomach_grid() -> void:
	var template_position := stomach_grid_frame.position
	var template_size := stomach_grid_frame.size
	stomach_grid_cell_size = minf(
		(template_size.x + float(STOMACH_COLUMNS - 1) * STOMACH_GRID_EDGE_OVERLAP) / float(STOMACH_COLUMNS),
		(template_size.y + float(STOMACH_ROWS - 1) * STOMACH_GRID_EDGE_OVERLAP) / float(STOMACH_ROWS)
	)
	stomach_grid_step = stomach_grid_cell_size - STOMACH_GRID_EDGE_OVERLAP
	var grid_size := Vector2(
		float(STOMACH_COLUMNS) * stomach_grid_cell_size - float(STOMACH_COLUMNS - 1) * STOMACH_GRID_EDGE_OVERLAP,
		float(STOMACH_ROWS) * stomach_grid_cell_size - float(STOMACH_ROWS - 1) * STOMACH_GRID_EDGE_OVERLAP
	)
	stomach_grid_origin = template_position + (template_size - grid_size) * 0.5
	for child in stomach.get_children():
		if child is NinePatchRect and String(child.name).begins_with("grid_frame_"):
			child.queue_free()
	for row in range(STOMACH_ROWS):
		for column in range(STOMACH_COLUMNS):
			var cell := stomach_grid_frame
			if row != 0 or column != 0:
				cell = stomach_grid_frame.duplicate() as NinePatchRect
				cell.name = "grid_frame_%d_%d" % [column, row]
				stomach.add_child(cell)
			cell.position = stomach_grid_origin + Vector2(column, row) * stomach_grid_step
			cell.size = Vector2(stomach_grid_cell_size, stomach_grid_cell_size)
	stomach.move_child(stomach_frame, stomach.get_child_count() - 1)


func _place_enemy_in_stomach(enemy_index: int) -> void:
	var top_left := ENEMY_STOMACH_TOP_LEFT_CELLS[enemy_index]
	var size := ENEMY_STOMACH_SIZES[enemy_index]
	enemy_nodes[enemy_index].global_position = _get_stomach_area_center(top_left, size)


func _return_enemy_to_origin(enemy_index: int) -> void:
	if enemy_index >= original_enemy_positions.size():
		return
	enemy_nodes[enemy_index].position = original_enemy_positions[enemy_index]


func _get_enemy_rect(enemy_index: int) -> Rect2:
	var sprite := enemy_nodes[enemy_index].get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		return Rect2(enemy_nodes[enemy_index].global_position - Vector2(50, 50), Vector2(100, 100))
	var size := sprite.texture.get_size() * sprite.scale.abs()
	return Rect2(sprite.global_position - size * 0.5, size)


func _get_stomach_rect() -> Rect2:
	if stomach_frame == null:
		return Rect2(stomach.global_position - Vector2(188, 284), Vector2(376, 568))
	return _get_global_rect(stomach_frame)


func _get_stomach_area_center(top_left: Vector2i, size: Vector2i) -> Vector2:
	var local_position := stomach_grid_origin + Vector2(
		float(top_left.x) * stomach_grid_step + _get_stomach_span_size(size.x) * 0.5,
		float(top_left.y) * stomach_grid_step + _get_stomach_span_size(size.y) * 0.5
	)
	return stomach.to_global(local_position)


func _resize_enemy_to_stomach_grid(enemy_index: int, sprite: Sprite2D) -> void:
	if enemy_index >= ENEMY_STOMACH_SIZES.size() or sprite.texture == null:
		return
	var size := ENEMY_STOMACH_SIZES[enemy_index]
	var target_size := Vector2(
		_get_stomach_span_size(size.x),
		_get_stomach_span_size(size.y)
	)
	sprite.scale = target_size / sprite.texture.get_size()


func _get_stomach_span_size(cell_count: int) -> float:
	return float(cell_count) * stomach_grid_cell_size - float(cell_count - 1) * STOMACH_GRID_EDGE_OVERLAP


func _get_global_rect(control: Control) -> Rect2:
	return Rect2(control.global_position, control.size)


func _format_time() -> String:
	var hour := int(minutes / 60) % 24
	var minute := minutes % 60
	return "%02d:%02d" % [hour, minute]


func _on_visibility_changed() -> void:
	_sync_ui_visibility()


func _sync_ui_visibility() -> void:
	if ui == null:
		return
	ui.visible = visible
