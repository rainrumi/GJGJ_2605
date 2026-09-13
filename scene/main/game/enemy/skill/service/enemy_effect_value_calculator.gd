class_name EnemyEffectValueCalculator
extends RefCounted

static var _adjustment_scopes: Array[Dictionary] = []


static func begin_adjustment_scope(data: EnemyData, amount_configured: bool, probability_configured: bool) -> void:
	_adjustment_scopes.append({
		"data": data,
		"amount": amount_configured,
		"probability": probability_configured,
	})


static func end_adjustment_scope() -> void:
	assert(not _adjustment_scopes.is_empty(), "効果補正スコープがありません")
	_adjustment_scopes.pop_back()


static func _uses_selected_field(data: EnemyData, probability: bool) -> bool:
	for index in range(_adjustment_scopes.size() - 1, -1, -1):
		var scope := _adjustment_scopes[index]
		if scope.data == data:
			return scope.probability if probability else scope.amount
	return false


# 確率判定
static func roll(source: Enemy, chance: float, invert := false) -> bool:
	var selected := source != null and _uses_selected_field(source.data, true)
	var delta := source.data.defense_status.chance_delta if source != null else 0.0 # 確率差分
	var multiplier := source.data.defense_status.chance_multiplier if source != null and not selected else 1.0 # 確率倍率
	var adjusted := clampf((chance + delta) * multiplier, 0.0, 1.0) # 補正確率
	if invert:
		adjusted = 1.0 - adjusted
	return randf() <= adjusted


# 効果値補正
static func scale(source: Enemy, value: float) -> float:
	var multiplier := source.data.defense_status.effect_multiplier if source != null and not _uses_selected_field(source.data, false) else 1.0 # 効果倍率
	return value * multiplier
