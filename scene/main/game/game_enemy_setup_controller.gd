class_name GameEnemySetupController
extends RefCounted

const ENEMY_TOP_Y := 280.0
const ENEMY_MIDDLE_Y := 390.0
const ENEMY_BOTTOM_Y := 505.0
const ENEMY_LEFT_X := 850.0
const ENEMY_CENTER_X := 1000.0
const ENEMY_RIGHT_X := 1150.0
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")

var _owner: Node
var _input_controller: GameInputController
var _stomach: StomachBoard
var _enemy_definitions: Array[Resource] = []
var _nightmare_skill_catalog: NightmareSkillCatalog


func setup(
	owner: Node,
	input_controller: GameInputController,
	stomach: StomachBoard,
	enemy_definitions: Array[Resource],
	nightmare_skill_catalog: NightmareSkillCatalog
) -> void:
	_owner = owner
	_input_controller = input_controller
	_stomach = stomach
	_enemy_definitions = enemy_definitions
	_nightmare_skill_catalog = nightmare_skill_catalog


func setup_enemies(enemies: Array[Enemy]) -> void:
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
	damage_value: int
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


func _get_random_nightmare_skills() -> Array[NightmareSkillDefinition]:
	if _nightmare_skill_catalog == null or _nightmare_skill_catalog.skills.is_empty():
		return []
	var skills_by_category: Dictionary = {}
	for skill in _nightmare_skill_catalog.skills:
		if skill == null:
			continue
		var category := skill.category
		if category.is_empty():
			category = "通常"
		if not skills_by_category.has(category):
			skills_by_category[category] = []
		skills_by_category[category].append(skill)
	return _pick_skills_from_category(skills_by_category)


func _pick_skills_from_category(skills_by_category: Dictionary) -> Array[NightmareSkillDefinition]:
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
	if _enemy_definitions.is_empty():
		return null
	return _enemy_definitions[enemy_index % _enemy_definitions.size()] as EnemyDefinition


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
