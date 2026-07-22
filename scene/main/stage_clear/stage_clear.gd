extends Node2D

signal selection_finished(recovered_hp_rate: float)

const ABANDON_HP_RECOVERY_RATE := 0.1
const CLEAR_RECOVERY_START_HOUR := 22
const CLEAR_RECOVERY_END_HOUR := 27
const CLEAR_RECOVERY_BASE_RATE := 0.5
const CLEAR_RECOVERY_HOURLY_LOSS_RATE := 0.1
const MAX_HP := 100
const BATTLE_START_MINUTES := 22 * 60
const REST_MINUTES := 30
const REST_HP_RATE := 0.1
const MAX_EQUIPPED_SEEDS := 6

@export var max_flowers := MAX_EQUIPPED_SEEDS
@export var initial_flower: SeedInfo
@export var seed_options: Array[SeedInfo] = []

# 表示エリア
@onready var character_area: StageClearCharacter = $CharacterArea
# 操作UI
@onready var ui: StageClearUi = $UI

var planted_flowers: Array[SeedInfo] = []
var stored_seeds: Array[SeedInfo] = []
var current_hp := MAX_HP
var clear_minutes := CLEAR_RECOVERY_START_HOUR * 60
var permanent_acid_damage_bonus_rate := 0.0
var debug_numbers_visible := false

var _clear_recovery_applied := false
var _selected_rewerd_effect_applied := false
var _remaining_extra_seed_choices := 0
var _extra_seed_choice_granted := false
var _seed_choice_active := false
var _base_seed_options: Array[SeedInfo] = []
var _current_clear_stage: StageInfo
var _stomach_columns := RunState.DEFAULT_STOMACH_COLUMNS
var _stomach_rows := RunState.DEFAULT_STOMACH_ROWS
var reward_service := StageClearReward.new()


# 初期化
func _ready() -> void:
	_cache_base_seed_options()
	_initialize_planted_flowers()
	_connect_ui_signals()
	_connect_debug_state()
	_set_debug_numbers_visible(DebugState.debug_enabled)
	_set_hp(current_hp, false)
	_show_select_mode()


# HP設定
func setup_hp(value: int) -> void:
	_set_clear_hp_state(value)
	_current_clear_stage = null
	_restore_base_seed_options()
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()


# clear結果設定
func setup_clear_result(
	value: int,
	cleared_minutes: int,
	cleared_stage: StageInfo = null,
	stomach_columns: int = RunState.DEFAULT_STOMACH_COLUMNS,
	stomach_rows: int = RunState.DEFAULT_STOMACH_ROWS
) -> void:
	_set_clear_result_state(value, cleared_minutes)
	_current_clear_stage = cleared_stage
	_stomach_columns = maxi(1, stomach_columns)
	_stomach_rows = maxi(1, stomach_rows)
	_restore_base_seed_options()
	_apply_stage_drop_options(cleared_stage)
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()


# player初期化
func reset_player_state() -> void:
	_reset_clear_state()
	_current_clear_stage = null
	_restore_base_seed_options()
	_initialize_planted_flowers()
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()


# HP取得
func get_current_hp() -> int:
	return current_hp


# 花取得
func get_planted_flowers() -> Array[SeedInfo]:
	var flowers: Array[SeedInfo] = []
	for flower in planted_flowers:
		if flower != null:
			flowers.append(flower)
	return flowers


# 所持種取得
func get_stored_seeds() -> Array[SeedInfo]:
	var seeds: Array[SeedInfo] = []
	for seed in stored_seeds:
		if seed != null:
			seeds.append(seed)
	return seeds


# 種inventory設定
func set_seed_inventory(equipped_seeds: Array, possession_seeds: Array) -> void:
	planted_flowers.clear()
	stored_seeds.clear()
	for source in equipped_seeds:
		if not (source is SeedInfo):
			continue
		if planted_flowers.size() < MAX_EQUIPPED_SEEDS:
			planted_flowers.append(source as SeedInfo)
		else:
			stored_seeds.append(source as SeedInfo)
	for source in possession_seeds:
		if source is SeedInfo:
			stored_seeds.append(source as SeedInfo)
	if is_node_ready():
		_refresh_after_reward_state_changed()


# 永続酸率取得
func get_permanent_acid_damage_bonus_rate() -> float:
	return permanent_acid_damage_bonus_rate


# 花削除
func remove_planted_flower(source: Resource) -> void:
	if source == null:
		return
	var equipped_index := planted_flowers.find(source)
	if equipped_index >= 0:
		planted_flowers.remove_at(equipped_index)
	else:
		var stored_index := stored_seeds.find(source)
		if stored_index >= 0:
			stored_seeds.remove_at(stored_index)
	if is_node_ready():
		_refresh_after_reward_state_changed()


# UI信号接続
func _connect_ui_signals() -> void:
	ui.seed_choice_pressed.connect(_on_seed_choice_pressed)
	ui.seed_choice_hovered.connect(_on_seed_choice_mouse_entered)
	ui.seed_choice_unhovered.connect(_on_seed_choice_mouse_exited)
	ui.abandon_pressed.connect(_on_abandon_button_pressed)
	ui.abandon_hovered.connect(_on_abandon_button_mouse_entered)
	ui.abandon_unhovered.connect(_on_abandon_button_mouse_exited)
	ui.reroll_pressed.connect(_on_reroll_button_pressed)
	ui.debug_pressed.connect(_on_debug_button_pressed)
	ui.hp_tooltip_requested.connect(_on_hp_tooltip_requested)
	ui.hp_tooltip_hide_requested.connect(_on_hp_tooltip_hide_requested)


# 花初期化
func _initialize_planted_flowers() -> void:
	planted_flowers.clear()
	stored_seeds.clear()
	if initial_flower != null:
		planted_flowers.append(initial_flower)
	if is_node_ready():
		character_area.set_planted_flowers(get_planted_flowers())


# clear初期化
func _reset_clear_state() -> void:
	current_hp = MAX_HP
	clear_minutes = CLEAR_RECOVERY_START_HOUR * 60
	permanent_acid_damage_bonus_rate = 0.0
	_clear_recovery_applied = false
	_selected_rewerd_effect_applied = false
	_reset_extra_seed_choices()


# HP状態設定
func _set_clear_hp_state(value: int) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	_clear_recovery_applied = false
	_selected_rewerd_effect_applied = false
	_reset_extra_seed_choices()


# 結果状態設定
func _set_clear_result_state(value: int, cleared_minutes: int) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	clear_minutes = cleared_minutes
	_clear_recovery_applied = false
	_selected_rewerd_effect_applied = false
	_reset_extra_seed_choices()


# base種保持
func _cache_base_seed_options() -> void:
	_base_seed_options = seed_options.duplicate()


# base種復元
func _restore_base_seed_options() -> void:
	if _base_seed_options.is_empty():
		return
	seed_options = reward_service.get_stage_seed_options(_base_seed_options, null)


# drop種適用
func _apply_stage_drop_options(stage: StageInfo) -> void:
	seed_options = reward_service.get_stage_seed_options(_base_seed_options, stage)


# 種取得
func _get_seed_option(seed_index: int) -> SeedInfo:
	if seed_index < 0 or seed_index >= seed_options.size():
		return null
	return seed_options[seed_index]


# 種名取得
func _get_seed_display_name(seed: SeedInfo) -> String:
	return seed.display_name


# debug押下
func _on_debug_button_pressed() -> void:
	DebugState.toggle_debug_enabled()


# HPツール表示
func _on_hp_tooltip_requested(anchor_global_position: Vector2) -> void:
	character_area.show_hp_tooltip_at(anchor_global_position)


# HPツール非表示
func _on_hp_tooltip_hide_requested() -> void:
	character_area.hide_hp_tooltip()


# debug接続
func _connect_debug_state() -> void:
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)


# debug変更
func _on_debug_enabled_changed(is_enabled: bool) -> void:
	_set_debug_numbers_visible(is_enabled)


# debug表示設定
func _set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	if not is_node_ready():
		return
	character_area.set_debug_numbers_visible(debug_numbers_visible)
	ui.set_debug_state(debug_numbers_visible, _seed_choice_active)


# reroll押下
func _on_reroll_button_pressed() -> void:
	if not debug_numbers_visible or not _seed_choice_active:
		return
	_reroll_seed_options()
	_refresh_after_reward_state_changed()


# 種reroll
func _reroll_seed_options() -> void:
	var skills := _get_reroll_seed_candidates()
	if skills.is_empty():
		return
	skills.shuffle()
	var rerolled_options: Array[SeedInfo] = []
	for i in range(ui.get_seed_choice_count()):
		var seed := _get_seed_option(i)
		if seed == null:
			continue
		rerolled_options.append(skills[i % skills.size()])
	seed_options = rerolled_options


# reroll候補
func _get_reroll_seed_candidates() -> Array[SeedInfo]:
	return reward_service.get_stage_seed_options(_base_seed_options, _current_clear_stage)


# 選択表示
func _show_select_mode() -> void:
	_seed_choice_active = true
	ui.show_select_mode(_get_abandon_extra_recovery_rate())
	_refresh_reward_ui()
	ui.set_debug_state(debug_numbers_visible, _seed_choice_active)


# 種押下
func _on_seed_choice_pressed(seed_index: int) -> void:
	var seed := _get_seed_option(seed_index)
	if seed == null:
		return
	if not _can_receive_seed(seed):
		return
	character_area.set_planned_recovery_rate(_get_seed_choice_recovery_rate(seed_index))
	if _can_plant_seed(seed):
		planted_flowers.append(seed)
		_refresh_after_reward_state_changed()
		var recovered_rate := _apply_selection_recovery(0.0)
		_finish_seed_choice(recovered_rate, "%sを植えました" % _get_seed_display_name(seed))
		return
	stored_seeds.append(seed)
	_refresh_after_reward_state_changed()
	var stored_recovered_rate := _apply_selection_recovery(0.0)
	_finish_seed_choice(stored_recovered_rate, "%sを所持枠へ加えました" % _get_seed_display_name(seed))


# 放棄押下
func _on_abandon_button_pressed() -> void:
	character_area.set_planned_recovery_rate(_get_abandon_recovery_rate())
	var recovery_rate := _apply_selection_recovery(_get_abandon_extra_recovery_rate())
	selection_finished.emit(recovery_rate)
	if recovery_rate > 0.0:
		_show_finished_mode("種を放棄してHPを回復しました")
	else:
		_show_finished_mode("種を放棄しました")


# 完了表示
func _show_finished_mode(message: String) -> void:
	_seed_choice_active = false
	ui.show_finished_mode(message)
	ui.set_debug_state(debug_numbers_visible, _seed_choice_active)
	_update_hp_heal_plan()


# 植え付け可否
func _can_plant_seed(seed: SeedInfo) -> bool:
	return reward_service.can_plant_seed(seed, planted_flowers, max_flowers)


# 入手可否
func _can_receive_seed(seed: SeedInfo) -> bool:
	return reward_service.can_receive_seed(seed, _get_all_owned_seeds())


# 種選択完了
func _finish_seed_choice(recovered_rate: float, message: String) -> void:
	if _remaining_extra_seed_choices > 0:
		_remaining_extra_seed_choices -= 1
		_show_select_mode()
		return
	selection_finished.emit(recovered_rate)
	_show_finished_mode(message)


# clear回復率
func _get_planned_clear_recovery_rate() -> float:
	return StageClearCalculatorRecovery.get_planned_recovery_rate(
		planted_flowers,
		clear_minutes,
		_clear_recovery_applied,
		CLEAR_RECOVERY_START_HOUR,
		CLEAR_RECOVERY_END_HOUR,
		CLEAR_RECOVERY_BASE_RATE,
		CLEAR_RECOVERY_HOURLY_LOSS_RATE
	)


# 種回復率
func _get_seed_choice_recovery_rate(seed_index: int) -> float:
	if _clear_recovery_applied:
		return 0.0
	var seed := _get_seed_option(seed_index)
	if seed == null:
		return _get_planned_clear_recovery_rate()
	return StageClearCalculatorRecovery.get_planned_recovery_rate(
		_get_preview_flowers_for_seed(seed),
		clear_minutes,
		false,
		CLEAR_RECOVERY_START_HOUR,
		CLEAR_RECOVERY_END_HOUR,
		CLEAR_RECOVERY_BASE_RATE,
		CLEAR_RECOVERY_HOURLY_LOSS_RATE
	)


# 放棄回復率
func _get_abandon_recovery_rate() -> float:
	if _clear_recovery_applied:
		return 0.0
	return _get_planned_clear_recovery_rate() + _get_abandon_extra_recovery_rate()


# 放棄追加回復
func _get_abandon_extra_recovery_rate() -> float:
	if _clear_recovery_applied:
		return 0.0
	if StageClearCalculatorRecovery.is_clear_time_recovery_disabled(planted_flowers, clear_minutes):
		return 0.0
	return ABANDON_HP_RECOVERY_RATE


# preview花取得
func _get_preview_flowers_for_seed(seed: SeedInfo) -> Array[SeedInfo]:
	return reward_service.get_preview_flowers_for_seed(seed, planted_flowers, max_flowers)


# 全所有種取得
func _get_all_owned_seeds() -> Array[SeedInfo]:
	var seeds := get_planted_flowers()
	seeds.append_array(get_stored_seeds())
	return seeds


# 追加選択初期化
func _reset_extra_seed_choices() -> void:
	_remaining_extra_seed_choices = 0
	_extra_seed_choice_granted = false


# 回復適用
func _apply_selection_recovery(extra_recovery_rate: float) -> float:
	var rewerd_context := _apply_selected_rewerd_effects() # 報酬効果
	var recovery_rate := 0.0 # 回復率
	if not _clear_recovery_applied:
		recovery_rate = _get_selected_rewerd_recovery_rate(rewerd_context) + extra_recovery_rate
		var recovered_hp := mini(MAX_HP, current_hp + ceili(float(MAX_HP) * recovery_rate)) # 回復HP
		_clear_recovery_applied = true
		_set_hp(recovered_hp, true)
	return recovery_rate


# 報酬効果適用
func _apply_selected_rewerd_effects() -> Dictionary:
	if _selected_rewerd_effect_applied:
		return {}
	var context := StageClearCalculatorRecovery.get_selected_rewerd_context(planted_flowers, clear_minutes) # 文脈
	permanent_acid_damage_bonus_rate += float(context.get("permanent_acid_rate", 0.0))
	var extra_count := int(context.get("extra_seed_choice_count", 0)) # 追加数
	if not _extra_seed_choice_granted and extra_count > 0:
		_remaining_extra_seed_choices += extra_count
		_extra_seed_choice_granted = true
	_selected_rewerd_effect_applied = true
	return context


# 報酬回復率
func _get_selected_rewerd_recovery_rate(rewerd_context: Dictionary) -> float:
	var recovery_rate := StageClearCalculatorRecovery.get_clear_time_recovery_rate(
		planted_flowers,
		clear_minutes,
		CLEAR_RECOVERY_START_HOUR,
		CLEAR_RECOVERY_END_HOUR,
		CLEAR_RECOVERY_BASE_RATE,
		CLEAR_RECOVERY_HOURLY_LOSS_RATE
	)
	recovery_rate += float(rewerd_context.get("hp_recovery_rate", 0.0))
	return recovery_rate


# 状態変更更新
func _refresh_after_reward_state_changed() -> void:
	_refresh_reward_ui()


# 報酬UI更新
func _refresh_reward_ui() -> void:
	character_area.set_planted_flowers(get_planted_flowers())
	ui.setup_seed_choices(seed_options, _get_seed_selectable_states())
	_update_hp_tooltip_info()
	_update_hp_heal_plan()


# 種選択可否一覧
func _get_seed_selectable_states() -> Array[bool]:
	var selectable_states: Array[bool] = [] # 可否一覧
	for seed in seed_options:
		selectable_states.append(_can_receive_seed(seed))
	return selectable_states


# HP設定内部
func _set_hp(value: int, animated: bool) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	character_area.set_hp(current_hp, MAX_HP, animated)
	_update_hp_tooltip_info()
	_update_hp_heal_plan()


# HPツール情報更新
func _update_hp_tooltip_info() -> void:
	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup(planted_flowers)
	character_area.set_hp_tooltip_info(
		REST_MINUTES,
		REST_HP_RATE,
		seed_effects.get_rest_recovery_bonus_rate()
	)


# 回復予定更新
func _update_hp_heal_plan() -> void:
	var recovery_rate := _get_planned_clear_recovery_rate()
	character_area.set_planned_recovery_rate(recovery_rate)
	_update_status_preview(planted_flowers, recovery_rate)


# 種hover開始
func _on_seed_choice_mouse_entered(seed_index: int) -> void:
	var recovery_rate := _get_seed_choice_recovery_rate(seed_index)
	character_area.set_planned_recovery_rate(recovery_rate)
	var seed := _get_seed_option(seed_index)
	_update_status_preview(_get_preview_flowers_for_seed(seed), recovery_rate)


# 種hover終了
func _on_seed_choice_mouse_exited() -> void:
	_update_hp_heal_plan()


# 放棄hover開始
func _on_abandon_button_mouse_entered() -> void:
	var recovery_rate := _get_abandon_recovery_rate()
	character_area.set_planned_recovery_rate(recovery_rate)
	_update_status_preview(planted_flowers, recovery_rate)


# 放棄hover終了
func _on_abandon_button_mouse_exited() -> void:
	_update_hp_heal_plan()


# 状態予測更新
func _update_status_preview(flowers: Array[SeedInfo], recovery_rate: float) -> void:
	var base_status := _get_status_preview(
		planted_flowers,
		_get_planned_clear_recovery_rate()
	)
	var preview_status := _get_status_preview(flowers, recovery_rate)
	var base_damage_info := base_status["acid_damage_info"] as Dictionary
	var base_interval_info := base_status["acid_interval_info"] as Dictionary
	ui.set_status_preview(
		base_damage_info,
		base_interval_info,
		int(base_status["hp"]),
		int((preview_status["acid_damage_info"] as Dictionary)["total"]),
		int((preview_status["acid_interval_info"] as Dictionary)["total"]),
		int(preview_status["hp"])
	)


# 状態予測取得
func _get_status_preview(flowers: Array[SeedInfo], recovery_rate: float) -> Dictionary:
	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup(flowers)
	seed_effects.add_acid_damage_bonus_rate(
		_get_preview_permanent_acid_damage_bonus_rate(flowers)
	)
	var stomach_size := _get_preview_stomach_size(flowers)
	var damage_info := seed_effects.get_acid_damage_breakdown(
		EnemyController.ACID_DAMAGE,
		0.0,
		BATTLE_START_MINUTES,
		false,
		stomach_size.x,
		stomach_size.y
	)
	var time_reduction_rate := seed_effects.get_time_reduction_rate(
		false,
		BATTLE_START_MINUTES,
		BATTLE_START_MINUTES,
		EnemyController.STEP_MINUTES
	)
	var acid_interval_minutes := maxi(
		1,
		roundi(float(EnemyController.STEP_MINUTES) * (1.0 - time_reduction_rate))
	)
	var acid_interval_info := {
		"total": acid_interval_minutes,
		"base": EnemyController.STEP_MINUTES,
		"seed_buff": acid_interval_minutes - EnemyController.STEP_MINUTES,
		"seed_rate": -time_reduction_rate,
		"nightmare_buff": 0,
		"nightmare_rate": 0.0,
	}
	var preview_hp := current_hp
	if not _clear_recovery_applied:
		preview_hp = mini(MAX_HP, current_hp + ceili(float(MAX_HP) * recovery_rate))
	return {
		"acid_damage_info": damage_info,
		"acid_interval_info": acid_interval_info,
		"hp": preview_hp,
	}


# 予測永続消化補正取得
func _get_preview_permanent_acid_damage_bonus_rate(flowers: Array[SeedInfo]) -> float:
	var rate := permanent_acid_damage_bonus_rate
	if _selected_rewerd_effect_applied:
		return rate
	var context := StageClearCalculatorRecovery.get_selected_rewerd_context(flowers, clear_minutes)
	return rate + float(context.get("permanent_acid_rate", 0.0))


# 予測胃袋サイズ取得
func _get_preview_stomach_size(flowers: Array[SeedInfo]) -> Vector2i:
	var has_column_bonus := false
	var has_row_bonus := false
	for flower in flowers:
		if flower == null or flower.get_main_skill() == null:
			continue
		var skill := flower.get_main_skill()
		has_column_bonus = has_column_bonus or skill.get_stomach_columns_delta() > 0
		has_row_bonus = has_row_bonus or skill.get_stomach_rows_delta() > 0
	return Vector2i(
		_stomach_columns + (1 if has_column_bonus else 0),
		_stomach_rows + (1 if has_row_bonus else 0)
	)
