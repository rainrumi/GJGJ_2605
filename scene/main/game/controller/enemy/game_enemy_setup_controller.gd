class_name GameEnemySetupController
extends RefCounted

const ENEMY_TOP_Y := 140.0
const ENEMY_MIDDLE_Y := 195.0
const ENEMY_BOTTOM_Y := 252.5
const ENEMY_LEFT_X := 425.0
const ENEMY_CENTER_X := 500.0
const ENEMY_RIGHT_X := 575.0
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
const STRENGTHENED_NIGHTMARE_SKILL_ID_MIN := 20000
const DEFAULT_NIGHTMARE_STOMACH_SIZE := Vector2i(2, 3)

var _owner: Node
var _input_controller: GameInputController
var _stomach: StomachBoard
var _enemy_preset: EnemyPresetInfo


# setup処理
func setup(
	owner: Node,
	input_controller: GameInputController,
	stomach: StomachBoard,
	enemy_preset: EnemyPresetInfo = null
) -> void:
	_owner = owner
	_input_controller = input_controller
	_stomach = stomach
	_enemy_preset = enemy_preset


# setup敵処理
func setup_enemies(enemies: Array[Enemy]) -> void:
	if _enemy_preset != null and not _enemy_preset.enemies.is_empty():
		_setup_preset_enemies(enemies)
		return

# setup編成敵処理
func _setup_preset_enemies(enemies: Array[Enemy]) -> void:
	# 敵positions
	var enemy_positions := _get_enemy_positions(_enemy_preset.enemies.size())
	for i in range(enemies.size()):
		# 敵値
		var enemy := enemies[i]
		if i >= _enemy_preset.enemies.size():
			enemy.visible = false
			enemy.Acided = true
			enemy.Aciding = false
			enemy.has_main_effect = false
			continue
		# 元データスキル
		var source_skill := _enemy_preset.enemies[i]
		if source_skill == null:
			continue
		# スキル有効
		var skill_enabled := _is_stage_nightmare_skill_enabled(source_skill)
		# 胃袋サイズ
		var stomach_size := _get_nightmare_stomach_size(source_skill)
		enemy.setup(
			source_skill,
			Vector2(
				_stomach.get_span_size(stomach_size.x),
				_stomach.get_span_size(stomach_size.y)
			),
			skill_enabled,
			enemy_positions[i],
			skill_enabled
		)

# 生成nuisance悪夢処理
func spawn_nuisance_nightmare(
	enemies: Array[Enemy],
	source_enemy: Enemy,
	spawn_cell: Vector2i,
	hp_rate: float,
	damage_value: int,
	acid_damage_rate: float = 1.0,
	global_acid_damage_rate: float = 1.0
) -> bool:
	# nuisance敵
	var nuisance_enemy := _get_available_nuisance_enemy(enemies, source_enemy)
	if nuisance_enemy == null:
		return false
	# 元データorigin位置
	var source_origin_position := source_enemy.origin_position
	# 元データ最大HP
	var source_max_hp := source_enemy.max_hp
	nuisance_enemy.setup(
		source_enemy.get_nightmare_skill(),
		Vector2.ONE * _stomach.get_span_size(1),
		false,
		source_origin_position,
		false
	)
	nuisance_enemy.setup_as_one_cell_stomach_block(Vector2.ONE * _stomach.get_span_size(1))
	nuisance_enemy.change_max_hp(maxi(1, roundi(float(source_max_hp) * hp_rate)))
	nuisance_enemy.current_hp = nuisance_enemy.max_hp
	nuisance_enemy.set_damage_value(maxi(0, damage_value))
	nuisance_enemy.set_acid_damage_taken_multiplier(acid_damage_rate)
	nuisance_enemy.set_acid_damage_global_multiplier(global_acid_damage_rate)
	nuisance_enemy.set_Aciding(true)
	_stomach.place_enemy(nuisance_enemy, spawn_cell)
	return true
	

# availablenuisance敵取得
func _get_available_nuisance_enemy(enemies: Array[Enemy], source_enemy: Enemy) -> Enemy:
	for enemy in enemies:
		if enemy.visible or not enemy.Acided:
			continue
		return enemy
	if source_enemy.Acided:
		return source_enemy
	# 敵値
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	_owner.add_child(enemy)
	enemies.append(enemy)
	_input_controller.setup(enemies)
	return enemy


# stageスキル有効
func _is_stage_nightmare_skill_enabled(source_skill: EnemyInfo) -> bool:
	return source_skill != null and source_skill.skill_id >= STRENGTHENED_NIGHTMARE_SKILL_ID_MIN


# 悪夢胃袋サイズ取得
func _get_nightmare_stomach_size(skill: EnemyInfo) -> Vector2i:
	var block := skill.acid_block if skill != null else null
	return block.get_stomach_size() if block != null else DEFAULT_NIGHTMARE_STOMACH_SIZE


# 敵positions取得
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


# spawn要求適用
func apply_spawn_requests(
	spawn_requests: Array[BattleSpawnEnemyData],
	enemies: Array[Enemy]
) -> void:
	for request in spawn_requests:
		if request == null:
			continue
		if not spawn_nuisance_nightmare(
			enemies,
			request.source_enemy,
			request.cell,
			request.hp_rate,
			request.damage,
			request.acid_damage_rate,
			request.global_acid_damage_rate
		):
			break
