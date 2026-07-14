class_name EnemyEffectWorldActions
extends RefCounted


# 全体消化補正
static func add_global_acid_damage(
	source: Enemy,
	modifiers: EnemyAcidDamageModifiers,
	value: int,
	multiplier := 1.0
) -> void:
	if modifiers != null:
		modifiers.add_modifier(
			roundi(EnemyEffectValueCalculator.scale(source, float(value))),
			EnemyEffectValueCalculator.scale(source, multiplier)
		)


# 消化間隔秒追加
static func add_interval_seconds(source: Enemy, interval: DigestionInterval, value: int) -> void:
	if interval != null:
		interval.add_seconds(roundi(EnemyEffectValueCalculator.scale(source, float(value))))


# 消化間隔率追加
static func add_interval_rate(source: Enemy, interval: DigestionInterval, value: float) -> void:
	if interval != null:
		interval.add_rate(EnemyEffectValueCalculator.scale(source, value))


# 敵生成要求
static func spawn_enemy(
	effect: EnemyEffect,
	queue: EnemySpawnQueue,
	enemy_info: EnemyInfo,
	spawn_skill: EnemySkill,
	spawn_count: int,
	max_spawn_count: int,
	spawn_area: EnemyEffect.SpawnArea,
	hp_value: int,
	attack_value: int,
	inherit_skill := false
) -> void:
	if queue != null:
		queue.request(effect.source, effect, enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, hp_value, attack_value, inherit_skill)


# 時刻差分追加
static func add_time_delta(clock: BattleClock, seconds: int) -> void:
	if clock != null:
		clock.request_change(seconds)


# 効果継承
static func inherit_effects(inheritance: EnemyEffectInheritance, target: Enemy, owner: Enemy) -> void:
	if inheritance != null:
		inheritance.inherit(target, owner)
