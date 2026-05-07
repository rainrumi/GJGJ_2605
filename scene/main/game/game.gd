extends Node2D

signal battle_finished(won: bool)

const START_HOUR := 23
const END_HOUR := 30
const STEP_MINUTES := 30
const REST_MINUTES := 60
const MAX_HP := 100
const REST_HP := 50
const DIGEST_DAMAGE := 200
const DIGEST_AUTO_INTERVAL := 0.6
const REMOVE_FROM_STOMACH_DAMAGE_RATE := 0.05
const START_MESSAGE := "６時までにすべての悪夢を消化しましょう"

@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var enemies: Array[Enemy] = [
	$EnemyLeft as Enemy,
	$EnemyCenter as Enemy,
	$EnemyRight as Enemy,
]

var minutes := START_HOUR * 60
var hp := MAX_HP
var battle_active := false
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var digestion_timer: Timer
var current_message := START_MESSAGE

var dragging_enemy: Enemy
var drag_offset := Vector2.ZERO
var drag_grab_cell := Vector2i.ZERO
var dragged_enemy_was_digesting := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO
var hovered_enemy: Enemy


func _ready() -> void:
	ui.digestion_requested.connect(_on_digestion_requested)
	_create_digestion_timer()
	_setup_enemies()
	start_battle()


func start_battle() -> void:
	minutes = START_HOUR * 60
	hp = MAX_HP
	battle_active = true
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	if digestion_timer != null and not digestion_timer.is_stopped():
		digestion_timer.stop()
	dragging_enemy = null
	hovered_enemy = null
	for enemy in enemies:
		enemy.reset_for_battle()
	current_message = START_MESSAGE
	ui.reset_for_battle(MAX_HP, minutes, current_message)
	_refresh_ui()
	stomach.hide_preview()


func _process(_delta: float) -> void:
	if not battle_active:
		_set_hovered_enemy(null)
		return
	var mouse_position := get_viewport().get_mouse_position()
	if dragging_enemy != null:
		dragging_enemy.global_position = mouse_position + drag_offset
		stomach.show_preview(dragging_enemy, mouse_position, drag_grab_cell, enemies)
		_update_hp_damage_preview(mouse_position)
		_set_hovered_enemy(null)
		return
	_update_enemy_hover(mouse_position)


func _input(event: InputEvent) -> void:
	if not battle_active:
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_handle_press(mouse_button.position)
		else:
			_handle_release(mouse_button.position)


func _handle_press(mouse_position: Vector2) -> void:
	if ui.is_digestion_button_hit(mouse_position):
		_on_digestion_requested()
		return
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if not enemy.can_drag():
			continue
		if enemy.get_global_rect().has_point(mouse_position):
			dragging_enemy = enemy
			drag_offset = enemy.global_position - mouse_position
			drag_grab_cell = enemy.get_grab_cell(mouse_position)
			dragged_enemy_was_digesting = enemy.digesting
			dragged_enemy_original_cell = enemy.stomach_cell
			dragged_enemy_original_global_position = enemy.global_position
			auto_digest_paused_for_drag = auto_digest_enabled
			_update_auto_digest_timer()
			return


func _handle_release(mouse_position: Vector2) -> void:
	if dragging_enemy == null:
		return
	var released_enemy := dragging_enemy
	dragging_enemy = null
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	if stomach.contains_global_position(mouse_position):
		_try_start_digesting(released_enemy, mouse_position)
	else:
		_remove_enemy_from_stomach(released_enemy)
	if auto_digest_enabled:
		auto_digest_paused_for_drag = false
	_update_auto_digest_timer()


func _setup_enemies() -> void:
	var definitions := _build_enemy_definitions()
	for i in range(enemies.size()):
		var definition := definitions[i]
		enemies[i].setup(
			definition,
			Vector2(
				stomach.get_span_size(definition.stomach_size.x),
				stomach.get_span_size(definition.stomach_size.y)
			)
		)


func _build_enemy_definitions() -> Array[EnemyDefinition]:
	var definitions: Array[EnemyDefinition] = []
	definitions.append(_create_enemy_definition(
		"Adult nightmare",
		preload("res://art/enemy/tex_enemy_1000_No_100.png"),
		1400,
		6,
		2,
		Vector2(850, 500),
		Vector2i(2, 3),
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
	))
	definitions.append(_create_enemy_definition(
		"Overeating nightmare",
		preload("res://art/enemy/tex_enemy_1000_No_200.png"),
		1000,
		5,
		3,
		Vector2(1000, 280),
		Vector2i(3, 3),
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
	))
	definitions.append(_create_enemy_definition(
		"Chased nightmare",
		preload("res://art/enemy/tex_enemy_1000_No_300.png"),
		2000,
		3,
		5,
		Vector2(1150, 500),
		Vector2i(2, 2),
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	))
	return definitions


func _create_enemy_definition(
	display_name: String,
	texture: Texture2D,
	max_hp: int,
	size: int,
	damage: int,
	start_position: Vector2,
	stomach_size: Vector2i,
	stomach_shape: Array[Vector2i]
) -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	definition.display_name = display_name
	definition.texture = texture
	definition.max_hp = max_hp
	definition.size = size
	definition.damage = damage
	definition.start_position = start_position
	definition.stomach_size = stomach_size
	definition.stomach_shape = stomach_shape
	return definition


func _create_digestion_timer() -> void:
	digestion_timer = Timer.new()
	digestion_timer.name = "AutoDigestionTimer"
	digestion_timer.wait_time = DIGEST_AUTO_INTERVAL
	digestion_timer.one_shot = false
	digestion_timer.timeout.connect(_on_digestion_timer_timeout)
	add_child(digestion_timer)


func _on_digestion_requested() -> void:
	if not battle_active:
		return
	if _active_digest_count() == 0:
		_advance_digest_turn()
		return
	auto_digest_enabled = true
	auto_digest_paused_for_drag = false
	if not stomach.has_bottom_touching_enemy(enemies):
		stomach.apply_gravity(enemies)
	_refresh_ui()
	_advance_digest_turn()


func _on_digestion_timer_timeout() -> void:
	if not auto_digest_enabled or auto_digest_paused_for_drag:
		_update_auto_digest_timer()
		return
	_advance_digest_turn()


func _try_start_digesting(enemy: Enemy, mouse_position: Vector2) -> void:
	var next_fullness := stomach.get_current_fullness(enemies)
	if not dragged_enemy_was_digesting:
		next_fullness += enemy.get_size()
	if next_fullness > stomach.get_capacity():
		_return_dragged_enemy(enemy)
		_set_status_message("胃袋がいっぱいで置けません")
		return
	var top_left := stomach.get_drop_cell(enemy, mouse_position, drag_grab_cell, enemies)
	if not stomach.can_place(enemy, top_left, enemies):
		_return_dragged_enemy(enemy)
		_set_status_message("その場所には置けません")
		return
	enemy.set_digesting(true)
	stomach.place_enemy(enemy, top_left)
	_set_status_message("")


func _return_dragged_enemy(enemy: Enemy) -> void:
	if dragged_enemy_was_digesting:
		enemy.set_digesting(true)
		enemy.set_stomach_cell(dragged_enemy_original_cell)
		enemy.global_position = dragged_enemy_original_global_position
		return
	enemy.return_to_origin()


func _remove_enemy_from_stomach(enemy: Enemy) -> void:
	if not dragged_enemy_was_digesting:
		enemy.return_to_origin()
		return
	enemy.set_digesting(false)
	enemy.return_to_origin()
	hp = maxi(0, hp - _get_remove_from_stomach_damage())
	_set_status_message("悪夢を外したのでダメージを受けました")


func _advance_digest_turn() -> void:
	if _active_digest_count() == 0:
		auto_digest_enabled = false
		_set_status_message("消化中の悪夢がありません")
		return
	var elapsed_minutes := STEP_MINUTES
	_digest_nightmares()
	_apply_digest_damage()
	minutes += STEP_MINUTES
	if hp <= 0:
		hp = REST_HP
		minutes += REST_MINUTES
		elapsed_minutes += REST_MINUTES
		_set_status_message("HPが尽きたため休憩しました")
	else:
		_set_status_message("")
	ui.show_time_elapsed(elapsed_minutes)
	_check_battle_end()
	_update_auto_digest_timer()


func _digest_nightmares() -> void:
	var digested_any := false
	for enemy in enemies:
		var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
		if bottom_cell_count == 0:
			continue
		if enemy.take_digest_damage(DIGEST_DAMAGE * bottom_cell_count):
			digested_any = true
		enemy.pulse_cost_label()
	if digested_any:
		stomach.apply_gravity(enemies)


func _apply_digest_damage() -> void:
	var damage := 0
	for enemy in enemies:
		if enemy.is_active_in_stomach():
			damage += enemy.get_damage()
	hp -= damage


func _check_battle_end() -> void:
	if _all_enemies_digested():
		battle_active = false
		auto_digest_enabled = false
		_update_auto_digest_timer()
		_set_status_message("すべての悪夢を消化しました")
		battle_finished.emit(true)
		return
	if minutes >= END_HOUR * 60:
		battle_active = false
		auto_digest_enabled = false
		_update_auto_digest_timer()
		_set_status_message("朝までに消化しきれませんでした")
		battle_finished.emit(false)


func _all_enemies_digested() -> bool:
	for enemy in enemies:
		if not enemy.digested:
			return false
	return true


func _active_digest_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.is_active_in_stomach():
			count += 1
	return count


func _get_remove_from_stomach_damage() -> int:
	return ceili(float(MAX_HP) * REMOVE_FROM_STOMACH_DAMAGE_RATE)


func _update_auto_digest_timer() -> void:
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
	_refresh_ui()


func _update_enemy_hover(mouse_position: Vector2) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if not enemy.can_drag() or not enemy.visible:
			continue
		if enemy.get_global_rect().has_point(mouse_position):
			_set_hovered_enemy(enemy)
			return
	_set_hovered_enemy(null)


func _set_hovered_enemy(enemy: Enemy) -> void:
	if hovered_enemy == enemy:
		return
	if hovered_enemy != null:
		hovered_enemy.set_hovered(false)
	hovered_enemy = enemy
	if hovered_enemy != null:
		hovered_enemy.set_hovered(true)


func _update_hp_damage_preview(mouse_position: Vector2) -> void:
	if dragged_enemy_was_digesting and not stomach.contains_global_position(mouse_position):
		ui.show_hp_damage_preview(_get_remove_from_stomach_damage())
	else:
		ui.hide_hp_damage_preview()


func _set_status_message(message: String) -> void:
	current_message = message
	ui.set_message(current_message)
	ui.set_debug_message(current_message)
	_refresh_ui()


func _refresh_ui() -> void:
	ui.set_hp(hp, MAX_HP)
	ui.set_time(minutes)
	ui.set_digestion_count(_active_digest_count())
	ui.set_digestion_button_visible(battle_active and not auto_digest_enabled)
