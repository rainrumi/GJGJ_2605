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
var _refresh_processor := EnemyEffectRefreshProcessor.new() # 補正更新


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
		_effect_stack,
		_refresh_processor
	)


# 状態初期化
func reset() -> void:
	_installer.reset()
	_refresh_processor.reset_all()
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
	_refresh_processor.clear_refresh_modifiers()
	_reset_global_modifiers()
	_refresh_processor.request_preprocess()
	_effect_stack.execute()
	_refresh_processor.request_refresh()
	_effect_stack.execute()
	_refresh_processor.apply_max_hp_modifiers(enemies)




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
	_refresh_processor.register(enemies)


# 全体補正初期化
func _reset_global_modifiers() -> void:
	_digestion_interval.reset()
	_acid_modifiers.reset()
