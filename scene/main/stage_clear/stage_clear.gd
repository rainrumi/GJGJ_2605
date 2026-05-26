extends Node2D
signal selection_finished(recovered_hp_rate: float)
const ABANDON_HP_RECOVERY_RATE := 0.1
const CLEAR_RECOVERY_START_HOUR := 22
const CLEAR_RECOVERY_END_HOUR := 27
const CLEAR_RECOVERY_BASE_RATE := 0.5
const CLEAR_RECOVERY_HOURLY_LOSS_RATE := 0.1
const MAX_HP := 100
const HEAD_FLOWER_DISPLAY_COUNT := 0
const DEBUG_BUTTON_NORMAL_FONT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_FONT_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const DEBUG_BUTTON_ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_HOVER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const DEBUG_BUTTON_ACTIVE_PRESSED_COLOR := Color(0.76, 0.76, 0.76, 1.0)
const DREAM_SEED_SKILL_CATALOG: DreamSeedSkillCatalog = preload("res://data/resources/seeds/dream_seed_skill_catalog.tres")
@export var max_flowers := 50
@export var initial_flower: FlowerDefinition
@export var seed_options: Array[Resource] = []
@onready var hp_view: HpView = $CharacterArea/HpFrame
@onready var dream_seed_skill_buttons: DreamSeedSkillButtonList = $CharacterArea/DreamSeedSkillButtons
@onready var guide_text: Label = $UI/GuideText
@onready var reroll_button: Button = $UI/RerollButton
@onready var debug_button: Button = $UI/DebugButton
@onready var seed_choices: Array[StageClearSeedChoice] = [
	$UI/SeedChoices/SeedChoice1 as StageClearSeedChoice,
	$UI/SeedChoices/SeedChoice2 as StageClearSeedChoice,
	$UI/SeedChoices/SeedChoice3 as StageClearSeedChoice,
]
@onready var abandon_button: StageClearAbandonButton = $UI/AbandonButton
@onready var flower_slots: Array[Button] = [
	$CharacterArea/FlowerSlots/FlowerSlot1 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot2 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot3 as Button,
]
var planted_flowers: Array[FlowerDefinition] = []
var current_hp := MAX_HP
var clear_minutes := CLEAR_RECOVERY_START_HOUR * 60
var _clear_recovery_applied := false
var _remaining_extra_seed_choices := 0
var _extra_seed_choice_granted := false
var _seed_choice_active := false
var _base_seed_options: Array[Resource] = []
var debug_numbers_visible := false
var reward_service := StageClearRewardService.new()
func _ready() -> void:
	_cache_base_seed_options()
	_initialize_planted_flowers()
	_setup_seed_choices()
	_setup_flower_slots()
	_setup_debug_button()
	_set_hp(current_hp, false)
	_show_select_mode()
func setup_hp(value: int) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	_clear_recovery_applied = false
	_reset_extra_seed_choices()
	_restore_base_seed_options()
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()
func setup_clear_result(value: int, cleared_minutes: int, cleared_stage: StageDefinition = null) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	clear_minutes = cleared_minutes
	_clear_recovery_applied = false
	_reset_extra_seed_choices()
	_restore_base_seed_options()
	_apply_stage_drop_options(cleared_stage)
	_update_extra_seed_choices()
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()
func reset_player_state() -> void:
	current_hp = MAX_HP
	clear_minutes = CLEAR_RECOVERY_START_HOUR * 60
	_clear_recovery_applied = false
	_reset_extra_seed_choices()
	_restore_base_seed_options()
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


func remove_planted_flower(source: Resource) -> void:
	if source == null:
		return
	for i in range(planted_flowers.size() - 1, -1, -1):
		var flower := planted_flowers[i]
		if flower == source:
			planted_flowers.remove_at(i)
			continue
		if source is DreamSeedSkillDefinition and flower != null and flower.dream_seed_skill == source:
			planted_flowers.remove_at(i)
	if is_node_ready():
		_refresh_flower_slots()
		_refresh_seed_choices()
		_update_hp_heal_plan()


func _initialize_planted_flowers() -> void:
	planted_flowers.clear()
	if initial_flower != null:
		planted_flowers.append(initial_flower)
	_refresh_flower_slots()
func _cache_base_seed_options() -> void:
	_base_seed_options = seed_options.duplicate()


func _restore_base_seed_options() -> void:
	if _base_seed_options.is_empty():
		return
	seed_options = reward_service.get_stage_seed_options(_base_seed_options, null)


func _apply_stage_drop_options(stage: StageDefinition) -> void:
	seed_options = reward_service.get_stage_seed_options(_base_seed_options, stage)


func _get_seed_option(seed_index: int) -> SeedOptionDefinition:
	if seed_index < 0 or seed_index >= seed_options.size():
		return null
	return seed_options[seed_index] as SeedOptionDefinition
func _get_seed_display_name(seed: SeedOptionDefinition) -> String:
	if seed.dream_seed_skill != null:
		return seed.dream_seed_skill.display_name
	return seed.display_name
func _setup_seed_choices() -> void:
	for i in range(seed_choices.size()):
		var seed_choice := seed_choices[i]
		seed_choice.pressed.connect(_on_seed_choice_pressed.bind(i))
		seed_choice.mouse_entered.connect(_on_seed_choice_mouse_entered.bind(i))
		seed_choice.mouse_exited.connect(_on_seed_choice_mouse_exited)
	_refresh_seed_choices()


func _refresh_seed_choices() -> void:
	for i in range(seed_choices.size()):
		var seed_choice := seed_choices[i]
		var seed := _get_seed_option(i)
		if seed == null:
			seed_choice.set_choice_disabled(true)
			continue
		seed_choice.setup_choice(seed)
		seed_choice.set_debug_numbers_visible(debug_numbers_visible)
		seed_choice.set_choice_disabled(not _seed_choice_active)
func _setup_flower_slots() -> void:
	for slot in flower_slots:
		slot.disabled = true


func _setup_debug_button() -> void:
	reroll_button.pressed.connect(_on_reroll_button_pressed)
	debug_button.pressed.connect(_on_debug_button_pressed)
	_apply_debug_button_state()
	_update_debug_numbers_visible()
	_update_reroll_button_state()


func _on_debug_button_pressed() -> void:
	debug_numbers_visible = not debug_numbers_visible
	_apply_debug_button_state()
	_update_debug_numbers_visible()
	_update_reroll_button_state()


func _on_reroll_button_pressed() -> void:
	if not debug_numbers_visible or not _seed_choice_active:
		return
	_reroll_seed_options()
	_refresh_seed_choices()
	_update_hp_heal_plan()


func _update_debug_numbers_visible() -> void:
	dream_seed_skill_buttons.set_debug_numbers_visible(debug_numbers_visible)
	for seed_choice in seed_choices:
		seed_choice.set_debug_numbers_visible(debug_numbers_visible)


func _apply_debug_button_state() -> void:
	if debug_numbers_visible:
		debug_button.add_theme_color_override("font_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_button.add_theme_stylebox_override("normal", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
		debug_button.add_theme_stylebox_override("hover", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_HOVER_COLOR))
		debug_button.add_theme_stylebox_override("pressed", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_PRESSED_COLOR))
		debug_button.add_theme_stylebox_override("focus", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
		return
	debug_button.add_theme_color_override("font_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_button.remove_theme_stylebox_override("normal")
	debug_button.remove_theme_stylebox_override("hover")
	debug_button.remove_theme_stylebox_override("pressed")
	debug_button.remove_theme_stylebox_override("focus")


func _update_reroll_button_state() -> void:
	reroll_button.visible = debug_numbers_visible
	reroll_button.disabled = not debug_numbers_visible or not _seed_choice_active


func _reroll_seed_options() -> void:
	var skills := _get_reroll_seed_skill_candidates()
	if skills.is_empty():
		return
	skills.shuffle()
	var rerolled_options: Array[Resource] = []
	for i in range(seed_choices.size()):
		var seed := _get_seed_option(i)
		if seed == null:
			continue
		var rerolled_seed := seed.duplicate() as SeedOptionDefinition
		rerolled_seed.dream_seed_skill = skills[i % skills.size()]
		rerolled_options.append(rerolled_seed)
	seed_options = rerolled_options


func _get_reroll_seed_skill_candidates() -> Array[DreamSeedSkillDefinition]:
	var candidates: Array[DreamSeedSkillDefinition] = []
	for skill in DREAM_SEED_SKILL_CATALOG.normal_skills:
		if skill != null:
			candidates.append(skill)
	for skill in DREAM_SEED_SKILL_CATALOG.rare_skills:
		if skill != null:
			candidates.append(skill)
	return candidates


func _create_debug_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		style.set_corner_radius(corner, 2)
	return style
func _show_select_mode() -> void:
	guide_text.text = "夢の種をひとつ選んでください"
	_seed_choice_active = true
	abandon_button.disabled = false
	abandon_button.reset_visual_state()
	abandon_button.set_recovery_rate(_get_abandon_extra_recovery_rate())
	_update_hp_heal_plan()
	_refresh_seed_choices()
	_update_reroll_button_state()
	for slot in flower_slots:
		slot.disabled = true
func _on_seed_choice_pressed(seed_index: int) -> void:
	var seed := _get_seed_option(seed_index)
	if seed == null:
		return
	hp_view.set_planned_recovery_rate(_get_seed_choice_recovery_rate(seed_index))
	var flower := reward_service.create_seed_flower(seed)
	if _can_plant_seed(seed):
		planted_flowers.append(flower)
		_refresh_flower_slots()
		var recovered_rate := _apply_selection_recovery(0.0)
		_finish_seed_choice(recovered_rate, "%sを植えました" % _get_seed_display_name(seed))
		return
	reward_service.replace_first_flower(planted_flowers, flower)
	_refresh_flower_slots()
	var replacement_recovered_rate := _apply_selection_recovery(0.0)
	_finish_seed_choice(replacement_recovered_rate, "%sを植え替えました" % _get_seed_display_name(seed))
func _on_abandon_button_pressed() -> void:
	hp_view.set_planned_recovery_rate(_get_abandon_recovery_rate())
	var recovery_rate := _apply_selection_recovery(_get_abandon_extra_recovery_rate())
	selection_finished.emit(recovery_rate)
	if recovery_rate > 0.0:
		_show_finished_mode("種を放棄してHPを回復しました")
	else:
		_show_finished_mode("種を放棄しました")
func _show_finished_mode(message: String) -> void:
	guide_text.text = message
	_seed_choice_active = false
	abandon_button.disabled = true
	abandon_button.reset_visual_state()
	for seed_choice in seed_choices:
		seed_choice.set_choice_disabled(true)
	for slot in flower_slots:
		slot.disabled = true
	_update_reroll_button_state()
	_update_hp_heal_plan()
func _can_plant_seed(seed: SeedOptionDefinition) -> bool:
	return reward_service.can_plant_seed(seed, planted_flowers, max_flowers)


func _finish_seed_choice(recovered_rate: float, message: String) -> void:
	if _remaining_extra_seed_choices > 0:
		_remaining_extra_seed_choices -= 1
		_show_select_mode()
		return
	selection_finished.emit(recovered_rate)
	_show_finished_mode(message)
func _get_planned_clear_recovery_rate() -> float:
	return StageClearRecoveryCalculator.get_planned_recovery_rate(planted_flowers, clear_minutes, _clear_recovery_applied, CLEAR_RECOVERY_START_HOUR, CLEAR_RECOVERY_END_HOUR, CLEAR_RECOVERY_BASE_RATE, CLEAR_RECOVERY_HOURLY_LOSS_RATE)
func _get_seed_choice_recovery_rate(seed_index: int) -> float:
	if _clear_recovery_applied:
		return 0.0
	var seed := _get_seed_option(seed_index)
	if seed == null:
		return _get_planned_clear_recovery_rate()
	return StageClearRecoveryCalculator.get_planned_recovery_rate(_get_preview_flowers_for_seed(seed), clear_minutes, false, CLEAR_RECOVERY_START_HOUR, CLEAR_RECOVERY_END_HOUR, CLEAR_RECOVERY_BASE_RATE, CLEAR_RECOVERY_HOURLY_LOSS_RATE)
func _get_abandon_recovery_rate() -> float:
	if _clear_recovery_applied:
		return 0.0
	return _get_planned_clear_recovery_rate() + _get_abandon_extra_recovery_rate()


func _get_abandon_extra_recovery_rate() -> float:
	if _clear_recovery_applied:
		return 0.0
	if StageClearRecoveryCalculator.is_clear_time_recovery_disabled(planted_flowers):
		return 0.0
	return ABANDON_HP_RECOVERY_RATE
func _get_preview_flowers_for_seed(seed: SeedOptionDefinition) -> Array[FlowerDefinition]:
	return reward_service.get_preview_flowers_for_seed(seed, planted_flowers, max_flowers)


func _reset_extra_seed_choices() -> void:
	_remaining_extra_seed_choices = 0
	_extra_seed_choice_granted = false


func _update_extra_seed_choices() -> void:
	if _extra_seed_choice_granted:
		return
	if StageClearRecoveryCalculator.grants_extra_seed_choice(planted_flowers, clear_minutes):
		_remaining_extra_seed_choices += 1
		_extra_seed_choice_granted = true
func _apply_selection_recovery(extra_recovery_rate: float) -> float:
	if _clear_recovery_applied:
		return 0.0
	var recovery_rate := _get_planned_clear_recovery_rate() + extra_recovery_rate
	var recovered_hp := mini(MAX_HP, current_hp + ceili(float(MAX_HP) * recovery_rate))
	_clear_recovery_applied = true
	_set_hp(recovered_hp, true)
	return recovery_rate
func _refresh_flower_slots() -> void:
	var display_textures := _get_display_flower_textures()
	for i in range(flower_slots.size()):
		var texture_rect := flower_slots[i].get_node("FlowerTexture") as TextureRect
		if i >= HEAD_FLOWER_DISPLAY_COUNT or i >= display_textures.size():
			texture_rect.texture = null
			flower_slots[i].disabled = true
			continue
		texture_rect.texture = display_textures[i]
		flower_slots[i].disabled = true
	_refresh_dream_seed_skill_buttons()


func _refresh_dream_seed_skill_buttons() -> void:
	if dream_seed_skill_buttons == null:
		return
	dream_seed_skill_buttons.set_seed_sources(get_planted_flowers())
func _get_display_flower_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for flower in planted_flowers:
		var texture := _get_display_flower_texture(flower)
		if texture != null:
			textures.append(texture)
	return textures
func _get_display_flower_texture(flower: FlowerDefinition) -> Texture2D:
	if flower == null or flower.dream_seed_skill == null:
		return null
	return flower.dream_seed_skill.texture
func _set_hp(value: int, animated: bool) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	hp_view.set_hp(current_hp, MAX_HP, animated)
	_update_hp_heal_plan()
func _update_hp_heal_plan() -> void:
	hp_view.set_planned_recovery_rate(_get_planned_clear_recovery_rate())
func _on_seed_choice_mouse_entered(seed_index: int) -> void:
	var seed_choice := seed_choices[seed_index]
	if seed_choice.disabled:
		return
	hp_view.set_planned_recovery_rate(_get_seed_choice_recovery_rate(seed_index))
func _on_seed_choice_mouse_exited() -> void:
	_update_hp_heal_plan()
func _on_abandon_button_mouse_entered() -> void:
	if not abandon_button.disabled:
		hp_view.set_planned_recovery_rate(_get_abandon_recovery_rate())
func _on_abandon_button_mouse_exited() -> void:
	_update_hp_heal_plan()
