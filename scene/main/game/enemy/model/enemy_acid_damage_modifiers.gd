class_name EnemyAcidDamageModifiers
extends RefCounted

signal changed

var delta := 0 # 全体消化差分
var multiplier := 1.0 # 全体消化倍率


# 全体補正初期化
func reset() -> void:
	delta = 0
	multiplier = 1.0
	changed.emit()


# 全体補正追加
func add_modifier(value_delta: int, value_multiplier: float) -> void:
	delta += value_delta
	multiplier *= value_multiplier
	changed.emit()


# 消化値解決
func resolve(enemy: Enemy, base_value: int) -> int:
	if enemy == null:
		return maxi(0, base_value)
	if enemy.data.defense_status.consume_acid_guard():
		return 0
	var defense := enemy.data.defense_status # 防御状態
	var value := base_value + delta + defense.acid_damage_delta + defense.permanent_acid_delta # 補正前値
	value = roundi(float(value) * multiplier * defense.acid_damage_multiplier * defense.permanent_acid_multiplier)
	return maxi(0, value)
