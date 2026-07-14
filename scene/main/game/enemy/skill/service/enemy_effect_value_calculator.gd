class_name EnemyEffectValueCalculator
extends RefCounted


# 確率判定
static func roll(source: Enemy, chance: float, invert := false) -> bool:
	var delta := source.data.defense_status.chance_delta if source != null else 0.0 # 確率差分
	var adjusted := clampf(chance + delta, 0.0, 1.0) # 補正確率
	if invert:
		adjusted = 1.0 - adjusted
	return randf() <= adjusted


# 効果値補正
static func scale(source: Enemy, value: float) -> float:
	var multiplier := source.data.defense_status.effect_multiplier if source != null else 1.0 # 効果倍率
	return value * multiplier
