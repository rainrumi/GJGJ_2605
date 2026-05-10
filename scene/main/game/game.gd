extends Node2D

signal battle_finished(won: bool)

const START_HOUR := 22
const END_HOUR := 30
const STEP_MINUTES := 30
const REST_MINUTES := 60
const MAX_HP := 100
const REST_HP_RATE := 0.1
const DIGEST_DAMAGE := 200
const DIGEST_AUTO_INTERVAL := 0.6
const REMOVE_FROM_STOMACH_DAMAGE_RATE := 0.05
const START_MESSAGE := "６時までにすべての悪夢を消化しましょう"
const ENEMY_TOP_Y := 280.0
const ENEMY_BOTTOM_Y := 500.0
const ENEMY_LEFT_X := 850.0
const ENEMY_CENTER_X := 1000.0
const ENEMY_RIGHT_X := 1150.0

@export var enemy_definitions: Array[Resource] = []
@export var nightmare_skill_catalog: NightmareSkillCatalog

@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var click_se: AudioStreamPlayer = $ClickSe
@onready var nightmare_tooltip_panel: Panel = $UI/NightmareTooltipPanel
@onready var nightmare_name_label: Label = $UI/NightmareTooltipPanel/Content/NameLabel
@onready var nightmare_category_label: Label = $UI/NightmareTooltipPanel/Content/CategoryLabel
@onready var nightmare_category_detail_label: Label = $UI/NightmareTooltipPanel/Content/CategoryDetailLabel
@onready var nightmare_status_title_label: Label = $UI/NightmareTooltipPanel/Content/StatusTitleLabel
@onready var nightmare_hp_label: Label = $UI/NightmareTooltipPanel/Content/HpLabel
@onready var nightmare_damage_label: Label = $UI/NightmareTooltipPanel/Content/DamageLabel
@onready var nightmare_main_effect_label: Label = $UI/NightmareTooltipPanel/Content/MainEffectLabel
@onready var nightmare_sub_effect_label: Label = $UI/NightmareTooltipPanel/Content/SubEffectLabel
@onready var enemies: Array[Enemy] = [
	$EnemyLeft as Enemy,
	$EnemyCenter as Enemy,
	$EnemyRight as Enemy,
	$EnemyUpperRight as Enemy,
]

var minutes := START_HOUR * 60
var hp := MAX_HP
var battle_active := false
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var digest_turn_in_progress := false
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
	randomize()
	ui.digestion_requested.connect(_on_digestion_requested)
	_create_digestion_timer()
	_hide_nightmare_tooltip()


func start_battle(starting_hp: int = MAX_HP, _day: int = 1) -> void:
	minutes = START_HOUR * 60
	hp = clampi(starting_hp, 0, MAX_HP)
	battle_active = false
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	digest_turn_in_progress = false
	if digestion_timer != null and not digestion_timer.is_stopped():
		digestion_timer.stop()
	dragging_enemy = null
	hovered_enemy = null
	_setup_enemies()
	current_message = START_MESSAGE
	ui.reset_for_battle(MAX_HP, minutes, current_message)
	_refresh_ui()
	stomach.hide_preview()
	battle_active = true
	_refresh_ui()


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
			_play_click_se()
			return


func _handle_release(mouse_position: Vector2) -> void:
	if dragging_enemy == null:
		return
	var released_enemy := dragging_enemy
	dragging_enemy = null
	_play_click_se()
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
	var selected_skills := _get_random_nightmare_skills()
	var enemy_positions := _get_enemy_positions(selected_skills.size())
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if i >= selected_skills.size():
			enemy.visible = false
			enemy.digested = true
			enemy.digesting = false
			continue
		var definition := _get_enemy_template(i)
		if definition == null:
			continue
		enemy.setup(
			definition,
			Vector2(
				stomach.get_span_size(definition.stomach_size.x),
				stomach.get_span_size(definition.stomach_size.y)
			),
			selected_skills[i],
			enemy_positions[i]
		)


func _get_random_nightmare_skills() -> Array[NightmareSkillDefinition]:
	if nightmare_skill_catalog == null or nightmare_skill_catalog.skills.is_empty():
		return []
	var skills_by_category: Dictionary = {}
	for skill in nightmare_skill_catalog.skills:
		if skill == null:
			continue
		var category := skill.category
		if category.is_empty():
			category = "通常"
		if not skills_by_category.has(category):
			skills_by_category[category] = []
		skills_by_category[category].append(skill)
	var categories := skills_by_category.keys()
	if categories.is_empty():
		return []
	var category = categories[randi() % categories.size()]
	var category_skills: Array = skills_by_category[category].duplicate()
	category_skills.shuffle()
	var max_count := mini(4, category_skills.size())
	var min_count := mini(2, max_count)
	var count := randi_range(min_count, max_count)
	var selected: Array[NightmareSkillDefinition] = []
	for i in range(count):
		selected.append(category_skills[i] as NightmareSkillDefinition)
	return selected


func _get_enemy_template(enemy_index: int) -> EnemyDefinition:
	if enemy_definitions.is_empty():
		return null
	var template := enemy_definitions[enemy_index % enemy_definitions.size()] as EnemyDefinition
	return template


func _get_enemy_positions(enemy_count: int) -> Array[Vector2]:
	var middle_y := (ENEMY_TOP_Y + ENEMY_BOTTOM_Y) * 0.5
	var positions: Array[Vector2] = []
	match enemy_count:
		2:
			positions = [
				Vector2(ENEMY_LEFT_X, middle_y),
				Vector2(ENEMY_RIGHT_X, middle_y),
			]
		4:
			positions = [
				Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_TOP_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_LEFT_X, ENEMY_TOP_Y),
			]
		_:
			positions = [
				Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_CENTER_X, ENEMY_TOP_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
			]
	return positions


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
	if digest_turn_in_progress:
		return
	digest_turn_in_progress = true
	if _active_digest_count() == 0:
		auto_digest_enabled = false
		_set_status_message("消化中の悪夢がありません")
		digest_turn_in_progress = false
		return
	var elapsed_minutes := STEP_MINUTES
	var digested_any := _digest_nightmares()
	_apply_digest_damage()
	if digested_any:
		await get_tree().create_timer(Enemy.DIGESTED_TWEEN_DURATION).timeout
		stomach.apply_gravity(enemies)
	minutes += STEP_MINUTES
	if hp <= 0:
		hp = _get_rest_hp()
		minutes += REST_MINUTES
		elapsed_minutes += REST_MINUTES
		_set_status_message("HPが尽きたため休憩しました")
	else:
		_set_status_message("")
	ui.show_time_elapsed(elapsed_minutes)
	_check_battle_end()
	_update_auto_digest_timer()
	digest_turn_in_progress = false


func _digest_nightmares() -> bool:
	var digested_any := false
	for enemy in enemies:
		var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
		if bottom_cell_count == 0:
			continue
		if enemy.take_digest_damage(DIGEST_DAMAGE * bottom_cell_count):
			digested_any = true
		enemy.pulse_cost_label()
	return digested_any


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


func _get_rest_hp() -> int:
	return ceili(float(MAX_HP) * REST_HP_RATE)


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
		_show_nightmare_tooltip(hovered_enemy)
	else:
		_hide_nightmare_tooltip()


func _show_nightmare_tooltip(enemy: Enemy) -> void:
	nightmare_name_label.text = enemy.get_display_name()
	nightmare_category_label.text = enemy.get_category_name()
	nightmare_category_detail_label.text = enemy.get_category_detail()
	nightmare_status_title_label.text = "ステータス"
	nightmare_hp_label.text = "HP: %d" % enemy.definition.max_hp
	nightmare_damage_label.text = "攻撃力: %d" % enemy.definition.damage
	nightmare_main_effect_label.text = "メイン効果: %s" % _get_effect_text(enemy.get_main_effect_text())
	nightmare_sub_effect_label.text = "サブ効果: %s" % _get_effect_text(enemy.get_sub_effect_text())
	nightmare_tooltip_panel.visible = true


func _hide_nightmare_tooltip() -> void:
	nightmare_tooltip_panel.visible = false


func _get_effect_text(text: String) -> String:
	if text.is_empty():
		return "-"
	return text


func _update_hp_damage_preview(mouse_position: Vector2) -> void:
	if dragged_enemy_was_digesting and not stomach.contains_global_position(mouse_position):
		ui.show_hp_damage_preview(_get_remove_from_stomach_damage())
	else:
		ui.hide_hp_damage_preview()


func _set_status_message(message: String) -> void:
	ui.set_message(START_MESSAGE)
	ui.set_debug_message(message)
	_refresh_ui()


func _play_click_se() -> void:
	if click_se == null:
		return
	click_se.stop()
	click_se.play()


func _refresh_ui() -> void:
	ui.set_hp(hp, MAX_HP)
	ui.set_time(minutes)
	ui.set_digestion_count(_active_digest_count())
	ui.set_digestion_button_visible(battle_active and not auto_digest_enabled)


func get_current_hp() -> int:
	return hp


func get_max_hp() -> int:
	return MAX_HP
