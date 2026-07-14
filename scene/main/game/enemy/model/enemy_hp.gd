class_name EnemyHp
extends RefCounted

signal changed(current_value: int, maximum_value: int)
signal damaged(amount: int)
signal depleted

var maximum := 1 # 最大HP
var current := 1 # 現在HP


# HP初期化
func setup(maximum_value: int, current_value: int = -1) -> void:
	maximum = maxi(1, maximum_value)
	current = maximum if current_value < 0 else clampi(current_value, 0, maximum)
	changed.emit(current, maximum)


# HP設定
func set_values(maximum_value: int, current_value: int) -> void:
	maximum = maxi(1, maximum_value)
	current = clampi(current_value, 0, maximum)
	changed.emit(current, maximum)


# 最大HP設定
func set_maximum(value: int) -> void:
	set_values(value, current)


# 現在HP設定
func set_current(value: int) -> void:
	current = clampi(value, 0, maximum)
	changed.emit(current, maximum)
	if current == 0:
		depleted.emit()


# ダメージ適用
func take_damage(amount: int) -> bool:
	var applied := maxi(0, mini(current, amount)) # 適用量
	current = maxi(0, current - maxi(0, amount))
	if applied > 0:
		damaged.emit(applied)
	changed.emit(current, maximum)
	if current == 0:
		depleted.emit()
		return true
	return false


# HP回復
func heal(amount: int) -> void:
	current = mini(maximum, current + maxi(0, amount))
	changed.emit(current, maximum)


# 上限外回復
func heal_over_max(amount: int) -> void:
	current = maxi(0, current + amount)
	changed.emit(current, maximum)


# 最大HP追加
func add_maximum(amount: int, also_heal := true) -> void:
	maximum = maxi(1, maximum + amount)
	if also_heal:
		current += amount
	current = maxi(0, current)
	changed.emit(current, maximum)
