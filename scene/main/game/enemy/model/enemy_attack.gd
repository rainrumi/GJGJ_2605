class_name EnemyAttack
extends RefCounted

signal changed(display_value: int)

var value := 0 # 攻撃値
var base_value := 0 # 基準攻撃値
var multiplier := 1.0 # 攻撃倍率
var display_override := -1 # 表示固定値
var modifier_delta := 0 # 一時攻撃差分
var modifier_multiplier := 1.0 # 一時攻撃倍率
var modifier_override := -1 # 一時攻撃固定値


# 攻撃初期化
func setup(attack_value: int) -> void:
	value = maxi(0, attack_value)
	base_value = value
	multiplier = 1.0
	display_override = -1
	reset_modifiers()
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


# 補正攻撃取得
func get_modified_value(base_attack: int) -> int:
	if modifier_override >= 0:
		return modifier_override
	return maxi(0, roundi(float(base_attack + modifier_delta) * modifier_multiplier))


# 一時差分追加
func add_modifier_delta(value_delta: int) -> void:
	modifier_delta += value_delta


# 一時倍率追加
func multiply_modifier(value_multiplier: float) -> void:
	modifier_multiplier *= value_multiplier


# 一時固定値設定
func set_modifier_override(attack_value: int) -> void:
	modifier_override = maxi(0, attack_value)


# 一時補正初期化
func reset_modifiers() -> void:
	modifier_delta = 0
	modifier_multiplier = 1.0
	modifier_override = -1
