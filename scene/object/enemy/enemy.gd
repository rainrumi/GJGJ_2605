class_name Enemy
extends Node2D
const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1
const COST_PULSE_SCALE := 1.1
const COST_PULSE_DURATION := 0.2
const DAMAGE_PULSE_SCALE := 1.12
const DAMAGE_PULSE_DURATION := 0.18
const DIGESTED_SCALE := 1.2
const DIGESTED_TWEEN_DURATION := 0.5
const DEFAULT_STATUS_COLOR := Color(0.0352941, 0.027451, 0.211765, 1.0)
const MAIN_EFFECT_STATUS_COLOR := Color(0.78, 0.18, 0.08, 1.0)
const ONE_CELL_STOMACH_TEXTURE := preload("res://art/enemy/tex_stomach_block_1000.png")
@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label = $HPText
@onready var damage_label: Label = $DamageText
var definition: EnemyDefinition
var skill_definition: NightmareSkillDefinition
var seed_skill_definition: DreamSeedSkillDefinition
var has_main_effect := false
var nightmare_skill_enabled := true
var max_hp := 0
var damage := 0
var base_damage := 0
var display_damage_override := -1
var attack_multiplier := 1.0
var digest_damage_taken_multiplier := 1.0
var digest_damage_global_multiplier := 1.0
var stomach_elapsed_minutes := 0
var revive_count := 0
var current_hp := 0
var digesting := false
var digested := false
var gravity_locked := false
var activation_deferred := false
var stomach_cell := Vector2i.ZERO
var origin_position := Vector2.ZERO
var _base_scale := Vector2.ONE
var _hover_tween: Tween
var _cost_pulse_tween: Tween
var _damage_pulse_tween: Tween
var _digested_tween: Tween
var _hovered := false
var _stomach_size_override := Vector2i.ZERO
var _stomach_shape_override: Array[Vector2i] = []
var _size_override := 0
var _texture_override: Texture2D
func setup(enemy_definition: EnemyDefinition, target_size: Vector2, nightmare_skill: NightmareSkillDefinition = null, has_effect := false, start_position_override := Vector2.INF) -> void:
	definition = enemy_definition
	skill_definition = nightmare_skill
	seed_skill_definition = null
	nightmare_skill_enabled = enemy_definition.nightmare_skill_enabled
	has_main_effect = has_effect and nightmare_skill_enabled
	max_hp = enemy_definition.max_hp
	damage = enemy_definition.damage
	base_damage = enemy_definition.damage
	display_damage_override = -1
	attack_multiplier = 1.0
	digest_damage_taken_multiplier = 1.0
	digest_damage_global_multiplier = 1.0
	stomach_elapsed_minutes = 0
	revive_count = 0
	gravity_locked = false
	activation_deferred = false
	_texture_override = null
	clear_stomach_footprint_override()
	origin_position = enemy_definition.start_position
	if start_position_override != Vector2.INF:
		origin_position = start_position_override
	position = origin_position
	if sprite != null:
		sprite.texture = _get_texture()
		if sprite.texture != null:
			sprite.scale = target_size / sprite.texture.get_size()
			_base_scale = sprite.scale
	reset_for_battle()
func reset_for_battle() -> void:
	current_hp = max_hp
	digesting = false
	digested = false
	gravity_locked = false
	activation_deferred = false
	stomach_cell = Vector2i.ZERO
	stomach_elapsed_minutes = 0
	revive_count = 0
	visible = true
	_reset_visuals()
	return_to_origin()
	set_hovered(false)
	_update_hp_label()
	_update_damage_label()
	_update_status_label_colors()
func get_display_name() -> String:
	if seed_skill_definition != null and not seed_skill_definition.display_name.is_empty():
		return seed_skill_definition.display_name
	if skill_definition != null and not skill_definition.display_name.is_empty():
		return skill_definition.display_name
	return definition.display_name


func is_seed_stomach_block() -> bool:
	return seed_skill_definition != null


func has_seed_skill() -> bool:
	return seed_skill_definition != null


func get_seed_skill() -> DreamSeedSkillDefinition:
	return seed_skill_definition


func has_nightmare_skill() -> bool:
	return skill_definition != null


func get_nightmare_skill() -> NightmareSkillDefinition:
	return skill_definition


func is_nightmare() -> bool:
	return not is_seed_stomach_block()


func is_stomach_piece() -> bool:
	return is_active_in_stomach()


func should_count_for_battle_clear() -> bool:
	return is_nightmare()


func should_apply_nightmare_skill() -> bool:
	return is_nightmare() and nightmare_skill_enabled


func should_deal_player_damage() -> bool:
	return is_nightmare()


func should_count_for_digest_order() -> bool:
	return is_nightmare()


func should_trigger_nightmare_reactions() -> bool:
	return is_nightmare()


func get_damage() -> int: return maxi(0, roundi(float(damage) * attack_multiplier))
func get_display_damage() -> int: return display_damage_override if display_damage_override >= 0 else get_damage()
func get_base_damage() -> int: return base_damage
func get_max_hp() -> int: return max_hp
func get_current_hp() -> int: return current_hp
func get_revive_count() -> int: return revive_count
func is_digested() -> bool: return digested
func is_digesting() -> bool: return digesting
func is_activation_deferred() -> bool: return activation_deferred


func get_size() -> int:
	if _size_override > 0:
		return _size_override
	return definition.size


func get_stomach_size() -> Vector2i:
	if _stomach_size_override != Vector2i.ZERO:
		return _stomach_size_override
	return definition.stomach_size


func get_stomach_shape() -> Array[Vector2i]:
	if not _stomach_shape_override.is_empty():
		return _stomach_shape_override.duplicate()
	var shape: Array[Vector2i] = []
	if definition == null:
		return shape
	for cell in definition.stomach_shape:
		if cell is Vector2i:
			shape.append(cell)
	return shape


func can_drag() -> bool:
	return not digested


func is_active_in_stomach() -> bool:
	return digesting and not digested


func can_take_stomach_turn() -> bool:
	return is_active_in_stomach() and not activation_deferred
func set_digesting(value: bool) -> void:
	if digesting != value:
		stomach_elapsed_minutes = 0
	digesting = value
func set_digested(value: bool) -> void:
	digested = value
	if digested:
		digesting = false
		_play_digested_tween()
func set_stomach_cell(cell: Vector2i) -> void:
	stomach_cell = cell
func set_stomach_footprint_override(size: Vector2i, shape: Array[Vector2i], cell_count: int) -> void:
	_stomach_size_override = size
	_stomach_shape_override = shape.duplicate()
	_size_override = cell_count
func set_texture_override(texture: Texture2D, target_size: Vector2) -> void:
	_texture_override = texture
	if sprite == null or _texture_override == null:
		return
	sprite.texture = _texture_override
	if sprite.texture != null:
		sprite.scale = target_size / sprite.texture.get_size()
		_base_scale = sprite.scale
	_reset_visuals()
func setup_as_one_cell_stomach_block(target_size: Vector2) -> void:
	var block_shape: Array[Vector2i] = [Vector2i.ZERO]
	set_stomach_footprint_override(Vector2i.ONE, block_shape, 1)
	set_texture_override(ONE_CELL_STOMACH_TEXTURE, target_size)
	gravity_locked = true
	activation_deferred = true


func setup_as_seed_stomach_block(seed_skill: DreamSeedSkillDefinition, target_size: Vector2) -> void:
	var block_definition := seed_skill.drag_block_definition if seed_skill != null else null
	if block_definition != null:
		set_stomach_footprint_override(
			block_definition.get_stomach_size(),
			block_definition.get_stomach_shape(),
			block_definition.get_cell_count()
		)
		set_texture_override(ONE_CELL_STOMACH_TEXTURE, target_size)
		gravity_locked = true
		activation_deferred = false
	else:
		setup_as_one_cell_stomach_block(target_size)
		activation_deferred = false
	seed_skill_definition = seed_skill
	if block_definition != null and block_definition.texture != null:
		set_texture_override(block_definition.texture, target_size)
	max_hp = block_definition.get_max_hp() if block_definition != null else 1
	current_hp = max_hp
	damage = block_definition.get_damage() if block_definition != null else 0
	base_damage = damage
	display_damage_override = damage
	_update_hp_label()
	_update_damage_label()


func update_stomach_display_size(target_size: Vector2) -> void:
	if sprite == null or sprite.texture == null:
		return
	sprite.scale = target_size / sprite.texture.get_size()
	_base_scale = sprite.scale
func can_apply_gravity() -> bool:
	return not gravity_locked
func clear_gravity_lock() -> void:
	gravity_locked = false
func activate_stomach_turn() -> void:
	activation_deferred = false
func clear_stomach_footprint_override() -> void:
	_stomach_size_override = Vector2i.ZERO
	_stomach_shape_override.clear()
	_size_override = 0
func return_to_origin() -> void:
	position = origin_position
func set_hovered(value: bool) -> void:
	if _hovered == value or sprite == null:
		return
	_hovered = value
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(sprite, "scale", target_scale, HOVER_TWEEN_DURATION)
func pulse_cost_label() -> void:
	if hp_label == null:
		return
	if _cost_pulse_tween != null and _cost_pulse_tween.is_valid():
		_cost_pulse_tween.kill()
	hp_label.scale = Vector2.ONE
	_cost_pulse_tween = create_tween()
	_cost_pulse_tween.set_trans(Tween.TRANS_ELASTIC)
	_cost_pulse_tween.set_ease(Tween.EASE_OUT)
	_cost_pulse_tween.tween_property(hp_label, "scale", Vector2.ONE * COST_PULSE_SCALE, COST_PULSE_DURATION * 0.5)
	_cost_pulse_tween.tween_property(hp_label, "scale", Vector2.ONE, COST_PULSE_DURATION * 0.5)
func pulse_damage() -> void:
	if sprite == null:
		return
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()
	_damage_pulse_tween = create_tween()
	_damage_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_damage_pulse_tween.set_ease(Tween.EASE_OUT)
	_damage_pulse_tween.tween_property(sprite, "scale", _base_scale * DAMAGE_PULSE_SCALE, DAMAGE_PULSE_DURATION * 0.5)
	_damage_pulse_tween.tween_property(sprite, "scale", _base_scale, DAMAGE_PULSE_DURATION * 0.5)
func take_digest_damage(amount: int, show_popup := true) -> bool:
	if show_popup:
		EnemyDamagePopup.show_damage(self, hp_label, amount, MAIN_EFFECT_STATUS_COLOR)
	current_hp = maxi(0, current_hp - amount)
	_update_hp_label()
	if current_hp == 0:
		set_digested(true)
		return true
	return false
func show_digest_damage_values(damage_values: Array) -> void:
	EnemyDamagePopup.show_damage_values(self, hp_label, damage_values, MAIN_EFFECT_STATUS_COLOR)
func get_global_rect() -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2(global_position - Vector2(25.0, 25.0), Vector2(50.0, 50.0))
	var size := sprite.texture.get_size() * sprite.scale.abs()
	return Rect2(sprite.global_position - size * 0.5, size)
func get_grab_cell(mouse_position: Vector2) -> Vector2i:
	var enemy_rect := get_global_rect()
	var enemy_size := get_stomach_size()
	var relative_position := mouse_position - enemy_rect.position
	var guessed_cell := Vector2i(clampi(int(relative_position.x / enemy_rect.size.x * float(enemy_size.x)), 0, enemy_size.x - 1), clampi(int(relative_position.y / enemy_rect.size.y * float(enemy_size.y)), 0, enemy_size.y - 1))
	if get_stomach_shape().has(guessed_cell):
		return guessed_cell
	return _get_nearest_shape_cell(guessed_cell)
func get_occupied_cells(top_left: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in get_stomach_shape():
		cells.append(top_left + offset)
	return cells
func get_bottom_row(top_left: Vector2i) -> int:
	var bottom_row := 0
	for cell in get_occupied_cells(top_left):
		bottom_row = maxi(bottom_row, cell.y)
	return bottom_row
func _get_nearest_shape_cell(target_cell: Vector2i) -> Vector2i:
	var nearest_cell := Vector2i.ZERO
	var nearest_distance := INF
	for offset in get_stomach_shape():
		var diff := target_cell - offset
		var distance := float(diff.x * diff.x + diff.y * diff.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = offset
	return nearest_cell
func _play_digested_tween() -> void:
	if _digested_tween != null and _digested_tween.is_valid():
		_digested_tween.kill()
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hovered = false
	visible = true
	scale = Vector2.ONE
	modulate.a = 1.0
	_digested_tween = create_tween()
	_digested_tween.set_parallel(true)
	_digested_tween.set_trans(Tween.TRANS_QUART)
	_digested_tween.set_ease(Tween.EASE_OUT)
	_digested_tween.tween_property(self, "scale", Vector2.ONE * DIGESTED_SCALE, DIGESTED_TWEEN_DURATION)
	_digested_tween.tween_property(self, "modulate:a", 0.0, DIGESTED_TWEEN_DURATION)
	_digested_tween.chain().tween_callback(func() -> void: visible = false)
func _reset_visuals() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	if _cost_pulse_tween != null and _cost_pulse_tween.is_valid():
		_cost_pulse_tween.kill()
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()
	if _digested_tween != null and _digested_tween.is_valid():
		_digested_tween.kill()
	_hovered = false
	scale = Vector2.ONE
	modulate.a = 1.0
	if sprite != null:
		sprite.scale = _base_scale
	if hp_label != null:
		hp_label.scale = Vector2.ONE
	if damage_label != null:
		damage_label.scale = Vector2.ONE
func _update_hp_label() -> void:
	if hp_label != null:
		hp_label.text = str(current_hp)
func set_display_damage(value: int) -> void: display_damage_override = maxi(0, value); _update_damage_label()
func _update_damage_label() -> void:
	if damage_label != null: damage_label.text = "攻 %d" % get_display_damage()
func _get_texture() -> Texture2D:
	if _texture_override != null:
		return _texture_override
	return definition.texture
func get_category_name() -> String:
	return EnemyTooltipFormatter.get_category_name(has_main_effect, skill_definition)
func get_category_detail() -> String:
	return EnemyTooltipFormatter.get_category_detail(has_main_effect, skill_definition)
func get_main_effect_text() -> String:
	return EnemyTooltipFormatter.get_main_effect_text(has_main_effect, skill_definition)
func get_tag_text() -> String:
	return EnemyTooltipFormatter.get_tag_text(skill_definition)
func get_sub_effect_text() -> String:
	return "-"
func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount); _update_hp_label()
func heal_over_max(amount: int) -> void:
	current_hp = maxi(0, current_hp + amount); _update_hp_label()
func change_max_hp(new_max_hp: int) -> void:
	max_hp = maxi(1, new_max_hp); current_hp = mini(current_hp, max_hp); _update_hp_label()
func add_max_hp(amount: int, also_heal := true) -> void:
	max_hp = maxi(1, max_hp + amount)
	if also_heal:
		current_hp += amount
	current_hp = maxi(0, current_hp)
	_update_hp_label()
func set_hp_values(next_max_hp: int, next_current_hp: int) -> void:
	max_hp = maxi(1, next_max_hp); current_hp = clampi(next_current_hp, 0, max_hp); _update_hp_label()
func add_damage(amount: int) -> void:
	damage = maxi(0, damage + amount); _update_damage_label()
func set_damage_value(value: int) -> void:
	damage = maxi(0, value); base_damage = damage; _update_damage_label()
func set_attack_multiplier(value: float) -> void:
	attack_multiplier = clampf(value, 0.0, 3.0); _update_damage_label()
func set_digest_damage_taken_multiplier(value: float) -> void:
	digest_damage_taken_multiplier = maxf(0.0, value)
func set_digest_damage_global_multiplier(value: float) -> void:
	digest_damage_global_multiplier = maxf(0.0, value)
func revive_with_half_hp() -> void:
	revive_with_hp_rate(0.5)
func revive_with_hp_rate(hp_rate: float) -> void:
	if _digested_tween != null and _digested_tween.is_valid():
		_digested_tween.kill()
	revive_count += 1
	change_max_hp(ceili(float(max_hp) * hp_rate))
	current_hp = max_hp
	digested = false
	digesting = false
	visible = true
	return_to_origin()
	scale = Vector2.ONE
	modulate.a = 1.0
	_update_hp_label()
func _update_status_label_colors() -> void:
	var status_color := MAIN_EFFECT_STATUS_COLOR if has_main_effect else DEFAULT_STATUS_COLOR
	if hp_label != null:
		hp_label.add_theme_color_override("font_color", status_color)
	if damage_label != null:
		damage_label.add_theme_color_override("font_color", status_color)
