class_name Enemy
extends Node2D

# 敵ModelとView仲介
const AcidED_TWEEN_DURATION := EnemySpriteView.ACIDED_TWEEN_DURATION
const DEFAULT_STATUS_COLOR := EnemyView.DEFAULT_STATUS_COLOR
const MAIN_EFFECT_STATUS_COLOR := EnemyView.MAIN_EFFECT_STATUS_COLOR
const ENEMY_CELL_TEXTURE := preload("res://art/enemy/tex_enemy_1_1_100.png")
const DEFAULT_ENEMY_MAX_HP := 1400
const DEFAULT_ENEMY_SIZE := 6
const DEFAULT_ENEMY_DAMAGE := 2
const DEFAULT_ENEMY_STOMACH_SIZE := Vector2i(2, 3)
const DEFAULT_ENEMY_STOMACH_SHAPE: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(0, 2),
	Vector2i(1, 2),
]
# 敵表示
@onready var enemy_view: EnemyView = $View
var data := EnemyData.new() # 敵データ
var seed_info: SeedInfo
var max_hp: int:
	get: return data.hp.maximum
	set(value): data.hp.set_maximum(value)
var current_hp: int:
	get: return data.hp.current
	set(value): data.hp.set_current(value)
var damage: int:
	get: return data.attack.value
	set(value): data.attack.set_value(value, false)
var base_damage: int:
	get: return data.attack.base_value
	set(value): data.attack.base_value = maxi(0, value)
var display_damage_override: int:
	get: return data.attack.display_override
	set(value): data.attack.set_display_override(value)
var attack_multiplier: float:
	get: return data.attack.multiplier
	set(value): data.attack.set_multiplier(value)
var acid_damage_taken_multiplier: float:
	get: return data.defense_status.taken_acid_multiplier
	set(value): data.defense_status.set_taken_acid_multiplier(value)
var acid_damage_global_multiplier: float:
	get: return data.defense_status.global_acid_multiplier
	set(value): data.defense_status.set_global_acid_multiplier(value)
var stomach_elapsed_minutes: int:
	get: return data.stomach_status.elapsed_minutes
	set(value): data.stomach_status.set_elapsed_minutes(value)
var revive_count: int:
	get: return data.stomach_status.revive_count
	set(value): data.stomach_status.revive_count = maxi(0, value)
var Aciding: bool:
	get: return data.stomach_status.is_digesting
	set(value): data.stomach_status.set_digesting(value)
var Acided: bool:
	get: return data.stomach_status.is_digested
	set(value): data.stomach_status.set_digested(value)
var gravity_locked: bool:
	get: return data.stomach_status.gravity_locked
	set(value): data.stomach_status.gravity_locked = value
var activation_deferred: bool:
	get: return data.stomach_status.activation_deferred
	set(value): data.stomach_status.activation_deferred = value
var stomach_cell: Vector2i:
	get: return data.stomach_status.cell
	set(value): data.stomach_status.cell = value
var origin_position := Vector2.ZERO
var _stomach_size_override := Vector2i.ZERO
var _stomach_shape_override: Array[Vector2i] = []
var _size_override := 0
var _texture_override: Texture2D
var _presenter := EnemyPresenter.new() # Model表示仲介


# 表示準備
func _ready() -> void:
	enemy_view.setup(self)
	_presenter.bind(data, enemy_view)


# 表示接続解除
func _exit_tree() -> void:
	_presenter.unbind()


# 表示仲介取得
func get_presenter() -> EnemyPresenter:
	return _presenter


# setup処理
func setup(enemy_info: EnemyInfo, target_size: Vector2, has_effect := false, start_position_override := Vector2.INF, skill_enabled_override := true) -> void:
	data.definition = enemy_info
	seed_info = null
	data.skills_enabled = skill_enabled_override
	data.main_skill_active = has_effect and data.skills_enabled
	data.setup(
		enemy_info,
		_get_enemy_max_hp(),
		_get_enemy_damage(),
		data.main_skill_active,
		data.skills_enabled
	)
	acid_damage_taken_multiplier = 1.0
	acid_damage_global_multiplier = 1.0
	stomach_elapsed_minutes = 0
	revive_count = 0
	gravity_locked = false
	activation_deferred = false
	_texture_override = null
	clear_stomach_footprint_override()
	origin_position = Vector2.ZERO
	if start_position_override != Vector2.INF:
		origin_position = start_position_override
	position = origin_position
	_presenter.setup_texture(_get_texture(), target_size)
	reset_for_battle()


# 種setup
func setup_seed(seed: SeedInfo, target_size: Vector2, start_position_override := Vector2.ZERO) -> void:
	setup(null, target_size, false, start_position_override, false)
	setup_as_seed_stomach_block(seed, target_size)
# for戦闘初期化
func reset_for_battle() -> void:
	current_hp = max_hp
	Aciding = false
	Acided = false
	gravity_locked = false
	activation_deferred = false
	stomach_cell = Vector2i.ZERO
	stomach_elapsed_minutes = 0
	revive_count = 0
	set_presented(true)
	_reset_visuals()
	return_to_origin()
	set_hovered(false)
	_update_hp_label()
	_update_damage_label()
	_update_status_label_colors()
# displayname取得
func get_display_name() -> String:
	if seed_info != null and not seed_info.display_name.is_empty():
		return seed_info.display_name
	if data.definition != null and not data.definition.display_name.is_empty():
		return data.definition.display_name
	return ""


# 種胃袋ブロック判定
func is_seed_stomach_block() -> bool:
	return seed_info != null


# 種スキル判定
func has_seed() -> bool:
	return seed_info != null


# 種スキル取得
func get_seed() -> SeedInfo:
	return seed_info


# 悪夢スキル判定
func has_enemy_info() -> bool:
	return data.definition != null


# 悪夢スキル取得
func get_enemy_info() -> EnemyInfo:
	return data.definition


# 敵skill取得
func get_enemy_skill() -> EnemySkill:
	return data.get_active_skill()


# 敵effects取得
func get_enemy_effects() -> Array[EnemyEffect]:
	return data.get_effects()


# 悪夢判定
func is_enemy() -> bool:
	return not is_seed_stomach_block()


# 胃袋piece判定
func is_stomach_piece() -> bool:
	return is_active_in_stomach()


# should数for戦闘clear処理
func should_count_for_battle_clear() -> bool:
	return is_enemy()


# shouldapply悪夢スキル処理
func should_apply_enemy_skill() -> bool:
	return is_enemy() and data.skills_enabled


# shoulddealplayerダメ処理
func should_deal_player_damage() -> bool:
	return is_enemy()


# should数for消化order処理
func should_count_for_acid_order() -> bool:
	return is_enemy()


# 悪夢reactions処理
func should_trigger_enemy_reactions() -> bool:
	return is_enemy()


# ダメージ取得
func get_damage() -> int: return maxi(0, roundi(float(damage) * attack_multiplier))
# displayダメージ取得
func get_display_damage() -> int: return display_damage_override if display_damage_override >= 0 else get_damage()
# baseダメージ取得
func get_base_damage() -> int: return base_damage
# 最大HP取得
func get_max_hp() -> int: return max_hp
# HP取得
func get_current_hp() -> int: return current_hp
# revive数取得
func get_revive_count() -> int: return revive_count
# 消化済み判定
func is_Acided() -> bool: return Acided
# Aciding判定
func is_Aciding() -> bool: return Aciding
# activationdeferred判定
func is_activation_deferred() -> bool: return activation_deferred


# サイズ取得
func get_size() -> int:
	if _size_override > 0:
		return _size_override
	return _get_enemy_cell_count()


# 胃袋サイズ取得
func get_stomach_size() -> Vector2i:
	if _stomach_size_override != Vector2i.ZERO:
		return _stomach_size_override
	return _get_enemy_stomach_size()


# 胃袋形状取得
func get_stomach_shape() -> Array[Vector2i]:
	if not _stomach_shape_override.is_empty():
		return _stomach_shape_override.duplicate()
	# 形状
	return _get_enemy_stomach_shape()


# 90度右回転後の胃袋サイズ取得
func get_clockwise_rotated_stomach_size() -> Vector2i:
	var current_size := get_stomach_size()
	return Vector2i(current_size.y, current_size.x)


# 90度右回転後の胃袋形状取得
func get_clockwise_rotated_stomach_shape() -> Array[Vector2i]:
	var current_size := get_stomach_size()
	var rotated_shape: Array[Vector2i] = []
	for cell: Vector2i in get_stomach_shape():
		rotated_shape.append(Vector2i(current_size.y - 1 - cell.y, cell.x))
	return rotated_shape


# 胃袋形状90度右回転
func rotate_stomach_footprint_clockwise(target_size: Vector2) -> void:
	set_stomach_footprint_override(
		get_clockwise_rotated_stomach_size(),
		get_clockwise_rotated_stomach_shape(),
		get_size()
	)
	_presenter.setup_texture(_get_texture(), target_size)
	_reset_visuals()


# ドラッグ判定
func can_drag() -> bool:
	return not Acided


# activein胃袋判定
func is_active_in_stomach() -> bool:
	return Aciding and not Acided


# take胃袋turn判定
func can_take_stomach_turn() -> bool:
	return is_active_in_stomach() and not activation_deferred
# Aciding設定
func set_Aciding(value: bool) -> void:
	if Aciding != value:
		stomach_elapsed_minutes = 0
	Aciding = value
# 消化済み設定
func set_Acided(value: bool) -> void:
	Acided = value
	if Acided:
		Aciding = false
# 胃袋セル設定
func set_stomach_cell(cell: Vector2i) -> void:
	stomach_cell = cell
# 胃袋footprintoverrid設定
func set_stomach_footprint_override(size: Vector2i, shape: Array[Vector2i], cell_count: int) -> void:
	_stomach_size_override = size
	_stomach_shape_override = shape.duplicate()
	_size_override = cell_count
# 画像override設定
func set_texture_override(texture: Texture2D, target_size: Vector2) -> void:
	_texture_override = texture
	if _texture_override == null:
		return
	_presenter.setup_texture(_texture_override, target_size)
	_reset_visuals()
# setupasoneセル胃袋ブロック処理
func setup_as_one_cell_stomach_block(target_size: Vector2) -> void:
	# ブロック形状
	var block_shape: Array[Vector2i] = [Vector2i.ZERO]
	set_stomach_footprint_override(Vector2i.ONE, block_shape, 1)
	gravity_locked = true
	activation_deferred = true


# setupas種胃袋ブロック処理
func setup_as_seed_stomach_block(seed: SeedInfo, target_size: Vector2) -> void:
	# ブロック定義
	var block_definition := seed.acid_block if seed != null else null
	if block_definition != null:
		set_stomach_footprint_override(
			block_definition.get_stomach_size(),
			block_definition.get_stomach_shape(),
			block_definition.get_cell_count()
		)
		gravity_locked = true
		activation_deferred = false
	else:
		setup_as_one_cell_stomach_block(target_size)
		activation_deferred = false
	seed_info = seed
	max_hp = block_definition.get_max_hp() if block_definition != null else 1
	current_hp = max_hp
	damage = block_definition.get_damage() if block_definition != null else 0
	base_damage = damage
	display_damage_override = damage
	_update_hp_label()
	_update_damage_label()


# 胃袋displayサイズ更新
func update_stomach_display_size(target_size: Vector2) -> void:
	_presenter.update_display_size(target_size)
# applygravity判定
func can_apply_gravity() -> bool:
	return not gravity_locked
# gravitylock消去
func clear_gravity_lock() -> void:
	gravity_locked = false
# activate胃袋turn処理
func activate_stomach_turn() -> void:
	activation_deferred = false
# 胃袋footprintoverrid消去
func clear_stomach_footprint_override() -> void:
	_stomach_size_override = Vector2i.ZERO
	_stomach_shape_override.clear()
	_size_override = 0
# toorigin返却
func return_to_origin() -> void:
	position = origin_position
# hovered設定
func set_hovered(value: bool) -> void:
	_presenter.set_hovered(value)


# 表示状態設定
func set_presented(value: bool) -> void:
	_presenter.set_presented(value)


# ツール表示
func show_tooltip(debug_number_text: String, debug_numbers_visible: bool) -> void:
	_presenter.show_tooltip(debug_number_text, debug_numbers_visible)


# ツール非表示
func hide_tooltip() -> void:
	_presenter.hide_tooltip()


# プレビュー画像取得
func get_preview_texture() -> Texture2D:
	return _presenter.get_preview_texture()


# プレビュー倍率取得
func get_preview_scale() -> Vector2:
	return _presenter.get_preview_scale()
# pulsecostラベル処理
func pulse_cost_label() -> void:
	_presenter.present_hp_pulse()
# pulseダメージ処理
func pulse_damage() -> void:
	_presenter.present_damage_pulse()
# take消化ダメージ処理
func take_acid_damage(amount: int, show_popup := true) -> bool:
	if show_popup:
		_presenter.present_damage_popup(amount)
	if data.hp.take_damage(amount):
		set_Acided(true)
		return true
	return false
# 消化ダメージvalues表示
func show_acid_damage_values(damage_values: Array) -> void:
	_presenter.present_damage_values(damage_values)
# globalrect取得
func get_global_rect() -> Rect2:
	var presented_rect := _presenter.get_global_rect() # 表示矩形
	if presented_rect.size != Vector2.ZERO:
		return presented_rect
	return Rect2(global_position - Vector2(25.0, 25.0), Vector2(50.0, 50.0))
# grabセル取得
func get_grab_cell(mouse_position: Vector2) -> Vector2i:
	# 敵rect
	var enemy_rect := get_global_rect()
	# 敵サイズ
	var enemy_size := get_stomach_size()
	# relative位置
	var relative_position := mouse_position - enemy_rect.position
	# guessedセル
	var guessed_cell := Vector2i(clampi(int(relative_position.x / enemy_rect.size.x * float(enemy_size.x)), 0, enemy_size.x - 1), clampi(int(relative_position.y / enemy_rect.size.y * float(enemy_size.y)), 0, enemy_size.y - 1))
	if get_stomach_shape().has(guessed_cell):
		return guessed_cell
	return _get_nearest_shape_cell(guessed_cell)
# occupiedcells取得
func get_occupied_cells(top_left: Vector2i) -> Array[Vector2i]:
	# cells
	var cells: Array[Vector2i] = []
	for offset in get_stomach_shape():
		cells.append(top_left + offset)
	return cells
# bottom行取得
func get_bottom_row(top_left: Vector2i) -> int:
	# bottom行
	var bottom_row := 0
	for cell in get_occupied_cells(top_left):
		bottom_row = maxi(bottom_row, cell.y)
	return bottom_row
# nearest形状セル取得
func _get_nearest_shape_cell(target_cell: Vector2i) -> Vector2i:
	# nearestセル
	var nearest_cell := Vector2i.ZERO
	# nearestdistance
	var nearest_distance := INF
	for offset in get_stomach_shape():
		# diff
		var diff := target_cell - offset
		# distance
		var distance := float(diff.x * diff.x + diff.y * diff.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = offset
	return nearest_cell
# 消化済みトゥイーン再生
func _play_Acided_tween() -> void:
	_presenter.present_digested()
# visuals初期化
func _reset_visuals() -> void:
	_presenter.reset_visuals()
# HPラベル更新
func _update_hp_label() -> void:
	_presenter.present_hp(current_hp)
# displayダメージ設定
func set_display_damage(value: int) -> void: display_damage_override = maxi(0, value); _update_damage_label()
# ダメージラベル更新
func _update_damage_label() -> void:
	_presenter.present_attack(get_display_damage())
# 画像取得
func _get_texture() -> Texture2D:
	if _texture_override != null:
		return _texture_override
	return EnemySpriteView.create_shape_texture(
		ENEMY_CELL_TEXTURE,
		get_stomach_size(),
		get_stomach_shape()
	)


# enemyblock取得
func _get_enemy_block() -> AcidBlockInfo:
	if data.definition == null:
		return null
	return data.definition.acid_block


# enemyHP取得
func _get_enemy_max_hp() -> int:
	var block := _get_enemy_block()
	return block.get_max_hp() if block != null else DEFAULT_ENEMY_MAX_HP


# enemy攻撃取得
func _get_enemy_damage() -> int:
	var block := _get_enemy_block()
	return block.get_damage() if block != null else DEFAULT_ENEMY_DAMAGE


# enemyセル数
func _get_enemy_cell_count() -> int:
	var block := _get_enemy_block()
	return block.get_cell_count() if block != null else DEFAULT_ENEMY_SIZE


# enemyサイズ
func _get_enemy_stomach_size() -> Vector2i:
	var block := _get_enemy_block()
	return block.get_stomach_size() if block != null else DEFAULT_ENEMY_STOMACH_SIZE


# enemy形状
func _get_enemy_stomach_shape() -> Array[Vector2i]:
	var block := _get_enemy_block()
	return block.get_stomach_shape() if block != null else DEFAULT_ENEMY_STOMACH_SHAPE.duplicate()
# categoryname取得
func get_category_name() -> String:
	return EnemyTooltipFormatter.get_category_name(data.main_skill_active, data.definition)
# categorydetail取得
func get_category_detail() -> String:
	return EnemyTooltipFormatter.get_category_detail(data.main_skill_active, data.definition)
# maineffect文言取得
func get_main_effect_text() -> String:
	return EnemyTooltipFormatter.get_main_effect_text(data.main_skill_active, data.definition)
# subeffect文言取得
func get_sub_effect_text() -> String:
	return "-"
# 回復処理
func heal(amount: int) -> void:
	data.hp.heal(amount)
# 回復over最大処理
func heal_over_max(amount: int) -> void:
	data.hp.heal_over_max(amount)
# change最大HP処理
func change_max_hp(new_max_hp: int) -> void:
	data.hp.set_maximum(new_max_hp)
# 最大HP追加
func add_max_hp(amount: int, also_heal := true) -> void:
	data.hp.add_maximum(amount, also_heal)
# HPvalues設定
func set_hp_values(next_max_hp: int, next_current_hp: int) -> void:
	data.hp.set_values(next_max_hp, next_current_hp)
# ダメージ追加
func add_damage(amount: int) -> void:
	data.attack.add_value(amount)
# ダメージ値設定
func set_damage_value(value: int) -> void:
	data.attack.set_value(value)
# attack倍率設定
func set_attack_multiplier(value: float) -> void:
	data.attack.set_multiplier(value)
# 消化ダメージtaken倍率設定
func set_acid_damage_taken_multiplier(value: float) -> void:
	acid_damage_taken_multiplier = value
# 消化ダメージglobal倍率設定
func set_acid_damage_global_multiplier(value: float) -> void:
	acid_damage_global_multiplier = value
# revivewithhalfHP処理
func revive_with_half_hp() -> void:
	revive_with_hp_rate(0.5)
# revivewithHP率処理
func revive_with_hp_rate(hp_rate: float) -> void:
	data.stomach_status.record_revive()
	change_max_hp(ceili(float(max_hp) * hp_rate))
	current_hp = max_hp
	Acided = false
	Aciding = false
	set_presented(true)
	return_to_origin()
	_update_hp_label()
# 状態ラベルcolors更新
func _update_status_label_colors() -> void:
	_presenter.update_status_colors(data.main_skill_active)
