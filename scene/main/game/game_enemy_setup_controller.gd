class_name GameEnemySetupController
extends RefCounted

const ENEMY_TOP_Y := 140.0
const ENEMY_MIDDLE_Y := 195.0
const ENEMY_BOTTOM_Y := 252.5
const ENEMY_LEFT_X := 425.0
const ENEMY_CENTER_X := 500.0
const ENEMY_RIGHT_X := 575.0
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
const DEFAULT_NIGHTMARE_MAX_HP := 1400
const DEFAULT_NIGHTMARE_SIZE := 6
const DEFAULT_NIGHTMARE_DAMAGE := 2
const STRENGTHENED_NIGHTMARE_SKILL_ID_MIN := 20000
const DEFAULT_NIGHTMARE_STOMACH_SIZE := Vector2i(2, 3)
const DEFAULT_NIGHTMARE_STOMACH_SHAPE: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(0, 2),
	Vector2i(1, 2),
]

var _owner: Node
var _input_controller: GameInputController
var _stomach: StomachBoard
var _enemy_definitions: Array[Resource] = []
var _enemy_preset: NightmarePresetInfo


func setup(
	owner: Node,
	input_controller: GameInputController,
	stomach: StomachBoard,
	enemy_definitions: Array[Resource],
	enemy_preset: NightmarePresetInfo = null
) -> void:
	_owner = owner
	_input_controller = input_controller
	_stomach = stomach
	_enemy_definitions = enemy_definitions
	_enemy_preset = enemy_preset


func setup_enemies(enemies: Array[Enemy]) -> void:
	if _enemy_preset != null and not _enemy_preset.enemies.is_empty():
		_setup_preset_enemies(enemies)
		return
	_setup_legacy_random_enemies(enemies)


func _setup_preset_enemies(enemies: Array[Enemy]) -> void:
	var enemy_positions := _get_enemy_positions(_enemy_preset.enemies.size())
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if i >= _enemy_preset.enemies.size():
			enemy.visible = false
			enemy.digested = true
			enemy.digesting = false
			enemy.has_main_effect = false
			continue
		var source_skill := _enemy_preset.enemies[i]
		if source_skill == null:
			continue
		var skill := _create_stage_nightmare_skill(source_skill)
		var definition := _create_nightmare_definition(skill)
		enemy.setup(
			definition,
			Vector2(
				_stomach.get_span_size(definition.stomach_size.x),
				_stomach.get_span_size(definition.stomach_size.y)
			),
			skill,
			skill.nightmare_skill_enabled,
			enemy_positions[i]
		)


func _setup_legacy_random_enemies(enemies: Array[Enemy]) -> void:
	var selected_skills := _get_random_nightmare_skills()
	var enemy_positions := _get_enemy_positions(selected_skills.size())
	var main_effect_enemy_index := randi() % selected_skills.size() if not selected_skills.is_empty() else -1
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if i >= selected_skills.size():
			enemy.visible = false
			enemy.digested = true
			enemy.digesting = false
			enemy.has_main_effect = false
			continue
		var definition := _get_enemy_template(i)
		if definition == null:
			continue
		enemy.setup(
			definition,
			Vector2(
				_stomach.get_span_size(definition.stomach_size.x),
				_stomach.get_span_size(definition.stomach_size.y)
			),
			selected_skills[i],
			i == main_effect_enemy_index,
			enemy_positions[i]
		)


func spawn_nuisance_nightmare(
	enemies: Array[Enemy],
	source_enemy: Enemy,
	spawn_cell: Vector2i,
	hp_rate: float,
	damage_value: int,
	digest_damage_rate: float = 1.0,
	global_digest_damage_rate: float = 1.0
) -> bool:
	var nuisance_enemy := _get_available_nuisance_enemy(enemies, source_enemy)
	if nuisance_enemy == null:
		return false
	var source_definition := source_enemy.definition
	var source_origin_position := source_enemy.origin_position
	var source_max_hp := source_enemy.max_hp
	nuisance_enemy.setup(
		source_definition,
		Vector2.ONE * _stomach.get_span_size(1),
		null,
		false,
		source_origin_position
	)
	nuisance_enemy.setup_as_one_cell_stomach_block(Vector2.ONE * _stomach.get_span_size(1))
	nuisance_enemy.change_max_hp(maxi(1, roundi(float(source_max_hp) * hp_rate)))
	nuisance_enemy.current_hp = nuisance_enemy.max_hp
	nuisance_enemy.set_damage_value(maxi(0, damage_value))
	nuisance_enemy.set_digest_damage_taken_multiplier(digest_damage_rate)
	nuisance_enemy.set_digest_damage_global_multiplier(global_digest_damage_rate)
	nuisance_enemy.set_digesting(true)
	_stomach.place_enemy(nuisance_enemy, spawn_cell)
	return true


func _get_available_nuisance_enemy(enemies: Array[Enemy], source_enemy: Enemy) -> Enemy:
	for enemy in enemies:
		if enemy.visible or not enemy.digested:
			continue
		return enemy
	if source_enemy.digested:
		return source_enemy
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	_owner.add_child(enemy)
	enemies.append(enemy)
	_input_controller.setup(enemies)
	return enemy


func _get_random_nightmare_skills() -> Array[NightmareInfo]:
	var skills_by_category: Dictionary = {}
	return _pick_skills_from_category(skills_by_category)


func _pick_skills_from_category(skills_by_category: Dictionary) -> Array[NightmareInfo]:
	var categories := skills_by_category.keys()
	if categories.is_empty():
		return []
	var category = categories[randi() % categories.size()]
	var category_skills: Array = skills_by_category[category].duplicate()
	category_skills.shuffle()
	var max_count := mini(4, category_skills.size())
	var min_count := mini(2, max_count)
	var count := randi_range(min_count, max_count)
	var selected: Array[NightmareInfo] = []
	for i in range(count):
		selected.append(category_skills[i] as NightmareInfo)
	return selected


func _get_enemy_template(enemy_index: int) -> EnemyDefinition:
	if _enemy_definitions.is_empty():
		return null
	return _enemy_definitions[enemy_index % _enemy_definitions.size()] as EnemyDefinition


func _create_nightmare_definition(skill: NightmareInfo) -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	if skill == null:
		return definition
	
	definition.display_name = skill.display_name
	definition.nightmare_skill = skill
	definition.nightmare_skill_enabled = skill.nightmare_skill_enabled
	
	var block := skill.acid_block
	if block == null:
		definition.max_hp = DEFAULT_NIGHTMARE_MAX_HP
		definition.size = DEFAULT_NIGHTMARE_SIZE
		definition.damage = DEFAULT_NIGHTMARE_DAMAGE
		definition.stomach_size = DEFAULT_NIGHTMARE_STOMACH_SIZE
		definition.stomach_shape = DEFAULT_NIGHTMARE_STOMACH_SHAPE.duplicate()
		return definition

	definition.texture = block.texture
	definition.max_hp = block.get_max_hp()
	definition.size = block.get_cell_count()
	definition.damage = block.get_damage()
	definition.stomach_size = block.get_stomach_size()
	definition.stomach_shape = block.get_stomach_shape()

	return definition


func _create_stage_nightmare_skill(source_skill: NightmareInfo) -> NightmareInfo:
	var skill := source_skill.duplicate(true) as NightmareInfo
	skill.nightmare_skill_enabled = skill.skill_id >= STRENGTHENED_NIGHTMARE_SKILL_ID_MIN
	return skill


func _get_nightmare_stomach_size(skill: NightmareInfo) -> Vector2i:
	if skill.stomach_size.x > 0 and skill.stomach_size.y > 0:
		return skill.stomach_size
	return DEFAULT_NIGHTMARE_STOMACH_SIZE


func _get_nightmare_stomach_shape(skill: NightmareInfo) -> Array[Vector2i]:
	var shape: Array[Vector2i] = []
	for cell in skill.stomach_shape:
		if cell is Vector2i:
			shape.append(cell)
	if shape.is_empty():
		return DEFAULT_NIGHTMARE_STOMACH_SHAPE.duplicate()
	return shape


func _get_enemy_positions(enemy_count: int) -> Array[Vector2]:
	match enemy_count:
		2:
			return [
				Vector2(ENEMY_LEFT_X, ENEMY_MIDDLE_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_MIDDLE_Y),
			]
		4:
			return [
				Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_TOP_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_LEFT_X, ENEMY_TOP_Y),
			]
	return [
		Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
		Vector2(ENEMY_CENTER_X, ENEMY_TOP_Y),
		Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
	]
