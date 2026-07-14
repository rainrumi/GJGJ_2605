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
var _connections: Dictionary = {} # 効果別接続
var _enemy_ids: Array[int] = [] # 接続対象ID
var _stomach_id := 0 # 胃袋ID
var _is_dirty := true # 再接続要否


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
	_disconnect_all()
	_enemy_ids = current_ids
	_stomach_id = current_stomach_id
	for enemy in enemies:
		_install_enemy(enemy, enemies, stomach)
	_is_dirty = false


# 配線解除
func reset() -> void:
	_disconnect_all()
	_enemy_ids.clear()
	_stomach_id = 0
	_is_dirty = true


# 敵効果接続
func _install_enemy(owner: Enemy, enemies: Array[Enemy], stomach: StomachBoard) -> void:
	if owner == null or not is_instance_valid(owner):
		return
	var effects := owner.get_enemy_effects() # 固有効果
	effects.append_array(_inheritance.get_effects(owner))
	effects.sort_custom(func(a: EnemyEffect, b: EnemyEffect) -> bool: return a.priority < b.priority)
	for effect in effects:
		if effect == null:
			continue
		effect.bind_dependencies(
			owner,
			enemies,
			stomach,
			_player_health,
			_spawn_queue,
			_battle_clock,
			_digestion_interval,
			_acid_modifiers,
			_digestion_state,
			_inheritance,
			_effect_stack
		)
		_installed_effects.append(effect)
		_connect_effect(effect, enemies, stomach)


# 発動元接続
func _connect_effect(effect: EnemyEffect, enemies: Array[Enemy], stomach: StomachBoard) -> void:
	var mask := effect.get_activation_mask() # 発動種別
	if mask & EnemyEffect.ACTIVATION_BATTLE_START:
		_connect_signal(effect, _battle_clock.battle_effect_requested)
	if mask & EnemyEffect.ACTIVATION_REFRESH and stomach != null:
		var preprocess := effect is EnemyEffectOnAdjacentObjectScaleEffect or effect is EnemyEffectOnAdjacentObjectChangeChance # 前処理効果
		_connect_signal(effect, stomach.effect_refresh_preprocess_requested if preprocess else stomach.effect_refresh_requested)
	if mask & EnemyEffect.ACTIVATION_TURN_START:
		_connect_signal(effect, _battle_clock.turn_effect_requested)
	if mask & EnemyEffect.ACTIVATION_PROGRESS_TIME:
		_connect_signal(effect, _battle_clock.progress_effect_requested)
	if mask & EnemyEffect.ACTIVATION_ANY_DIGESTED:
		_connect_signal(effect, _digestion_state.any_digested_effect_requested)
	for enemy in enemies:
		_connect_enemy_signals(effect, mask, enemy)


# 敵別信号接続
func _connect_enemy_signals(effect: EnemyEffect, mask: int, enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if mask & EnemyEffect.ACTIVATION_BEFORE_ACID_DAMAGE:
		_connect_signal(effect, enemy.data.hp.before_acid_damage_requested)
	if mask & EnemyEffect.ACTIVATION_AFTER_ACID_DAMAGE:
		_connect_signal(effect, enemy.data.hp.after_acid_damage_requested)
	if mask & EnemyEffect.ACTIVATION_ADJACENT_ACID_DAMAGE:
		_connect_signal(effect, enemy.data.hp.adjacent_acid_damage_requested)
	if mask & EnemyEffect.ACTIVATION_DIGESTED:
		_connect_signal(effect, enemy.data.stomach_status.digested_effect_requested)
	if mask & EnemyEffect.ACTIVATION_ADJACENT_DIGESTED:
		_connect_signal(effect, enemy.data.stomach_status.adjacent_digested_effect_requested)


# 単一信号接続
func _connect_signal(effect: EnemyEffect, source_signal: Signal) -> void:
	var callback := effect.queue_activation # 発動要求
	if not source_signal.is_connected(callback):
		source_signal.connect(callback)
	if not _connections.has(effect):
		_connections[effect] = []
	_connections[effect].append(source_signal)


# 全配線解除
func _disconnect_all() -> void:
	for effect in _installed_effects:
		if effect == null:
			continue
		var callback := effect.queue_activation # 発動要求
		for source_signal in _connections.get(effect, []):
			if source_signal.is_connected(callback):
				source_signal.disconnect(callback)
		effect.unbind()
	_installed_effects.clear()
	_connections.clear()


# 継承変更受信
func _on_effects_changed() -> void:
	_is_dirty = true
