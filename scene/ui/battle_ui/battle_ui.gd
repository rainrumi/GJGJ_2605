class_name BattleUI
extends CanvasLayer

signal digestion_requested
signal debug_message_requested(is_active: bool)
signal debug_reroll_requested
signal debug_stomach_size_requested(delta_columns: int, delta_rows: int)
signal debug_seed_requested
signal seed_skill_drag_started(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)
signal seed_skill_drag_moved(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)
signal seed_skill_drag_released(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)

@onready var digest_damage_panel: Control = $DigestiveDMG
@onready var digest_damage_icon: Control = $DigestiveDMG/digestiveDMG_icon
@onready var digest_damage_value_label: Label = $DigestiveDMG/digestiveDMG_value
@onready var digest_efficiency_panel: Control = $DigestiveINTERVAL
@onready var digest_efficiency_icon: Control = $DigestiveINTERVAL/digestiveINTERVAL_icon
@onready var digest_efficiency_value_label: Label = $DigestiveINTERVAL/digestiveINTERVAL_value
@onready var hp_status: HpView = $HpFrame
@onready var dream_seed_skill_buttons: DreamSeedSkillButtonList = $DreamSeedSkillButtons
@onready var time_status: TimeStatusView = $Time
@onready var digestion_button: DigestionButtonView = $DigestionFrame
@onready var status_panel: StatusPanelView = $StatusPanel
@onready var nightmare_tooltip: NightmareTooltipView = $NightmareTooltipPanel
@onready var digest_tooltip: DigestDamageTooltipView = $DigestDamageTooltipPanel
@onready var efficiency_tooltip: DigestEfficiencyTooltipView = $DigestEfficiencyTooltipPanel
@onready var time_tooltip: TimeTooltipView = $TimeTooltipPanel
@onready var hp_tooltip: HpTooltipView = $HpTooltipPanel

var _rest_minutes := 30
var _rest_hp_rate := 0.1
var _rest_recovery_bonus_rate := 0.0


func _ready() -> void:
	_prepare_digest_mouse_filters()
	dream_seed_skill_buttons.set_sub_skill_drag_enabled(true)
	_connect_child_signals()
	_hide_all_tooltips()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_D:
			status_panel.toggle_debug_message()
		if key_event.keycode == KEY_R:
			status_panel.request_debug_reroll()


func reset_for_battle(
	max_hp: int,
	minutes: int,
	message: String,
	rest_minutes: int = 30,
	rest_hp_rate: float = 0.1,
	rest_recovery_bonus_rate: float = 0.0
) -> void:
	_rest_minutes = rest_minutes
	_rest_hp_rate = rest_hp_rate
	_rest_recovery_bonus_rate = rest_recovery_bonus_rate
	set_hp(max_hp, max_hp)
	set_time(minutes)
	set_digest_damage(0)
	set_digest_efficiency_value(30.0)
	digest_tooltip.set_damage_info(0, 0, 0, 0.0, 0, 0.0)
	efficiency_tooltip.set_efficiency_info(30.0)
	time_tooltip.set_time_info()
	set_message(message)
	set_debug_message("")
	set_dream_seed_skill_sources([])
	set_dream_seed_debug_numbers_visible(false)
	set_debug_button_active(false)
	set_digestion_count(0)
	set_digestion_button_visible(true)
	hide_hp_damage_preview()
	hide_time_elapsed()
	_hide_all_tooltips()


func set_hp(current_hp: int, max_hp: int) -> void:
	hp_status.set_hp(current_hp, max_hp)
	hp_tooltip.set_hp_info(current_hp, max_hp, _rest_minutes, _rest_hp_rate, _rest_recovery_bonus_rate)


func set_rest_recovery_bonus_rate(rest_recovery_bonus_rate: float) -> void:
	_rest_recovery_bonus_rate = rest_recovery_bonus_rate


func set_time(minutes: int) -> void:
	time_status.set_time(minutes)


func set_message(message: String) -> void:
	status_panel.set_message(message)


func set_debug_message(message: String) -> void:
	status_panel.set_debug_message(message)


func set_dream_seed_skill_sources(sources: Array) -> void:
	dream_seed_skill_buttons.set_seed_sources(sources)


func set_dream_seed_debug_numbers_visible(is_visible: bool) -> void:
	dream_seed_skill_buttons.set_debug_numbers_visible(is_visible)


func show_nightmare_tooltip(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	_hide_all_tooltips()
	nightmare_tooltip.show_enemy_at(enemy, debug_number_text, debug_numbers_visible, enemy.global_position)


func hide_nightmare_tooltip() -> void:
	nightmare_tooltip.hide_tooltip()


func show_digest_damage_tooltip() -> void:
	_hide_all_tooltips()
	digest_tooltip.show_tooltip_at(digest_damage_panel.global_position)


func hide_digest_damage_tooltip() -> void:
	digest_tooltip.hide_tooltip()


func show_digest_efficiency_tooltip() -> void:
	_hide_all_tooltips()
	efficiency_tooltip.show_tooltip_at(digest_efficiency_panel.global_position)


func hide_digest_efficiency_tooltip() -> void:
	efficiency_tooltip.hide_tooltip()


func show_time_tooltip() -> void:
	_hide_all_tooltips()
	time_tooltip.show_tooltip_at(time_status.global_position)


func hide_time_tooltip() -> void:
	time_tooltip.hide_tooltip()


func show_hp_tooltip() -> void:
	_hide_all_tooltips()
	hp_tooltip.show_tooltip_at(hp_status.global_position)


func hide_hp_tooltip() -> void:
	hp_tooltip.hide_tooltip()


func _hide_all_tooltips() -> void:
	for tooltip in _get_tooltip_views():
		if tooltip != null and tooltip.has_method("hide_tooltip"):
			tooltip.hide_tooltip()


func _get_tooltip_views() -> Array[Object]:
	return [
		nightmare_tooltip,
		digest_tooltip,
		efficiency_tooltip,
		time_tooltip,
		hp_tooltip,
	]


func set_digest_damage_info(
	total_damage: int,
	base_damage: int,
	seed_buff: int,
	seed_rate: float,
	nightmare_buff: int,
	nightmare_rate: float
) -> void:
	set_digest_damage(total_damage)
	digest_tooltip.set_damage_info(total_damage, base_damage, seed_buff, seed_rate, nightmare_buff, nightmare_rate)


func set_digest_efficiency_minutes(
	amount_minutes: float,
	base_minutes: float = 30.0,
	seed_buff: int = 0,
	seed_rate: float = 0.0,
	nightmare_buff: int = 0,
	nightmare_rate: float = 0.0
) -> void:
	set_digest_efficiency_value(amount_minutes)
	efficiency_tooltip.set_efficiency_info(amount_minutes, base_minutes, seed_buff, seed_rate, nightmare_buff, nightmare_rate)


func set_debug_button_active(is_active: bool) -> void:
	status_panel.set_debug_button_active(is_active)


func set_digestion_count(count: int) -> void:
	digestion_button.set_count(count)


func set_digestion_button_visible(is_visible: bool) -> void:
	digestion_button.set_button_visible(is_visible)


func is_digestion_button_hit(mouse_position: Vector2) -> bool:
	return digestion_button.is_hit(mouse_position)


func show_time_elapsed(amount_minutes: int) -> void:
	time_status.show_elapsed(amount_minutes)


func hide_time_elapsed() -> void:
	time_status.hide_elapsed()


func show_hp_damage_preview(amount: int) -> void:
	hp_status.show_damage_preview(amount)


func hide_hp_damage_preview() -> void:
	hp_status.hide_damage_preview()


func show_hp_damage_values(damage_values: Array[int]) -> void:
	hp_status.show_damage_values(damage_values)


func _connect_child_signals() -> void:
	digestion_button.digestion_requested.connect(_on_digestion_requested)
	status_panel.debug_message_requested.connect(_on_debug_message_requested)
	status_panel.debug_reroll_requested.connect(_on_debug_reroll_requested)
	status_panel.debug_stomach_size_requested.connect(_on_debug_stomach_size_requested)
	status_panel.debug_seed_requested.connect(_on_debug_seed_requested)
	dream_seed_skill_buttons.seed_skill_drag_started.connect(_on_seed_skill_drag_started)
	dream_seed_skill_buttons.seed_skill_drag_moved.connect(_on_seed_skill_drag_moved)
	dream_seed_skill_buttons.seed_skill_drag_released.connect(_on_seed_skill_drag_released)
	digest_damage_panel.mouse_entered.connect(show_digest_damage_tooltip)
	digest_damage_panel.mouse_exited.connect(hide_digest_damage_tooltip)
	digest_efficiency_panel.mouse_entered.connect(show_digest_efficiency_tooltip)
	digest_efficiency_panel.mouse_exited.connect(hide_digest_efficiency_tooltip)
	time_status.mouse_entered.connect(show_time_tooltip)
	time_status.mouse_exited.connect(hide_time_tooltip)
	hp_status.mouse_entered.connect(show_hp_tooltip)
	hp_status.mouse_exited.connect(hide_hp_tooltip)


func _prepare_digest_mouse_filters() -> void:
	digest_damage_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	digest_damage_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digest_damage_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digest_efficiency_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	digest_efficiency_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digest_efficiency_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_status.mouse_filter = Control.MOUSE_FILTER_STOP
	hp_status.mouse_filter = Control.MOUSE_FILTER_STOP


func set_digest_damage(total_damage: int) -> void:
	digest_damage_value_label.text = "%d" % total_damage


func set_digest_efficiency_value(amount_minutes: float) -> void:
	digest_efficiency_value_label.text = _format_digest_efficiency(amount_minutes)


func _format_digest_efficiency(amount_minutes: float) -> String:
	var total_seconds := maxi(1, roundi(amount_minutes * 60.0))
	if total_seconds < 60:
		return "%dsec" % total_seconds
	var total_minutes := int(total_seconds / 60)
	var hours := int(total_minutes / 60)
	var minutes_only := total_minutes % 60
	if hours <= 0:
		return "%dmin" % total_minutes
	if minutes_only == 0:
		return "%dh" % hours
	return "%dh%dm" % [hours, minutes_only]


func _on_digestion_requested() -> void:
	digestion_requested.emit()


func _on_debug_message_requested(is_active: bool) -> void:
	debug_message_requested.emit(is_active)


func _on_debug_reroll_requested() -> void:
	debug_reroll_requested.emit()


func _on_debug_stomach_size_requested(delta_columns: int, delta_rows: int) -> void:
	debug_stomach_size_requested.emit(delta_columns, delta_rows)


func _on_debug_seed_requested() -> void:
	debug_seed_requested.emit()


func _on_seed_skill_drag_started(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	seed_skill_drag_started.emit(button, seed_skill, mouse_position)


func _on_seed_skill_drag_moved(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	seed_skill_drag_moved.emit(button, seed_skill, mouse_position)


func _on_seed_skill_drag_released(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	seed_skill_drag_released.emit(button, seed_skill, mouse_position)
