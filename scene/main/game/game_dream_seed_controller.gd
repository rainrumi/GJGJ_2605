class_name GameDreamSeedController
extends RefCounted

const DREAM_SEED_SKILL_CATALOG: DreamSeedSkillCatalog = preload("res://data/resources/dream_seed_skills/dream_seed_skill_catalog.tres")
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
const SEED_BLOCK_DRAG_ALPHA := 0.58
const DREAM_SEED_ACTIVATION_HP_RECOVERY := 1002
const DREAM_SEED_ACTIVATION_HP_RECOVERY_RATE := 0.05
const DREAM_SEED_ACTIVATION_SKIP_REST_TIME := 1004

var rest_time_skip_count := 0
var _flowers: Array[FlowerDefinition] = []


func setup(flowers: Array) -> void:
	_flowers.clear()
	rest_time_skip_count = 0
	for flower in flowers:
		if flower is FlowerDefinition:
			_flowers.append(flower as FlowerDefinition)


func get_flowers() -> Array[FlowerDefinition]:
	return _flowers


func add_random_debug_seed() -> bool:
	var flower := _get_random_debug_seed_flower()
	if flower == null:
		return false
	_flowers.append(flower)
	return true


func remove_source_if_button_depleted(button: DreamSeedSkillButton) -> Resource:
	if button == null or button.get_remaining_stock() > 0:
		return null
	var source := button.get_seed_source()
	if source == null:
		return null
	remove_source(source)
	return source


func remove_source(source: Resource) -> void:
	for i in range(_flowers.size() - 1, -1, -1):
		var flower := _flowers[i]
		if flower == source:
			_flowers.remove_at(i)
			continue
		if source is DreamSeedSkillDefinition and flower != null and flower.dream_seed_skill == source:
			_flowers.remove_at(i)


func create_seed_block(
	owner: Node,
	stomach: StomachBoard,
	enemy_definitions: Array[Resource],
	seed_skill: DreamSeedSkillDefinition
) -> Enemy:
	if seed_skill == null:
		return null
	var definition := _get_seed_block_template(enemy_definitions)
	if definition == null:
		return null
	var seed_block := ENEMY_SCENE.instantiate() as Enemy
	owner.add_child(seed_block)
	var block_size := _get_seed_block_stomach_size(seed_skill)
	var target_size := Vector2(
		stomach.get_span_size(block_size.x),
		stomach.get_span_size(block_size.y)
	)
	seed_block.setup(definition, target_size, null, false, Vector2.ZERO)
	seed_block.setup_as_seed_stomach_block(seed_skill, target_size)
	return seed_block


func try_place_seed_block(
	seed_block: Enemy,
	mouse_position: Vector2,
	stomach: StomachBoard,
	enemies: Array[Enemy],
	input_controller: GameInputController
) -> bool:
	if seed_block == null:
		return false
	var top_left := stomach.get_drop_cell(seed_block, mouse_position, Vector2i.ZERO, enemies)
	if not stomach.can_place(seed_block, top_left, enemies):
		return false
	seed_block.modulate.a = 1.0
	seed_block.set_digesting(true)
	enemies.append(seed_block)
	input_controller.setup(enemies)
	stomach.place_enemy(seed_block, top_left)
	return true


func cancel_seed_block(seed_block: Enemy) -> void:
	if seed_block != null:
		seed_block.queue_free()


func apply_activation(
	seed_skill: DreamSeedSkillDefinition,
	current_hp: int,
	max_hp: int,
	digest_controller: NightmareDigestController
) -> Dictionary:
	if seed_skill.skill_id == DREAM_SEED_ACTIVATION_HP_RECOVERY:
		return {
			"applied": true,
			"hp": mini(max_hp, current_hp + ceili(float(max_hp) * DREAM_SEED_ACTIVATION_HP_RECOVERY_RATE)),
		}
	if seed_skill.skill_id == DREAM_SEED_ACTIVATION_SKIP_REST_TIME:
		rest_time_skip_count += 1
		return {
			"applied": true,
			"hp": current_hp,
		}
	return {
		"applied": digest_controller.add_seed_activation_effect(seed_skill),
		"hp": current_hp,
	}


func consume_rest_time_skip() -> bool:
	if rest_time_skip_count <= 0:
		return false
	rest_time_skip_count -= 1
	return true


func _get_seed_block_stomach_size(seed_skill: DreamSeedSkillDefinition) -> Vector2i:
	if seed_skill != null and seed_skill.drag_block_definition != null:
		return seed_skill.drag_block_definition.get_stomach_size()
	return Vector2i.ONE


func _get_seed_block_template(enemy_definitions: Array[Resource]) -> EnemyDefinition:
	for definition in enemy_definitions:
		if definition is EnemyDefinition:
			return definition as EnemyDefinition
	return null


func _get_random_debug_seed_flower() -> FlowerDefinition:
	var candidates := _get_debug_seed_flower_candidates()
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


func _get_debug_seed_flower_candidates() -> Array[FlowerDefinition]:
	var candidates: Array[FlowerDefinition] = []
	_append_debug_seed_flower_candidates(candidates, DREAM_SEED_SKILL_CATALOG.normal_skills)
	_append_debug_seed_flower_candidates(candidates, DREAM_SEED_SKILL_CATALOG.rare_skills)
	return candidates


func _append_debug_seed_flower_candidates(
	candidates: Array[FlowerDefinition],
	skills: Array
) -> void:
	for skill_resource in skills:
		if not skill_resource is DreamSeedSkillDefinition:
			continue
		var skill := skill_resource as DreamSeedSkillDefinition
		var flower := FlowerDefinition.new()
		flower.display_name = skill.display_name
		flower.texture = skill.texture
		flower.dream_seed_skill = skill
		candidates.append(flower)
