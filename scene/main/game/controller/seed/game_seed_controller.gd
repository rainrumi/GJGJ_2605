class_name GameSeedController
extends RefCounted

const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
const SEED_BLOCK_DRAG_ALPHA := 0.58

var rest_time_skip_count := 0
var _flowers: Array[SeedInfo] = []
var _owner: Node
var _stomach: StomachBoard
var _input_controller: GameInputController
var _dragging_seed_block: Enemy
var _dragging_seed_button_list: SeedButton
var _dragging_seed: SeedInfo
var _pending_depleted_sources_by_block: Dictionary = {}
var debug_factory := SeedDebug.new()


# setup処理
func setup(
	owner: Node,
	stomach: StomachBoard,
	input_controller: GameInputController
) -> void:
	_owner = owner
	_stomach = stomach
	_input_controller = input_controller


# 花値設定
func set_flowers(flowers: Array) -> void:
	_flowers.clear()
	_pending_depleted_sources_by_block.clear()
	rest_time_skip_count = 0
	for flower in flowers:
		if flower is SeedInfo:
			_flowers.append(flower as SeedInfo)


# 花値取得
func get_flowers() -> Array[SeedInfo]:
	return _flowers


# 元データwhilein胃袋削除
func remove_source_while_in_stomach(button: SeedButton, seed_block: Enemy) -> void:
	if button == null or button.get_remaining_sub_skill_uses() > 0:
		return
	# 元データ
	var source := button.get_seed_source()
	if source == null:
		return
	remove_source(source)
	if seed_block != null:
		_pending_depleted_sources_by_block[seed_block] = source


# 枯渇処理
func collect_depleted_sources(Acided_enemies: Array[Enemy]) -> Array[Resource]:
	# sources
	var sources: Array[Resource] = []
	for enemy in Acided_enemies:
		if not _pending_depleted_sources_by_block.has(enemy):
			continue
		# 元データ
		var source := _pending_depleted_sources_by_block[enemy] as Resource
		_pending_depleted_sources_by_block.erase(enemy)
		if source != null:
			sources.append(source)
	return sources


# 元データ削除
func remove_source(source: Resource) -> void:
	for i in range(_flowers.size() - 1, -1, -1):
		# 花値
		var flower := _flowers[i]
		if flower == source:
			_flowers.remove_at(i)
			continue
		if source is SeedInfo:
			_flowers.remove_at(i)


# ドラッグ開始
func start_drag(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> SeedDragData:
	# 結果
	var result := SeedDragData.new()
	result.source_button = button
	result.seed = seed
	if is_dragging():
		return result
	# 種ブロック
	var seed_block := _create_seed_block(seed)
	if seed_block == null:
		return result
	_dragging_seed_button_list = button
	_dragging_seed = seed
	_dragging_seed_block = seed_block
	_dragging_seed_block.global_position = mouse_position
	_dragging_seed_block.modulate.a = SEED_BLOCK_DRAG_ALPHA
	result.started = true
	result.seed_block = seed_block
	return result


# moveドラッグ処理
func move_drag(mouse_position: Vector2, enemies: Array[Enemy]) -> void:
	if _dragging_seed_block == null:
		return
	_dragging_seed_block.global_position = mouse_position
	_stomach.show_preview(_dragging_seed_block, mouse_position, Vector2i.ZERO, enemies)


# releaseドラッグ処理
func release_drag(mouse_position: Vector2, enemies: Array[Enemy]) -> SeedDragData:
	# 結果
	var result := SeedDragData.new()
	if _dragging_seed_block == null:
		return result
	result.started = true
	result.seed_block = _dragging_seed_block
	result.source_button = _dragging_seed_button_list
	result.seed = _dragging_seed
	result.source = _dragging_seed_button_list.get_seed_source() if _dragging_seed_button_list != null else null
	_dragging_seed_block = null
	_dragging_seed_button_list = null
	_dragging_seed = null
	_stomach.hide_preview()
	if _stomach.contains_global_position(mouse_position) and _try_place_seed_block(result.seed_block, mouse_position, enemies):
		result.placed = true
	else:
		cancel_seed_block(result.seed_block)
		result.cancelled = true
	return result


# ドラッグ取消
func cancel_drag() -> void:
	if _dragging_seed_block != null:
		cancel_seed_block(_dragging_seed_block)
	_dragging_seed_block = null
	_dragging_seed_button_list = null
	_dragging_seed = null
	if _stomach != null:
		_stomach.hide_preview()


# dragging判定
func is_dragging() -> bool:
	return _dragging_seed_block != null


# 種ブロック作成
func _create_seed_block(
	seed: SeedInfo
) -> Enemy:
	if seed == null:
		return null
	# 種ブロック
	var seed_block := ENEMY_SCENE.instantiate() as Enemy
	_owner.add_child(seed_block)
	# ブロックサイズ
	var block_size := _get_seed_block_stomach_size(seed)
	# 対象サイズ
	var target_size := Vector2(
		_stomach.get_span_size(block_size.x),
		_stomach.get_span_size(block_size.y)
	)
	seed_block.setup_seed(seed, target_size, Vector2.ZERO)
	return seed_block


# place種ブロック試行
func _try_place_seed_block(
	seed_block: Enemy,
	mouse_position: Vector2,
	enemies: Array[Enemy]
) -> bool:
	if seed_block == null:
		return false
	# topleft
	var top_left := _stomach.get_drop_cell(seed_block, mouse_position, Vector2i.ZERO, enemies)
	if not _stomach.can_place(seed_block, top_left, enemies):
		return false
	seed_block.modulate.a = 1.0
	seed_block.set_Aciding(true)
	enemies.append(seed_block)
	_input_controller.setup(enemies)
	_stomach.place_enemy(seed_block, top_left)
	return true


# 種ブロック取消
func cancel_seed_block(seed_block: Enemy) -> void:
	if seed_block != null:
		seed_block.queue_free()


# 種ブロック胃袋サイズ取得
func _get_seed_block_stomach_size(seed: SeedInfo) -> Vector2i:
	if seed != null and seed.acid_block != null:
		return seed.acid_block.get_stomach_size()
	return Vector2i.ONE


# direct消化済み種effects適用
func apply_direct_Acided_seed_effects(
	Acided_enemies: Array[Enemy],
	current_hp: int,
	max_hp: int
) -> int:
	# HP
	var next_hp := current_hp
	for enemy in Acided_enemies:
		if enemy == null or not enemy.has_seed():
			continue
		# 種値
		var seed := enemy.get_seed()
		for effect in _get_finish_seed_effects(seed):
			if effect is SeedEffectOnFinishAcidSeedRecoverHp:
				# 回復効果
				var recover_effect := effect as SeedEffectOnFinishAcidSeedRecoverHp
				next_hp = mini(max_hp, next_hp + _get_seed_recovery_amount(recover_effect, enemy, max_hp))
				continue
			if effect is SeedEffectOnFinishAcidSeedSkipRestTime:
				# skip効果
				var skip_effect := effect as SeedEffectOnFinishAcidSeedSkipRestTime
				rest_time_skip_count += maxi(0, skip_effect.skip_count)
	return next_hp


# collect消化済み種skills処理
func collect_Acided_seeds(Acided_enemies: Array[Enemy]) -> Array[SeedInfo]:
	# skills
	var skills: Array[SeedInfo] = []
	for enemy in Acided_enemies:
		if enemy == null or not enemy.has_seed():
			continue
		# 種スキル
		var seed := enemy.get_seed()
		if _is_direct_controller_effect(seed):
			continue
		skills.append(seed)
	return skills


# 休憩時間skip消費
func consume_rest_time_skip() -> bool:
	if rest_time_skip_count <= 0:
		return false
	rest_time_skip_count -= 1
	return true


# controllereffect判定
func _is_direct_controller_effect(seed: SeedInfo) -> bool:
	for effect in _get_finish_seed_effects(seed):
		if (
			effect is SeedEffectOnFinishAcidSeedRecoverHp
			or effect is SeedEffectOnFinishAcidSeedSkipRestTime
		):
			return true
	return false


# 完了効果取得
func _get_finish_seed_effects(seed: SeedInfo) -> Array[SeedEffect]:
	# 効果一覧
	var effects: Array[SeedEffect] = []
	if seed == null or seed.get_sub_skill() == null:
		return effects
	effects.append_array(seed.get_sub_skill().get_effects())
	return effects


# 種回復量取得
func _get_seed_recovery_amount(
	effect: SeedEffectOnFinishAcidSeedRecoverHp,
	enemy: Enemy,
	max_hp: int
) -> int:
	# 回復率
	var recovery_rate := effect.hp_rate
	if effect.hp_rate_per_size != 0.0 and enemy != null:
		recovery_rate += effect.hp_rate_per_size * float(enemy.get_size())
	return ceili(float(max_hp) * recovery_rate)


# randomデバッグ種追加
func add_random_debug_seed() -> bool:
	# 花値
	var flower := debug_factory.create_random_debug_seed_flower()
	if flower == null:
		return false
	_flowers.append(flower)
	return true
