class_name EnemyEffectInstaller
extends RefCounted

var _player_health: PlayerHealth # プレイヤーHP
var _spawn_queue: EnemySpawnQueue # 敵生成要求
var _battle_clock: BattleClock # 戦闘時刻
var _digestion_interval: DigestionInterval # 消化間隔
var _acid_modifiers: EnemyAcidDamageModifiers # 全体消化補正
var _digestion_state: EnemyDigestionState # 消化状態
var _inheritance: EnemyEffectInheritance # 継承効果
var _effect_stack: EnemyEffectStack # 効果スタック
var _installed_effects: Array[EnemyEffect] = [] # 接続済み効果
var _observed_data: Array[EnemyData] = [] # 監視中データ
var _connections: Dictionary = {} # 効果別接続
var _enemy_ids: Array[int] = [] # 接続対象ID
var _stomach_id := 0 # 胃袋ID
var _is_dirty := true # 再接続要否
var _current_enemies: Array[Enemy] = [] # 現在の敵一覧
var _current_stomach: StomachBoard # 現在の胃袋


# 依存関係設定
func setup(
	player_health: PlayerHealth,
	spawn_queue: EnemySpawnQueue,
	battle_clock: BattleClock,
	digestion_interval: DigestionInterval,
	acid_modifiers: EnemyAcidDamageModifiers,
	digestion_state: EnemyDigestionState,
	inheritance: EnemyEffectInheritance,
	effect_stack: EnemyEffectStack
) -> void:
	_player_health = player_health
	_spawn_queue = spawn_queue
	_battle_clock = battle_clock
	_digestion_interval = digestion_interval
	_acid_modifiers = acid_modifiers
	_digestion_state = digestion_state
	_inheritance = inheritance
	_effect_stack = effect_stack
	if not _inheritance.effects_changed.is_connected(_on_effects_changed):
		_inheritance.effects_changed.connect(_on_effects_changed)


# 効果配線同期
func sync(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	var current_ids: Array[int] = [] # 現在の敵ID
	for enemy in enemies:
		if enemy != null and is_instance_valid(enemy):
			current_ids.append(enemy.get_instance_id())
	var current_stomach_id := stomach.get_instance_id() if stomach != null else 0 # 現在の胃袋ID
	if not _is_dirty and current_ids == _enemy_ids and current_stomach_id == _stomach_id:
		return
	_disconnect_all(false)
	_current_enemies.assign(enemies)
	_current_stomach = stomach
	_enemy_ids = current_ids
	_stomach_id = current_stomach_id
	for enemy in enemies:
		_install_enemy(enemy, enemies, stomach)
	_is_dirty = false


# 配線解除
func reset() -> void:
	_disconnect_all(true)
	_current_enemies.clear()
	_current_stomach = null
	_enemy_ids.clear()
	_stomach_id = 0
	_is_dirty = true


# 敵効果接続
func _install_enemy(owner: Enemy, enemies: Array[Enemy], stomach: StomachBoard) -> void:
	if owner == null or not is_instance_valid(owner):
		return
	if not owner.data.skills_changed.is_connected(_on_skills_changed):
		owner.data.skills_changed.connect(_on_skills_changed)
	_observed_data.append(owner.data)
	var effects := owner.get_enemy_effects() # 固有効果
	effects.append_array(_inheritance.get_effects(owner))
	effects.sort_custom(func(a: EnemyEffect, b: EnemyEffect) -> bool: return a.priority < b.priority)
	for effect in effects:
		if effect == null:
			continue
		effect.bind_owner(owner, _effect_stack)
		effect.bind_dependencies(self)
		_installed_effects.append(effect)
		effect.bind_triggers(self)


# 敵一覧取得
func get_enemies() -> Array[Enemy]:
	return _current_enemies.duplicate()


# 胃袋取得
func get_stomach() -> StomachBoard:
	return _current_stomach


# プレイヤーHP取得
func get_player_health() -> PlayerHealth:
	return _player_health


# 敵生成要求取得
func get_spawn_queue() -> EnemySpawnQueue:
	return _spawn_queue


# 戦闘時刻取得
func get_battle_clock() -> BattleClock:
	return _battle_clock


# 消化間隔取得
func get_digestion_interval() -> DigestionInterval:
	return _digestion_interval


# 消化補正取得
func get_acid_modifiers() -> EnemyAcidDamageModifiers:
	return _acid_modifiers


# 消化状態取得
func get_digestion_state() -> EnemyDigestionState:
	return _digestion_state


# 効果継承取得
func get_inheritance() -> EnemyEffectInheritance:
	return _inheritance


# 更新Signal接続
func connect_refresh(effect: EnemyEffect) -> void:
	if _current_stomach != null:
		_connect_signal(effect, _current_stomach.refreshed)


# 更新前Signal接続
func connect_refresh_preprocess(effect: EnemyEffect) -> void:
	if _current_stomach != null:
		_connect_signal(effect, _current_stomach.refresh_preparing)


# 通常攻撃更新接続
func connect_default_attack_refresh(effect: EnemyEffect, disabled: bool) -> void:
	if _current_stomach == null:
		return
	var refresh_effect := EnemyEffectRefreshDefaultAttack.new() # 更新専用効果
	refresh_effect.priority = effect.priority
	refresh_effect.disabled = disabled
	refresh_effect.bind_owner(effect.source, _effect_stack)
	_installed_effects.append(refresh_effect)
	_connect_signal(refresh_effect, _current_stomach.refreshed)


# 時間Signal接続
func connect_progress_time(effect: EnemyEffect) -> void:
	_connect_signal(effect, _battle_clock.progress_resolved)


# 全消化Signal接続
func connect_any_digested(effect: EnemyEffect) -> void:
	_connect_signal(effect, _digestion_state.digestion_batch_resolved)


# 消化前Signal接続
func connect_before_acid_damage(effect: EnemyEffect) -> void:
	_connect_enemy_signal(effect, "acid_damage_preparing")


# 消化後Signal接続
func connect_after_acid_damage(effect: EnemyEffect) -> void:
	_connect_enemy_signal(effect, "acid_damage_applied")


# 隣接被弾Signal接続
func connect_adjacent_acid_damage(effect: EnemyEffect) -> void:
	_connect_enemy_signal(effect, "adjacent_acid_damage_applied")


# 消化Signal接続
func connect_digested(effect: EnemyEffect) -> void:
	for enemy in _current_enemies:
		if enemy != null and is_instance_valid(enemy):
			_connect_signal(effect, enemy.data.stomach_status.digestion_resolved)


# 隣接消化Signal接続
func connect_adjacent_digested(effect: EnemyEffect) -> void:
	for enemy in _current_enemies:
		if enemy != null and is_instance_valid(enemy):
			_connect_signal(effect, enemy.data.stomach_status.adjacent_digestion_resolved)


# HP Signal接続
func _connect_enemy_signal(effect: EnemyEffect, signal_name: StringName) -> void:
	for enemy in _current_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		_connect_signal(effect, Signal(enemy.data.hp, signal_name))


# 単一信号接続
func _connect_signal(effect: EnemyEffect, source_signal: Signal) -> void:
	var callback := effect.queue_activation # 発動要求
	if not source_signal.is_connected(callback):
		source_signal.connect(callback)
	if not _connections.has(effect):
		_connections[effect] = []
	_connections[effect].append(source_signal)


# 全配線解除
func _disconnect_all(clear_state: bool) -> void:
	for enemy_data in _observed_data:
		if enemy_data != null and enemy_data.skills_changed.is_connected(_on_skills_changed):
			enemy_data.skills_changed.disconnect(_on_skills_changed)
	_observed_data.clear()
	for effect in _installed_effects:
		if effect == null:
			continue
		var callback := effect.queue_activation # 発動要求
		for source_signal in _connections.get(effect, []):
			if not source_signal.is_null() and source_signal.is_connected(callback):
				source_signal.disconnect(callback)
		effect.unbind(clear_state)
	_installed_effects.clear()
	_connections.clear()


# 継承変更受信
func _on_effects_changed() -> void:
	_is_dirty = true


# スキル変更受信
func _on_skills_changed() -> void:
	_is_dirty = true
