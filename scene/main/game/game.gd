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
const DIGEST_AUTO_INTERVAL := 0.8
const REMOVE_FROM_STOMACH_DAMAGE_RATE := 0.05
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
const ENEMY_STOMACH_SIZES: Array[Vector2i] = [
	Vector2i(2, 3),
	Vector2i(3, 3),
	Vector2i(2, 2),
]
const ENEMY_STOMACH_SHAPES: Array[Array] = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
]

@onready var ui: CanvasLayer = $UI
@onready var time_text: Label = $UI/TimeBar/TimeText
@onready var hp_frame: NinePatchRect = $UI/HpFrame
@onready var hp_gauge: NinePatchRect = $UI/HpFrame/HpGauge
@onready var hp_text: Label = $UI/HpFrame/HpText
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
var drag_grab_cell := Vector2i.ZERO
var original_enemy_positions: Array[Vector2] = []
var battle_active := false
var stomach_grid_origin := Vector2.ZERO
var stomach_grid_cell_size := 0.0
var stomach_grid_step := 0.0
var stomach_preview_sprite: Sprite2D
var digestion_timer: Timer
var hp_damage_preview_label: Label
var hp_gauge_full_width := 0.0
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var dragged_enemy_was_digesting := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_prepare_mouse_filters()
	_capture_hp_gauge_size()
	_configure_stomach_grid()
	_create_stomach_preview()
	_create_digestion_timer()
	_create_hp_damage_preview()
	_sync_ui_visibility()
	start_battle()


func start_battle() -> void:
	minutes = START_HOUR * 60
	hp = MAX_HP
	battle_active = true
	dragging_enemy_index = -1
	dragged_enemy_was_digesting = false
	_hide_stomach_preview()
	_hide_hp_damage_preview()
	_reset_auto_digest()
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
			_update_stomach_preview(mouse_motion.position)
			_update_hp_damage_preview(mouse_motion.position)


func _handle_press(mouse_position: Vector2) -> void:
	var digestion_rect := _get_global_rect(digestion_frame)
	if digestion_frame.visible and digestion_rect.has_point(mouse_position):
		_start_auto_digest()
		return
	for i in range(enemy_nodes.size() - 1, -1, -1):
		if not _can_drag_enemy(i):
			continue
		if _get_enemy_rect(i).has_point(mouse_position):
			dragging_enemy_index = i
			drag_offset = enemy_nodes[i].global_position - mouse_position
			drag_grab_cell = _get_enemy_grab_cell(i, mouse_position)
			_start_enemy_drag(i)
			_pause_auto_digest_for_drag()
			_update_stomach_preview(mouse_position)
			_update_hp_damage_preview(mouse_position)
			return


func _handle_release(mouse_position: Vector2) -> void:
	if dragging_enemy_index == -1:
		return
	var enemy_index := dragging_enemy_index
	dragging_enemy_index = -1
	_hide_stomach_preview()
	_hide_hp_damage_preview()
	if _get_stomach_rect().has_point(mouse_position):
		_try_start_digesting(enemy_index, mouse_position)
	else:
		_remove_dragged_enemy_from_stomach(enemy_index)
	_resume_auto_digest_after_drag()


func _create_enemy(name: String, hp_value: int, size: int, damage: int) -> Dictionary:
	return {
		"name": name,
		"max_hp": hp_value,
		"remaining_hp": hp_value,
		"size": size,
		"damage": damage,
		"digesting": false,
		"digested": false,
		"stomach_cell": Vector2i.ZERO,
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
	var hp_frame := get_node_or_null("UI/HpFrame") as Control
	if hp_frame != null:
		hp_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var time_bar := get_node_or_null("UI/TimeBar") as Control
	if time_bar != null:
		time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enemy_node in enemy_nodes:
		var label := enemy_node.get_node_or_null("HPText") as Label
		if label != null:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _capture_hp_gauge_size() -> void:
	hp_gauge_full_width = hp_gauge.size.x


func _can_drag_enemy(enemy_index: int) -> bool:
	var enemy := enemies[enemy_index]
	return not bool(enemy["digested"])


func _start_enemy_drag(enemy_index: int) -> void:
	var enemy := enemies[enemy_index]
	dragged_enemy_was_digesting = bool(enemy["digesting"])
	dragged_enemy_original_cell = enemy["stomach_cell"]
	dragged_enemy_original_global_position = enemy_nodes[enemy_index].global_position


func _create_digestion_timer() -> void:
	digestion_timer = Timer.new()
	digestion_timer.name = "AutoDigestionTimer"
	digestion_timer.wait_time = DIGEST_AUTO_INTERVAL
	digestion_timer.one_shot = false
	digestion_timer.autostart = false
	digestion_timer.timeout.connect(_on_digestion_timer_timeout)
	add_child(digestion_timer)


func _create_hp_damage_preview() -> void:
	hp_damage_preview_label = Label.new()
	hp_damage_preview_label.name = "RemoveNightmareDamagePreview"
	hp_damage_preview_label.visible = false
	hp_damage_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_damage_preview_label.text = "-%d" % _get_remove_from_stomach_damage()
	hp_damage_preview_label.add_theme_color_override("font_color", Color.html("#ff0736"))
	hp_damage_preview_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_damage_preview_label.add_theme_constant_override("outline_size", 3)
	var preview_font := hp_text.get_theme_font("font")
	if preview_font != null:
		hp_damage_preview_label.add_theme_font_override("font", preview_font)
	hp_damage_preview_label.add_theme_font_size_override("font_size", 28)
	ui.add_child(hp_damage_preview_label)
	_position_hp_damage_preview()


func _update_auto_digest_timer() -> void:
	if digestion_timer == null:
		return
	var active_digest_count := _active_digest_count()
	if auto_digest_enabled and active_digest_count == 0:
		auto_digest_enabled = false
		auto_digest_paused_for_drag = false
	if auto_digest_enabled and battle_active and not auto_digest_paused_for_drag and active_digest_count > 0:
		if digestion_timer.is_stopped():
			digestion_timer.start()
	else:
		if not digestion_timer.is_stopped():
			digestion_timer.stop()
	_update_digestion_button_visibility()


func _stop_auto_digest() -> void:
	if digestion_timer != null and not digestion_timer.is_stopped():
		digestion_timer.stop()


func _reset_auto_digest() -> void:
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	_stop_auto_digest()
	_update_digestion_button_visibility()


func _start_auto_digest() -> void:
	if _active_digest_count() == 0:
		_advance_digest_turn()
		return
	auto_digest_enabled = true
	auto_digest_paused_for_drag = false
	_update_digestion_button_visibility()
	_prepare_stomach_for_digest()
	_advance_digest_turn()


func _pause_auto_digest_for_drag() -> void:
	if not auto_digest_enabled:
		return
	auto_digest_paused_for_drag = true
	_update_auto_digest_timer()


func _resume_auto_digest_after_drag() -> void:
	if not auto_digest_enabled:
		return
	auto_digest_paused_for_drag = false
	_update_auto_digest_timer()


func _update_digestion_button_visibility() -> void:
	digestion_frame.visible = battle_active and not auto_digest_enabled


func _on_digestion_timer_timeout() -> void:
	if not auto_digest_enabled or auto_digest_paused_for_drag:
		_update_auto_digest_timer()
		return
	_advance_digest_turn()


func _prepare_stomach_for_digest() -> void:
	if not _has_bottom_touching_nightmare():
		_apply_stomach_gravity()


func _try_start_digesting(enemy_index: int, mouse_position: Vector2) -> void:
	var enemy := enemies[enemy_index]
	var next_fullness := _current_fullness()
	if not dragged_enemy_was_digesting:
		next_fullness += int(enemy["size"])
	if next_fullness > MAX_FULLNESS:
		_return_dragged_enemy(enemy_index)
		_update_ui("胃袋がいっぱいです")
		return
	var top_left := _get_dragged_enemy_drop_cell(enemy_index, mouse_position)
	if not _can_place_enemy_at(enemy_index, top_left):
		_return_dragged_enemy(enemy_index)
		_update_ui("その場所には置けません")
		return
	enemy["digesting"] = true
	enemies[enemy_index] = enemy
	_place_enemy_in_stomach(enemy_index, top_left)
	_update_ui("%s の消化を開始しました" % String(enemy["name"]))


func _advance_digest_turn() -> void:
	if _active_digest_count() == 0:
		_reset_auto_digest()
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
	_update_auto_digest_timer()


func _digest_nightmares() -> void:
	var digested_this_turn := false
	for i in range(enemies.size()):
		var enemy := enemies[i]
		var bottom_cell_count := _get_bottom_row_cell_count(i)
		if bottom_cell_count == 0:
			continue
		enemy["remaining_hp"] = maxi(0, int(enemy["remaining_hp"]) - DIGEST_DAMAGE * bottom_cell_count)
		if int(enemy["remaining_hp"]) == 0:
			enemy["digested"] = true
			enemy["digesting"] = false
			enemy_nodes[i].visible = false
			digested_this_turn = true
		enemies[i] = enemy
	if digested_this_turn:
		_apply_stomach_gravity()
	_update_enemy_labels()


func _apply_digest_damage() -> void:
	var damage := 0
	for raw_enemy in enemies:
		var enemy: Dictionary = raw_enemy
		if bool(enemy["digesting"]) and not bool(enemy["digested"]):
			damage += int(enemy["damage"])
	hp -= damage


func _apply_remove_from_stomach_damage() -> void:
	hp = maxi(0, hp - _get_remove_from_stomach_damage())
	_update_ui("胃袋から悪夢を戻したためダメージを受けました")


func _get_remove_from_stomach_damage() -> int:
	return ceili(float(MAX_HP) * REMOVE_FROM_STOMACH_DAMAGE_RATE)


func _check_battle_end() -> void:
	if _all_enemies_digested():
		battle_active = false
		_reset_auto_digest()
		_update_ui("勝利。すべての悪夢を消化しました")
		battle_finished.emit(true)
		return
	if minutes >= END_HOUR * 60:
		battle_active = false
		_reset_auto_digest()
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
	_update_hp_gauge()
	if message_text != null:
		message_text.text = message
	_update_digestion_label()


func _update_hp_gauge() -> void:
	var hp_ratio := clampf(float(maxi(0, hp)) / float(MAX_HP), 0.0, 1.0)
	hp_gauge.visible = hp_ratio > 0.0
	hp_gauge.size = Vector2(hp_gauge_full_width * hp_ratio, hp_gauge.size.y)


func _update_digestion_label() -> void:
	digestion_label.text = "消化開始！"


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


func _create_stomach_preview() -> void:
	stomach_preview_sprite = Sprite2D.new()
	stomach_preview_sprite.name = "EnemyPlacementPreview"
	stomach_preview_sprite.visible = false
	stomach_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	stomach_preview_sprite.z_index = 5
	stomach.add_child(stomach_preview_sprite)
	stomach.move_child(stomach_frame, stomach.get_child_count() - 1)


func _update_stomach_preview(mouse_position: Vector2) -> void:
	if dragging_enemy_index == -1 or not _get_stomach_rect().has_point(mouse_position):
		_hide_stomach_preview()
		return
	var source_sprite := enemy_nodes[dragging_enemy_index].get_node_or_null("Sprite2D") as Sprite2D
	if source_sprite == null or source_sprite.texture == null:
		_hide_stomach_preview()
		return
	var top_left := _get_dragged_enemy_drop_cell(dragging_enemy_index, mouse_position)
	if not _is_enemy_within_stomach_bounds(dragging_enemy_index, top_left):
		_hide_stomach_preview()
		return
	stomach_preview_sprite.texture = source_sprite.texture
	stomach_preview_sprite.scale = source_sprite.scale
	stomach_preview_sprite.global_position = _get_stomach_area_center(top_left, ENEMY_STOMACH_SIZES[dragging_enemy_index])
	stomach_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	if not _can_place_enemy_at(dragging_enemy_index, top_left):
		stomach_preview_sprite.modulate = Color(1.0, 0.35, 0.35, 0.32)
	stomach_preview_sprite.visible = true


func _hide_stomach_preview() -> void:
	if stomach_preview_sprite != null:
		stomach_preview_sprite.visible = false


func _update_hp_damage_preview(mouse_position: Vector2) -> void:
	if hp_damage_preview_label == null:
		return
	if dragged_enemy_was_digesting and not _get_stomach_rect().has_point(mouse_position):
		hp_damage_preview_label.text = "-%d" % _get_remove_from_stomach_damage()
		_position_hp_damage_preview()
		hp_damage_preview_label.visible = true
	else:
		_hide_hp_damage_preview()


func _hide_hp_damage_preview() -> void:
	if hp_damage_preview_label != null:
		hp_damage_preview_label.visible = false


func _position_hp_damage_preview() -> void:
	if hp_damage_preview_label == null:
		return
	hp_damage_preview_label.position = hp_frame.position + Vector2(hp_frame.size.x - 42.0, -16.0)


func _place_enemy_in_stomach(enemy_index: int, top_left: Vector2i) -> void:
	var size := ENEMY_STOMACH_SIZES[enemy_index]
	var enemy := enemies[enemy_index]
	enemy["stomach_cell"] = top_left
	enemies[enemy_index] = enemy
	enemy_nodes[enemy_index].global_position = _get_stomach_area_center(top_left, size)


func _return_dragged_enemy(enemy_index: int) -> void:
	if dragged_enemy_was_digesting:
		var enemy := enemies[enemy_index]
		enemy["digesting"] = true
		enemy["stomach_cell"] = dragged_enemy_original_cell
		enemies[enemy_index] = enemy
		enemy_nodes[enemy_index].global_position = dragged_enemy_original_global_position
	else:
		_return_enemy_to_origin(enemy_index)


func _remove_dragged_enemy_from_stomach(enemy_index: int) -> void:
	if not dragged_enemy_was_digesting:
		_return_enemy_to_origin(enemy_index)
		return
	var enemy := enemies[enemy_index]
	enemy["digesting"] = false
	enemies[enemy_index] = enemy
	_return_enemy_to_origin(enemy_index)
	_apply_remove_from_stomach_damage()


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


func _get_enemy_grab_cell(enemy_index: int, mouse_position: Vector2) -> Vector2i:
	var enemy_rect := _get_enemy_rect(enemy_index)
	var enemy_size := ENEMY_STOMACH_SIZES[enemy_index]
	var relative_position := mouse_position - enemy_rect.position
	var grabbed_cell := Vector2i(
		clampi(int(relative_position.x / enemy_rect.size.x * float(enemy_size.x)), 0, enemy_size.x - 1),
		clampi(int(relative_position.y / enemy_rect.size.y * float(enemy_size.y)), 0, enemy_size.y - 1)
	)
	if _get_enemy_shape_offsets(enemy_index).has(grabbed_cell):
		return grabbed_cell
	return _get_nearest_enemy_shape_cell(enemy_index, grabbed_cell)


func _get_nearest_enemy_shape_cell(enemy_index: int, target_cell: Vector2i) -> Vector2i:
	var nearest_cell := Vector2i.ZERO
	var nearest_distance := INF
	for offset in _get_enemy_shape_offsets(enemy_index):
		var offset_cell: Vector2i = offset
		var diff := target_cell - offset_cell
		var distance := float(diff.x * diff.x + diff.y * diff.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = offset_cell
	return nearest_cell


func _get_dragged_enemy_top_left_cell(mouse_position: Vector2) -> Vector2i:
	return _get_nearest_stomach_cell(mouse_position) - drag_grab_cell


func _get_dragged_enemy_drop_cell(enemy_index: int, mouse_position: Vector2) -> Vector2i:
	var target_cell := _get_dragged_enemy_top_left_cell(mouse_position)
	target_cell.y = 0
	if not _can_place_enemy_at(enemy_index, target_cell):
		return target_cell
	var drop_cell := target_cell
	while _can_place_enemy_at(enemy_index, drop_cell + Vector2i(0, 1)):
		drop_cell += Vector2i(0, 1)
	return drop_cell


func _get_nearest_stomach_cell(global_position: Vector2) -> Vector2i:
	var local_position := stomach.to_local(global_position)
	var centered_position := local_position - stomach_grid_origin - Vector2.ONE * stomach_grid_cell_size * 0.5
	return Vector2i(
		clampi(roundi(centered_position.x / stomach_grid_step), 0, STOMACH_COLUMNS - 1),
		clampi(roundi(centered_position.y / stomach_grid_step), 0, STOMACH_ROWS - 1)
	)


func _get_stomach_rect() -> Rect2:
	if stomach_frame == null:
		return Rect2(stomach.global_position - Vector2(188, 284), Vector2(376, 568))
	return _get_global_rect(stomach_frame)


func _get_bottom_row_cell_count(enemy_index: int) -> int:
	var enemy := enemies[enemy_index]
	if not bool(enemy["digesting"]) or bool(enemy["digested"]):
		return 0
	var top_left: Vector2i = enemy["stomach_cell"]
	var count := 0
	for cell in _get_enemy_occupied_cells(enemy_index, top_left):
		if cell.y == STOMACH_ROWS - 1:
			count += 1
	return count


func _has_bottom_touching_nightmare() -> bool:
	for i in range(enemies.size()):
		if _get_bottom_row_cell_count(i) > 0:
			return true
	return false


func _apply_stomach_gravity() -> void:
	var moved := true
	while moved:
		moved = false
		for i in _get_active_enemy_indices_bottom_first():
			var enemy := enemies[i]
			var current_cell: Vector2i = enemy["stomach_cell"]
			var next_cell := current_cell + Vector2i(0, 1)
			if not _can_place_enemy_at(i, next_cell):
				continue
			enemy["stomach_cell"] = next_cell
			enemies[i] = enemy
			enemy_nodes[i].global_position = _get_stomach_area_center(next_cell, ENEMY_STOMACH_SIZES[i])
			moved = true


func _get_active_enemy_indices_bottom_first() -> Array[int]:
	var indices: Array[int] = []
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if bool(enemy["digesting"]) and not bool(enemy["digested"]):
			indices.append(i)
	indices.sort_custom(_sort_enemy_indices_by_bottom_row)
	return indices


func _sort_enemy_indices_by_bottom_row(a: int, b: int) -> bool:
	return _get_enemy_bottom_row(a) > _get_enemy_bottom_row(b)


func _get_enemy_bottom_row(enemy_index: int) -> int:
	var enemy := enemies[enemy_index]
	var top_left: Vector2i = enemy["stomach_cell"]
	var bottom_row := 0
	for cell in _get_enemy_occupied_cells(enemy_index, top_left):
		bottom_row = maxi(bottom_row, cell.y)
	return bottom_row


func _can_place_enemy_at(enemy_index: int, top_left: Vector2i) -> bool:
	var cells := _get_enemy_occupied_cells(enemy_index, top_left)
	if not _is_enemy_within_stomach_bounds(enemy_index, top_left):
		return false
	for other_index in range(enemies.size()):
		if other_index == enemy_index:
			continue
		var other := enemies[other_index]
		if not bool(other["digesting"]) or bool(other["digested"]):
			continue
		var other_top_left: Vector2i = other["stomach_cell"]
		for cell in cells:
			if _get_enemy_occupied_cells(other_index, other_top_left).has(cell):
				return false
	return true


func _is_enemy_within_stomach_bounds(enemy_index: int, top_left: Vector2i) -> bool:
	for cell in _get_enemy_occupied_cells(enemy_index, top_left):
		if cell.x < 0 or cell.x >= STOMACH_COLUMNS or cell.y < 0 or cell.y >= STOMACH_ROWS:
			return false
	return true


func _get_enemy_occupied_cells(enemy_index: int, top_left: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in _get_enemy_shape_offsets(enemy_index):
		var offset_cell: Vector2i = offset
		cells.append(top_left + offset_cell)
	return cells


func _get_enemy_shape_offsets(enemy_index: int) -> Array:
	return ENEMY_STOMACH_SHAPES[enemy_index]


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
