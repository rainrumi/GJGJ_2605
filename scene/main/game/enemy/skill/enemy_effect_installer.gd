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
var _refresh_processor: EnemyEffectRefreshProcessor # 更新Signal元
var _installed_effects: Array[EnemyEffect] = [] # 接続済み効果
var _observed_data: Array[EnemyData] = [] # 監視中データ
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
	effect_stack: EnemyEffectStack,
	refresh_processor: EnemyEffectRefreshProcessor
) -> void:
	_player_health = player_health
	_spawn_queue = spawn_queue
	_battle_clock = battle_clock
	_digestion_interval = digestion_interval
	_acid_modifiers = acid_modifiers
	_digestion_state = digestion_state
	_inheritance = inheritance
	_effect_stack = effect_stack
	_refresh_processor = refresh_processor
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
	_enemy_ids = current_ids
	_stomach_id = current_stomach_id
	for enemy in enemies:
		_install_enemy(enemy, enemies, stomach)
	_is_dirty = false


# 配線解除
func reset() -> void:
	_disconnect_all(true)
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
		effect.bind_owner(owner.data, _effect_stack)
		_setup_trigger_dependencies(effect, owner, enemies)
		_inject_dependencies(effect, enemies, stomach)
		_installed_effects.append(effect)
		effect.bind()


# Trigger依存設定
func _setup_trigger_dependencies(
	effect: EnemyEffect,
	owner: Enemy,
	enemies: Array[Enemy]
) -> void:
	if effect is EnemyNodeEffect:
		(effect as EnemyNodeEffect).bind_source(owner)
	if effect is EnemyEffectOnDamage:
		(effect as EnemyEffectOnDamage).setup_damage_triggers(enemies)
	if effect is EnemyEffectOnDigested:
		(effect as EnemyEffectOnDigested).setup_digestion_triggers(enemies, _digestion_state)
	if effect is EnemyEffectOnTimeProgressed:
		(effect as EnemyEffectOnTimeProgressed).setup_time_trigger(_battle_clock, _refresh_processor)
	if effect is EnemyEffectOnRefresh:
		(effect as EnemyEffectOnRefresh).setup_refresh_trigger(_refresh_processor)
	if effect is EnemyEffectOnRefreshPreprocess:
		(effect as EnemyEffectOnRefreshPreprocess).setup_refresh_trigger(_refresh_processor)


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


# 任意ゲーム依存注入
func _call_setup(effect: EnemyEffect, method: StringName, arguments: Array) -> void:
	# TriggerとStackは型付き設定済み。具体Effect固有の任意依存だけに限定する。
	if effect.has_method(method):
		effect.callv(method, arguments)


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


# 継承変更受信
func _on_effects_changed() -> void:
	_is_dirty = true


# スキル変更受信
func _on_skills_changed() -> void:
	_is_dirty = true
