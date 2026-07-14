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
var _enemy_ids: Array[int] = [] # 接続対象ID
var _stomach_id := 0 # 胃袋ID
var _is_dirty := true # 再接続要否
var _current_enemies: Array[Enemy] = [] # 現在の敵一覧
var _current_stomach: StomachBoard # 現在の胃袋
var _progress_time_effects: Array[EnemyEffect] = [] # 時間効果
var _any_digested_effects: Array[EnemyEffect] = [] # 消化群効果
var _before_acid_effects: Array[EnemyEffect] = [] # 消化前効果
var _after_acid_effects: Array[EnemyEffect] = [] # 消化後効果
var _adjacent_acid_effects: Array[EnemyEffect] = [] # 隣接被弾効果
var _digested_effects: Array[EnemyEffect] = [] # 消化効果
var _adjacent_digested_effects: Array[EnemyEffect] = [] # 隣接消化効果
var _refresh_effects: Array[EnemyEffect] = [] # 更新効果
var _refresh_preprocess_effects: Array[EnemyEffect] = [] # 更新前効果


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
		_inject_dependencies(effect, enemies, stomach)
		_installed_effects.append(effect)
		effect.bind_triggers(self)


# 依存関係注入
func _inject_dependencies(
	effect: EnemyEffect,
	enemies: Array[Enemy],
	stomach: StomachBoard
) -> void:
	_call_setup(effect, &"setup_enemies", [enemies.duplicate()])
	_call_setup(effect, &"setup_stomach", [stomach])
	_call_setup(effect, &"setup_player_health", [_player_health])
	_call_setup(effect, &"setup_spawn_queue", [_spawn_queue])
	_call_setup(effect, &"setup_battle_clock", [_battle_clock])
	_call_setup(effect, &"setup_digestion_interval", [_digestion_interval])
	_call_setup(effect, &"setup_acid_modifiers", [_acid_modifiers])
	_call_setup(effect, &"setup_digestion_state", [_digestion_state])
	_call_setup(effect, &"setup_inheritance", [_inheritance])


# 個別依存注入
func _call_setup(effect: EnemyEffect, method: StringName, arguments: Array) -> void:
	if effect.has_method(method):
		effect.callv(method, arguments)


# 更新Signal接続
func connect_refresh(effect: EnemyEffect) -> void:
	_append_trigger(_refresh_effects, effect)


# 更新前Signal接続
func connect_refresh_preprocess(effect: EnemyEffect) -> void:
	_append_trigger(_refresh_preprocess_effects, effect)


# 通常攻撃更新接続
func connect_default_attack_refresh(effect: EnemyEffect, disabled: bool) -> void:
	if _current_stomach == null:
		return
	var refresh_effect := EnemyEffectRefreshDefaultAttack.new() # 更新専用効果
	refresh_effect.priority = effect.priority
	refresh_effect.disabled = disabled
	refresh_effect.bind_owner(effect.source, _effect_stack)
	_installed_effects.append(refresh_effect)
	_append_trigger(_refresh_effects, refresh_effect)


# 時間Signal接続
func connect_progress_time(effect: EnemyEffect) -> void:
	_append_trigger(_progress_time_effects, effect)


# 全消化Signal接続
func connect_any_digested(effect: EnemyEffect) -> void:
	_append_trigger(_any_digested_effects, effect)


# 消化前Signal接続
func connect_before_acid_damage(effect: EnemyEffect) -> void:
	_append_trigger(_before_acid_effects, effect)


# 消化後Signal接続
func connect_after_acid_damage(effect: EnemyEffect) -> void:
	_append_trigger(_after_acid_effects, effect)


# 隣接被弾Signal接続
func connect_adjacent_acid_damage(effect: EnemyEffect) -> void:
	_append_trigger(_adjacent_acid_effects, effect)


# 消化Signal接続
func connect_digested(effect: EnemyEffect) -> void:
	_append_trigger(_digested_effects, effect)


# 隣接消化Signal接続
func connect_adjacent_digested(effect: EnemyEffect) -> void:
	_append_trigger(_adjacent_digested_effects, effect)


# 発動先登録
func _append_trigger(targets: Array[EnemyEffect], effect: EnemyEffect) -> void:
	if not targets.has(effect):
		targets.append(effect)


# 時間効果要求
func queue_progress_time(data: TimeActivationData) -> void:
	_queue_effects(_progress_time_effects, data)


# 更新前効果要求
func queue_refresh_preprocess(data: RefreshActivationData) -> void:
	_queue_effects(_refresh_preprocess_effects, data)


# 更新効果要求
func queue_refresh(data: RefreshActivationData) -> void:
	_queue_effects(_refresh_effects, data)


# 消化群効果要求
func queue_any_digested(data: DigestionActivationData) -> void:
	_queue_effects(_any_digested_effects, data)


# 消化前効果要求
func queue_before_acid_damage(data: DamageActivationData) -> void:
	_queue_effects(_before_acid_effects, data)


# 消化後効果要求
func queue_after_acid_damage(data: DamageActivationData) -> void:
	_queue_effects(_after_acid_effects, data)


# 隣接被弾効果要求
func queue_adjacent_acid_damage(data: DamageActivationData) -> void:
	_queue_effects(_adjacent_acid_effects, data)


# 消化効果要求
func queue_digested(data: DigestionActivationData) -> void:
	_queue_effects(_digested_effects, data)


# 隣接消化効果要求
func queue_adjacent_digested(data: DigestionActivationData) -> void:
	_queue_effects(_adjacent_digested_effects, data)


# 効果要求追加
func _queue_effects(effects: Array[EnemyEffect], data: EnemyEffectActivationData) -> void:
	for effect in effects:
		if effect != null:
			effect.queue_activation(data)


# 全配線解除
func _disconnect_all(clear_state: bool) -> void:
	for enemy_data in _observed_data:
		if enemy_data != null and enemy_data.skills_changed.is_connected(_on_skills_changed):
			enemy_data.skills_changed.disconnect(_on_skills_changed)
	_observed_data.clear()
	for effect in _installed_effects:
		if effect == null:
			continue
		effect.unbind(clear_state)
	_installed_effects.clear()
	_progress_time_effects.clear()
	_any_digested_effects.clear()
	_before_acid_effects.clear()
	_after_acid_effects.clear()
	_adjacent_acid_effects.clear()
	_digested_effects.clear()
	_adjacent_digested_effects.clear()
	_refresh_effects.clear()
	_refresh_preprocess_effects.clear()


# 継承変更受信
func _on_effects_changed() -> void:
	_is_dirty = true


# スキル変更受信
func _on_skills_changed() -> void:
	_is_dirty = true
