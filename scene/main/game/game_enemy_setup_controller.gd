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
var _enemy_preset: NightmarePresetInfo


# setup処理
func setup(
	owner: Node,
	input_controller: GameInputController,
	stomach: StomachBoard,
	enemy_preset: NightmarePresetInfo = null
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
	_setup_legacy_random_enemies(enemies)


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


# setuplegacyrandom敵処理
func _setup_legacy_random_enemies(enemies: Array[Enemy]) -> void:
	# selectedskills
	var selected_skills := _get_random_nightmare_skills()
	# 敵positions
	var enemy_positions := _get_enemy_positions(selected_skills.size())
	# maineffect敵番号
	var main_effect_enemy_index := randi() % selected_skills.size() if not selected_skills.is_empty() else -1
	for i in range(enemies.size()):
		# 敵値
		var enemy := enemies[i]
		if i >= selected_skills.size():
			enemy.visible = false
			enemy.Acided = true
			enemy.Aciding = false
			enemy.has_main_effect = false
			continue
		# 胃袋サイズ
		var stomach_size := _get_nightmare_stomach_size(selected_skills[i])
		enemy.setup(
			selected_skills[i],
			Vector2(
				_stomach.get_span_size(stomach_size.x),
				_stomach.get_span_size(stomach_size.y)
			),
			i == main_effect_enemy_index,
			enemy_positions[i],
			selected_skills[i].nightmare_skill_enabled
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


# random悪夢skills取得
func _get_random_nightmare_skills() -> Array[NightmareInfo]:
	# skillsbycategory
	var skills_by_category: Dictionary = {}
	return _pick_skills_from_category(skills_by_category)


# skillsfromcategory選択
func _pick_skills_from_category(skills_by_category: Dictionary) -> Array[NightmareInfo]:
	# categories
	var categories := skills_by_category.keys()
	if categories.is_empty():
		return []
	# category
	var category = categories[randi() % categories.size()]
	# categoryskills
	var category_skills: Array = skills_by_category[category].duplicate()
	category_skills.shuffle()
	# 最大数
	var max_count := mini(4, category_skills.size())
	# 最小数
	var min_count := mini(2, max_count)
	# 数値
	var count := randi_range(min_count, max_count)
	# selected
	var selected: Array[NightmareInfo] = []
	for i in range(count):
		selected.append(category_skills[i] as NightmareInfo)
	return selected


# stageスキル有効
func _is_stage_nightmare_skill_enabled(source_skill: NightmareInfo) -> bool:
	return source_skill != null and source_skill.skill_id >= STRENGTHENED_NIGHTMARE_SKILL_ID_MIN


# 悪夢胃袋サイズ取得
func _get_nightmare_stomach_size(skill: NightmareInfo) -> Vector2i:
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
