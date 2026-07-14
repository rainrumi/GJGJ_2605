class_name EnemyEffectSystem
extends RefCounted

var _digestion_interval: DigestionInterval # 消化間隔
var _acid_modifiers: EnemyAcidDamageModifiers # 全体消化補正
var _player_health: PlayerHealth # プレイヤーHP
var _spawn_queue: EnemySpawnQueue # 生成要求
var _battle_clock: BattleClock # 戦闘時刻
var _digestion_state: EnemyDigestionState # 消化状態
var _inheritance: EnemyEffectInheritance # 継承効果
var _effect_stack: EnemyEffectStack # 効果スタック
var _installer: EnemyEffectInstaller # 効果配線
var _known_enemies: Dictionary = {} # 戦闘参加敵


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
	installer: EnemyEffectInstaller
) -> void:
	_player_health = player_health
	_spawn_queue = spawn_queue
	_battle_clock = battle_clock
	_digestion_interval = digestion_interval
	_acid_modifiers = acid_modifiers
	_digestion_state = digestion_state
	_inheritance = inheritance
	_effect_stack = effect_stack
	_installer = installer
	_installer.setup(
		_player_health,
		_spawn_queue,
		_battle_clock,
		_digestion_interval,
		_acid_modifiers,
		_digestion_state,
		_inheritance,
		_effect_stack
	)


# 状態初期化
func reset() -> void:
	_installer.reset()
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_known_enemies.clear()
	_player_health.clear()
	_spawn_queue.clear()
	_battle_clock.reset()
	_digestion_interval.reset()
	_acid_modifiers.reset()
	_digestion_state.reset()
	_inheritance.reset()
	_effect_stack.clear()


# 継続効果更新
func refresh(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_register_enemies(enemies)
	_installer.sync(enemies, stomach)
	_clear_refresh_modifiers()
	var activation := RefreshActivationData.new() # 更新発動値
	if stomach != null:
		stomach.notify_refresh_preparing(activation)
	_effect_stack.execute()
	if stomach != null:
		stomach.notify_refreshed(activation)
	_effect_stack.execute()
	_apply_max_hp_modifiers(enemies)




# プレイヤーダメージ消費
func consume_player_damage() -> Array[int]:
	return _player_health.consume_damage()


# 生成要求消費
func consume_spawns() -> Array[BattleSpawnEnemyData]:
	return _spawn_queue.consume()


# 時刻差分消費
func consume_time_delta_seconds() -> int:
	return _battle_clock.consume_change()




# 効果配線準備
func prepare(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	_register_enemies(enemies)
	_installer.sync(enemies, stomach)


# 効果要求実行
func execute() -> void:
	_effect_stack.execute()




# 敵一覧登録
func _register_enemies(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy != null:
			_known_enemies[enemy] = true


# 一時補正初期化
func _clear_refresh_modifiers() -> void:
	for enemy in _known_enemies.keys():
		if enemy != null and is_instance_valid(enemy):
			enemy.data.defense_status.reset_refresh_modifiers()
			enemy.data.attack.reset_modifiers()
			enemy.data.hp.reset_modifiers()
	_digestion_interval.reset()
	_acid_modifiers.reset()


# 最大HP補正適用
func _apply_max_hp_modifiers(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy != null and not enemy.is_Acided():
			enemy.data.hp.apply_modifiers()
