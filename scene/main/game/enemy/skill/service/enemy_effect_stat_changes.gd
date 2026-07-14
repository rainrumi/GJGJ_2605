class_name EnemyEffectStatChanges
extends RefCounted


# 攻撃差分追加
static func add_attack_delta(source: Enemy, enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.attack.add_modifier_delta(roundi(EnemyEffectValueCalculator.scale(source, float(value))))


# 攻撃値固定
static func set_attack(source: Enemy, enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.attack.set_modifier_override(roundi(EnemyEffectValueCalculator.scale(source, float(value))))


# 攻撃倍率追加
static func multiply_attack(source: Enemy, enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.attack.multiply_modifier(EnemyEffectValueCalculator.scale(source, value))


# HP変更
static func change_hp(source: Enemy, enemy: Enemy, value: int) -> void:
	if enemy == null or value == 0:
		return
	var scaled := roundi(EnemyEffectValueCalculator.scale(source, float(value))) # 補正値
	if scaled > 0:
		enemy.heal(scaled)
	else:
		enemy.take_acid_damage(-scaled)


# 最大HP差分追加
static func add_max_hp_delta(source: Enemy, enemy: Enemy, value: int, follow_hp := false) -> void:
	if enemy != null:
		enemy.data.hp.add_modifier_delta(roundi(EnemyEffectValueCalculator.scale(source, float(value))), follow_hp)


# HP倍率追加
static func multiply_hp(source: Enemy, enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.hp.multiply_modifier(EnemyEffectValueCalculator.scale(source, value))


# 消化差分追加
static func add_acid_damage_delta(source: Enemy, enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_acid_damage_delta(roundi(EnemyEffectValueCalculator.scale(source, float(value))))


# 消化倍率追加
static func multiply_acid_damage(source: Enemy, enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.defense_status.multiply_acid_damage(EnemyEffectValueCalculator.scale(source, value))


# 効果倍率追加
static func multiply_effect(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.defense_status.multiply_effect(value)


# 確率差分追加
static func add_chance_delta(enemy: Enemy, value: float) -> void:
	if enemy != null:
		enemy.data.defense_status.add_chance_delta(value)


# 攻撃無効追加
static func add_attack_guards(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_attack_guards(value)


# 消化無効追加
static func add_acid_guards(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_acid_guards(value)


# 追加攻撃追加
static func add_extra_attacks(enemy: Enemy, value: int) -> void:
	if enemy != null:
		enemy.data.defense_status.add_extra_attacks(value)


# 永続消化補正
static func add_permanent_acid_modifier(enemy: Enemy, delta: int, multiplier: float) -> void:
	if enemy != null:
		enemy.data.defense_status.add_permanent_acid_modifier(delta, multiplier)


# 通常攻撃設定
static func set_default_attack_disabled(enemy: Enemy, value: bool) -> void:
	if enemy != null and value:
		enemy.data.defense_status.disable_default_attack(true)
