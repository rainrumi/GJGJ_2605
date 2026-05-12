extends Node2D
signal selection_finished(recovered_hp_rate: float)
const ABANDON_HP_RECOVERY_RATE := 0.1
const CLEAR_RECOVERY_START_HOUR := 22
const CLEAR_RECOVERY_END_HOUR := 27
const CLEAR_RECOVERY_BASE_RATE := 0.5
const CLEAR_RECOVERY_HOURLY_LOSS_RATE := 0.1
const MAX_HP := 100
const HP_GAUGE_TWEEN_DURATION := 0.35
const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const HOVER_TWEEN_DURATION := 0.1
const RARITY_NORMAL: StringName = &"normal"
const RARITY_HIGH: StringName = &"high"
const HEAD_FLOWER_DISPLAY_COUNT := 1
const ABANDON_BUTTON_PRESSED_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const ABANDON_BUTTON_DEFAULT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
@export var max_normal_flowers := 3
@export var max_high_flowers := 2
@export var initial_flower: FlowerDefinition
@export var seed_options: Array[Resource] = []
@onready var hp_gauge: NinePatchRect = $CharacterArea/HpFrame/HpGauge
@onready var hp_heal_plan: NinePatchRect = $CharacterArea/HpFrame/HpHealPlan
@onready var hp_text: Label = $CharacterArea/HpFrame/HpText
@onready var planted_info_text: Label = $CharacterArea/PlantedInfoFrame/PlantedInfoText
@onready var guide_text: Label = $UI/GuideText
@onready var seed_choices: Array[StageClearSeedChoice] = [
	$UI/SeedChoices/SeedChoice1 as StageClearSeedChoice,
	$UI/SeedChoices/SeedChoice2 as StageClearSeedChoice,
	$UI/SeedChoices/SeedChoice3 as StageClearSeedChoice,
]
@onready var abandon_button: Button = $UI/AbandonButton
@onready var abandon_button_frame: TextureRect = $UI/AbandonButton/Frame
@onready var flower_slots: Array[Button] = [
	$CharacterArea/FlowerSlots/FlowerSlot1 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot2 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot3 as Button,
]
var planted_flowers: Array[FlowerDefinition] = []
var current_hp := MAX_HP
var clear_minutes := CLEAR_RECOVERY_START_HOUR * 60
var _clear_recovery_applied := false
var _hp_gauge_full_width := 0.0
var _hp_gauge_tween: Tween
var _abandon_button_base_scale := Vector2.ONE
var _abandon_button_hover_tween: Tween
var _abandon_button_hovered := false
var _abandon_button_pressed := false
func _ready() -> void:
	_capture_hp_gauge_size()
	_capture_button_scales()
	_initialize_planted_flowers()
	_setup_seed_choices()
	_setup_flower_slots()
	abandon_button.button_down.connect(_on_abandon_button_down)
	abandon_button.button_up.connect(_on_abandon_button_up)
	abandon_button.pressed.connect(_on_abandon_button_pressed)
	abandon_button.mouse_entered.connect(_on_abandon_button_mouse_entered)
	abandon_button.mouse_exited.connect(_on_abandon_button_mouse_exited)
	_set_hp(current_hp, false)
	_show_select_mode()
func setup_hp(value: int) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	_clear_recovery_applied = false
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()
func setup_clear_result(value: int, cleared_minutes: int) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	clear_minutes = cleared_minutes
	_clear_recovery_applied = false
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()
func reset_player_state() -> void:
	current_hp = MAX_HP
	clear_minutes = CLEAR_RECOVERY_START_HOUR * 60
	_clear_recovery_applied = false
	_initialize_planted_flowers()
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()
func get_current_hp() -> int:
	return current_hp
func get_planted_flowers() -> Array[FlowerDefinition]:
	var flowers: Array[FlowerDefinition] = []
	for flower in planted_flowers:
		if flower != null:
			flowers.append(flower)
	return flowers
func _initialize_planted_flowers() -> void:
	planted_flowers.clear()
	if initial_flower != null:
		planted_flowers.append(initial_flower)
	_refresh_flower_slots()
func _get_seed_option(seed_index: int) -> SeedOptionDefinition:
	if seed_index < 0 or seed_index >= seed_options.size():
		return null
	return seed_options[seed_index] as SeedOptionDefinition
func _setup_seed_choices() -> void:
	for i in range(seed_choices.size()):
		var seed_choice := seed_choices[i]
		var seed := _get_seed_option(i)
		if seed == null:
			seed_choice.set_choice_disabled(true)
			continue
		seed_choice.setup_choice(
			seed.display_name,
			seed.effect_text,
			seed.seed_texture,
			seed.frame_texture,
			seed.effect_font_size
		)
		seed_choice.pressed.connect(_on_seed_choice_pressed.bind(i))
func _setup_flower_slots() -> void:
	for slot in flower_slots:
		slot.disabled = true
func _show_select_mode() -> void:
	guide_text.text = "夢の種をひとつ選んでください"
	abandon_button.disabled = false
	_reset_abandon_button_visual()
	_reset_abandon_button_scale()
	abandon_button.text = "放棄する　HP +%d%%回復" % roundi(ABANDON_HP_RECOVERY_RATE * 100.0)
	_update_hp_heal_plan()
	for i in range(seed_choices.size()):
		seed_choices[i].set_choice_disabled(_get_seed_option(i) == null)
	for slot in flower_slots:
		slot.disabled = true
func _on_seed_choice_pressed(seed_index: int) -> void:
	var seed := _get_seed_option(seed_index)
	if seed == null:
		return
	var flower := _create_seed_flower(seed)
	if _can_plant_seed(seed):
		planted_flowers.append(flower)
		_refresh_flower_slots()
		var recovered_rate := _apply_selection_recovery(0.0)
		selection_finished.emit(recovered_rate)
		_show_finished_mode("%sを植えました" % seed.display_name)
		return
	_replace_flower(seed, flower)
	_refresh_flower_slots()
	var replacement_recovered_rate := _apply_selection_recovery(0.0)
	selection_finished.emit(replacement_recovered_rate)
	_show_finished_mode("%sを植え替えました" % seed.display_name)
func _on_abandon_button_pressed() -> void:
	var recovery_rate := _apply_selection_recovery(ABANDON_HP_RECOVERY_RATE)
	selection_finished.emit(recovery_rate)
	_reset_abandon_button_scale()
	_show_finished_mode("種を放棄してHPを回復しました")
func _show_finished_mode(message: String) -> void:
	guide_text.text = message
	abandon_button.disabled = true
	_reset_abandon_button_visual()
	_reset_abandon_button_scale()
	for seed_choice in seed_choices:
		seed_choice.set_choice_disabled(true)
	for slot in flower_slots:
		slot.disabled = true
	_update_hp_heal_plan()
func _can_plant_seed(seed: SeedOptionDefinition) -> bool:
	return StageClearRecoveryCalculator.can_plant_seed(seed, planted_flowers, max_normal_flowers, max_high_flowers)
func _create_seed_flower(seed: SeedOptionDefinition) -> FlowerDefinition:
	if seed.flower_definition == null:
		return null
	var flower := seed.flower_definition.duplicate() as FlowerDefinition
	flower.dream_seed_skill = seed.dream_seed_skill
	return flower
func _replace_flower(seed: SeedOptionDefinition, flower: FlowerDefinition) -> void:
	if flower == null:
		return
	for i in range(planted_flowers.size()):
		if planted_flowers[i] == null or planted_flowers[i].rarity != seed.rarity:
			continue
		planted_flowers[i] = flower
		return
func _get_planned_clear_recovery_rate() -> float:
	return StageClearRecoveryCalculator.get_planned_recovery_rate(planted_flowers, clear_minutes, _clear_recovery_applied, CLEAR_RECOVERY_START_HOUR, CLEAR_RECOVERY_END_HOUR, CLEAR_RECOVERY_BASE_RATE, CLEAR_RECOVERY_HOURLY_LOSS_RATE)
func _apply_selection_recovery(extra_recovery_rate: float) -> float:
	if _clear_recovery_applied:
		return 0.0
	var recovery_rate := _get_planned_clear_recovery_rate() + extra_recovery_rate
	var recovered_hp := mini(MAX_HP, current_hp + ceili(float(MAX_HP) * recovery_rate))
	_clear_recovery_applied = true
	_set_hp(recovered_hp, true)
	return recovery_rate
func _refresh_flower_slots() -> void:
	for i in range(flower_slots.size()):
		var texture_rect := flower_slots[i].get_node("FlowerTexture") as TextureRect
		if i >= HEAD_FLOWER_DISPLAY_COUNT or i >= planted_flowers.size() or planted_flowers[i] == null:
			texture_rect.texture = null
			flower_slots[i].disabled = true
			continue
		texture_rect.texture = planted_flowers[i].texture
		flower_slots[i].disabled = true
	_update_planted_info_text()
func _update_planted_info_text() -> void:
	var normal_count := StageClearRecoveryCalculator.count_planted_by_rarity(planted_flowers, RARITY_NORMAL)
	var high_count := StageClearRecoveryCalculator.count_planted_by_rarity(planted_flowers, RARITY_HIGH)
	var normal_remaining := maxi(0, max_normal_flowers - normal_count)
	var high_remaining := maxi(0, max_high_flowers - high_count)
	planted_info_text.text = "植えられる数\n通常　あと %d本\n高級　あと %d本" % [normal_remaining, high_remaining]
func _on_abandon_button_down() -> void:
	_abandon_button_pressed = true
	abandon_button_frame.modulate = ABANDON_BUTTON_PRESSED_MODULATE
	_update_abandon_button_scale()
func _on_abandon_button_up() -> void:
	_abandon_button_pressed = false
	_abandon_button_hovered = false
	_reset_abandon_button_visual()
	_update_abandon_button_scale()
func _reset_abandon_button_visual() -> void:
	abandon_button_frame.modulate = ABANDON_BUTTON_DEFAULT_MODULATE
func _capture_button_scales() -> void:
	abandon_button_frame.pivot_offset = abandon_button_frame.size * 0.5
	_abandon_button_base_scale = abandon_button_frame.scale
func _capture_hp_gauge_size() -> void:
	_hp_gauge_full_width = hp_gauge.size.x
func _set_hp(value: int, animated: bool) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	hp_text.text = "%d/%d" % [current_hp, MAX_HP]
	var hp_ratio := clampf(float(current_hp) / float(MAX_HP), 0.0, 1.0)
	var target_size := Vector2(_hp_gauge_full_width * hp_ratio, hp_gauge.size.y)
	if _hp_gauge_tween != null and _hp_gauge_tween.is_valid():
		_hp_gauge_tween.kill()
	if current_hp > 0:
		hp_gauge.visible = true
	if not animated:
		hp_gauge.size = target_size
		if current_hp == 0:
			hp_gauge.visible = false
		_update_hp_heal_plan()
		return
	_hp_gauge_tween = create_tween()
	_hp_gauge_tween.set_trans(Tween.TRANS_QUAD)
	_hp_gauge_tween.set_ease(Tween.EASE_OUT)
	_hp_gauge_tween.tween_property(hp_gauge, "size", target_size, HP_GAUGE_TWEEN_DURATION)
	_hp_gauge_tween.tween_callback(Callable(self, "_update_hp_heal_plan"))
	if current_hp == 0:
		_hp_gauge_tween.tween_callback(func() -> void: hp_gauge.visible = false)
func _update_hp_heal_plan() -> void:
	if hp_heal_plan == null:
		return
	var recovery_rate := _get_planned_clear_recovery_rate()
	var current_ratio := clampf(float(current_hp) / float(MAX_HP), 0.0, 1.0)
	var target_hp := mini(MAX_HP, current_hp + ceili(float(MAX_HP) * recovery_rate))
	var target_ratio := clampf(float(target_hp) / float(MAX_HP), 0.0, 1.0)
	var current_width := _hp_gauge_full_width * current_ratio
	var target_width := _hp_gauge_full_width * target_ratio
	var plan_width := maxf(0.0, target_width - current_width)
	hp_heal_plan.visible = plan_width > 0.0
	hp_heal_plan.position = hp_gauge.position + Vector2(current_width, 0.0)
	hp_heal_plan.size = Vector2(plan_width, hp_gauge.size.y)
	hp_heal_plan.z_index = hp_gauge.z_index + 1
	hp_text.z_index = hp_heal_plan.z_index + 1
func _on_abandon_button_mouse_entered() -> void:
	_abandon_button_hovered = true
	_update_abandon_button_scale()
func _on_abandon_button_mouse_exited() -> void:
	_abandon_button_hovered = false
	_abandon_button_pressed = false
	_update_abandon_button_scale()
func _update_abandon_button_scale() -> void:
	if _abandon_button_hover_tween != null and _abandon_button_hover_tween.is_valid():
		_abandon_button_hover_tween.kill()
	var target_scale := _abandon_button_base_scale
	if _abandon_button_hovered:
		target_scale *= HOVER_SCALE
	if _abandon_button_pressed:
		target_scale = _abandon_button_base_scale * PRESSED_SCALE
	_abandon_button_hover_tween = create_tween()
	_abandon_button_hover_tween.set_trans(Tween.TRANS_QUAD)
	_abandon_button_hover_tween.set_ease(Tween.EASE_OUT)
	_abandon_button_hover_tween.tween_property(
		abandon_button_frame,
		"scale",
		target_scale,
		HOVER_TWEEN_DURATION
	)
func _reset_abandon_button_scale() -> void:
	_abandon_button_hovered = false
	_abandon_button_pressed = false
	if _abandon_button_hover_tween != null and _abandon_button_hover_tween.is_valid():
		_abandon_button_hover_tween.kill()
	abandon_button_frame.scale = _abandon_button_base_scale

