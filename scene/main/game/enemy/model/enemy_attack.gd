class_name EnemyAttack
extends RefCounted

signal changed(display_value: int)

var value := 0 # 攻撃値
var base_value := 0 # 基準攻撃値
var multiplier := 1.0 # 攻撃倍率
var display_override := -1 # 表示固定値


# 攻撃初期化
func setup(attack_value: int) -> void:
	value = maxi(0, attack_value)
	base_value = value
	multiplier = 1.0
	display_override = -1
	changed.emit(get_display_value())


# 攻撃値取得
func get_value() -> int:
	return maxi(0, roundi(float(value) * multiplier))


# 表示値取得
func get_display_value() -> int:
	return display_override if display_override >= 0 else get_value()


# 攻撃値設定
func set_value(attack_value: int, update_base := true) -> void:
	value = maxi(0, attack_value)
	if update_base:
		base_value = value
	changed.emit(get_display_value())


# 攻撃値追加
func add_value(amount: int) -> void:
	value = maxi(0, value + amount)
	changed.emit(get_display_value())


# 攻撃倍率設定
func set_multiplier(value_multiplier: float) -> void:
	multiplier = clampf(value_multiplier, 0.0, 3.0)
	changed.emit(get_display_value())


# 表示値設定
func set_display_override(display_value: int) -> void:
	display_override = display_value
	changed.emit(get_display_value())
