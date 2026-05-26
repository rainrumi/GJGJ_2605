class_name GameDreamSeedController
extends RefCounted

const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
const SEED_BLOCK_DRAG_ALPHA := 0.58
const DREAM_SEED_DIGEST_HP_RECOVERY := 1002
const DREAM_SEED_DIGEST_HP_RECOVERY_RATE := 0.05
const DREAM_SEED_DIGEST_SKIP_REST_TIME := 1004

var rest_time_skip_count := 0
var _flowers: Array[FlowerDefinition] = []
var _owner: Node
var _stomach: StomachBoard
var _input_controller: GameInputController
var _dragging_seed_block: Enemy
var _dragging_seed_button: DreamSeedSkillButton
var _dragging_seed_skill: DreamSeedSkillDefinition
var _pending_depleted_sources_by_block: Dictionary = {}
var debug_factory := DreamSeedDebugFactory.new()


func setup(
	owner: Node,
	stomach: StomachBoard,
	input_controller: GameInputController
) -> void:
	_owner = owner
	_stomach = stomach
	_input_controller = input_controller


func set_flowers(flowers: Array) -> void:
	_flowers.clear()
	_pending_depleted_sources_by_block.clear()
	rest_time_skip_count = 0
	for flower in flowers:
		if flower is FlowerDefinition:
			_flowers.append(flower as FlowerDefinition)


func get_flowers() -> Array[FlowerDefinition]:
	return _flowers


func remove_source_while_in_stomach(button: DreamSeedSkillButton, seed_block: Enemy) -> void:
	if button == null or button.get_remaining_sub_skill_uses() > 0:
		return
	var source := button.get_seed_source()
	if source == null:
		return
	remove_source(source)
	if seed_block != null:
		_pending_depleted_sources_by_block[seed_block] = source


func collect_depleted_sources(digested_enemies: Array[Enemy]) -> Array[Resource]:
	var sources: Array[Resource] = []
	for enemy in digested_enemies:
		if not _pending_depleted_sources_by_block.has(enemy):
			continue
		var source := _pending_depleted_sources_by_block[enemy] as Resource
		_pending_depleted_sources_by_block.erase(enemy)
		if source != null:
			sources.append(source)
	return sources


func remove_source(source: Resource) -> void:
	for i in range(_flowers.size() - 1, -1, -1):
		var flower := _flowers[i]
		if flower == source:
			_flowers.remove_at(i)
			continue
		if source is DreamSeedSkillDefinition and flower != null and flower.dream_seed_skill == source:
			_flowers.remove_at(i)


func start_drag(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> DreamSeedDragResult:
	var result := DreamSeedDragResult.new()
	result.source_button = button
	result.seed_skill = seed_skill
	if is_dragging():
		return result
	var seed_block := _create_seed_block(seed_skill)
	if seed_block == null:
		return result
	_dragging_seed_button = button
	_dragging_seed_skill = seed_skill
	_dragging_seed_block = seed_block
	_dragging_seed_block.global_position = mouse_position
	_dragging_seed_block.modulate.a = SEED_BLOCK_DRAG_ALPHA
	result.started = true
	result.seed_block = seed_block
	return result


func move_drag(mouse_position: Vector2, enemies: Array[Enemy]) -> void:
	if _dragging_seed_block == null:
		return
	_dragging_seed_block.global_position = mouse_position
	_stomach.show_preview(_dragging_seed_block, mouse_position, Vector2i.ZERO, enemies)


func release_drag(mouse_position: Vector2, enemies: Array[Enemy]) -> DreamSeedDragResult:
	var result := DreamSeedDragResult.new()
	if _dragging_seed_block == null:
		return result
	result.started = true
	result.seed_block = _dragging_seed_block
	result.source_button = _dragging_seed_button
	result.seed_skill = _dragging_seed_skill
	result.source = _dragging_seed_button.get_seed_source() if _dragging_seed_button != null else null
	_dragging_seed_block = null
	_dragging_seed_button = null
	_dragging_seed_skill = null
	_stomach.hide_preview()
	if _stomach.contains_global_position(mouse_position) and _try_place_seed_block(result.seed_block, mouse_position, enemies):
		result.placed = true
	else:
		cancel_seed_block(result.seed_block)
		result.cancelled = true
	return result


func cancel_drag() -> void:
	if _dragging_seed_block != null:
		cancel_seed_block(_dragging_seed_block)
	_dragging_seed_block = null
	_dragging_seed_button = null
	_dragging_seed_skill = null
	if _stomach != null:
		_stomach.hide_preview()


func is_dragging() -> bool:
	return _dragging_seed_block != null


func _create_seed_block(
	seed_skill: DreamSeedSkillDefinition
) -> Enemy:
	if seed_skill == null:
		return null
	var definition := _get_seed_block_template(seed_skill)
	if definition == null:
		return null
	var seed_block := ENEMY_SCENE.instantiate() as Enemy
	_owner.add_child(seed_block)
	var block_size := _get_seed_block_stomach_size(seed_skill)
	var target_size := Vector2(
		_stomach.get_span_size(block_size.x),
		_stomach.get_span_size(block_size.y)
	)
	seed_block.setup(definition, target_size, null, false, Vector2.ZERO)
	seed_block.setup_as_seed_stomach_block(seed_skill, target_size)
	return seed_block


func _try_place_seed_block(
	seed_block: Enemy,
	mouse_position: Vector2,
	enemies: Array[Enemy]
) -> bool:
	if seed_block == null:
		return false
	var top_left := _stomach.get_drop_cell(seed_block, mouse_position, Vector2i.ZERO, enemies)
	if not _stomach.can_place(seed_block, top_left, enemies):
		return false
	seed_block.modulate.a = 1.0
	seed_block.set_digesting(true)
	enemies.append(seed_block)
	_input_controller.setup(enemies)
	_stomach.place_enemy(seed_block, top_left)
	return true


func cancel_seed_block(seed_block: Enemy) -> void:
	if seed_block != null:
		seed_block.queue_free()


func _get_seed_block_stomach_size(seed_skill: DreamSeedSkillDefinition) -> Vector2i:
	if seed_skill != null and seed_skill.drag_block_definition != null:
		return seed_skill.drag_block_definition.get_stomach_size()
	return Vector2i.ONE


func _get_seed_block_template(seed_skill: DreamSeedSkillDefinition) -> EnemyDefinition:
	return _create_seed_block_template(seed_skill)


func _create_seed_block_template(seed_skill: DreamSeedSkillDefinition) -> EnemyDefinition:
	if seed_skill == null:
		return null
	var block_definition := seed_skill.drag_block_definition
	var definition := EnemyDefinition.new()
	definition.display_name = seed_skill.display_name
	definition.texture = seed_skill.texture
	definition.max_hp = 1
	definition.size = 1
	definition.damage = 0
	definition.nightmare_skill_enabled = false
	definition.stomach_size = Vector2i.ONE
	definition.stomach_shape = [Vector2i.ZERO]
	if block_definition != null:
		if block_definition.texture != null:
			definition.texture = block_definition.texture
		definition.max_hp = block_definition.get_max_hp()
		definition.size = block_definition.get_cell_count()
		definition.damage = block_definition.get_damage()
		definition.stomach_size = block_definition.get_stomach_size()
		definition.stomach_shape = block_definition.get_stomach_shape()
	return definition


func apply_direct_digested_seed_effects(
	digested_enemies: Array[Enemy],
	current_hp: int,
	max_hp: int
) -> int:
	var next_hp := current_hp
	for enemy in digested_enemies:
		if enemy == null or not enemy.has_seed_skill():
			continue
		var seed_skill := enemy.get_seed_skill()
		if seed_skill.skill_id == DREAM_SEED_DIGEST_HP_RECOVERY:
			next_hp = mini(max_hp, next_hp + ceili(float(max_hp) * DREAM_SEED_DIGEST_HP_RECOVERY_RATE))
			continue
		if seed_skill.skill_id == DREAM_SEED_DIGEST_SKIP_REST_TIME:
			rest_time_skip_count += 1
	return next_hp


func collect_digested_seed_skills(digested_enemies: Array[Enemy]) -> Array[DreamSeedSkillDefinition]:
	var skills: Array[DreamSeedSkillDefinition] = []
	for enemy in digested_enemies:
		if enemy == null or not enemy.has_seed_skill():
			continue
		var seed_skill := enemy.get_seed_skill()
		if _is_direct_controller_effect(seed_skill):
			continue
		skills.append(seed_skill)
	return skills


func consume_rest_time_skip() -> bool:
	if rest_time_skip_count <= 0:
		return false
	rest_time_skip_count -= 1
	return true


func _is_direct_controller_effect(seed_skill: DreamSeedSkillDefinition) -> bool:
	return (
		seed_skill.skill_id == DREAM_SEED_DIGEST_HP_RECOVERY
		or seed_skill.skill_id == DREAM_SEED_DIGEST_SKIP_REST_TIME
	)


func add_random_debug_seed() -> bool:
	var flower := debug_factory.create_random_debug_seed_flower()
	if flower == null:
		return false
	_flowers.append(flower)
	return true
