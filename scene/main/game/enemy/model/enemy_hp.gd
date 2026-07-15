class_name EnemyHp
extends RefCounted

signal changed(current_value: int, maximum_value: int)
signal damaged(amount: int)
signal healed(amount: int)
signal depleted
signal damage_requested(request: EnemyDamageRequest)
signal damage_resolved(amount: int, overkill: int)

var maximum := 1 # 最大HP
var current := 1 # 現在HP
var modifier_delta := 0 # 一時最大HP差分
var modifier_multiplier := 1.0 # 一時最大HP倍率
var _applied_modifier_delta := 0 # 適用済み差分
var _follow_current_delta := 0 # 現在HP追従差分


# HP初期化
func setup(maximum_value: int, current_value: int = -1) -> void:
	maximum = maxi(1, maximum_value)
	current = maximum if current_value < 0 else clampi(current_value, 0, maximum)
	modifier_delta = 0
	modifier_multiplier = 1.0
	_applied_modifier_delta = 0
	_follow_current_delta = 0
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


# ダメージ要求作成
func request_damage(amount: int, target: EnemyData) -> EnemyDamageRequest:
	var request := EnemyDamageRequest.new(amount, target) # 可変要求
	damage_requested.emit(request)
	return request


# ダメージ適用
func take_damage(amount: int) -> bool:
	var requested := maxi(0, amount) # 要求量
	var before := current # 適用前HP
	var applied := maxi(0, mini(current, amount)) # 適用量
	current = maxi(0, current - requested)
	if applied > 0:
		damaged.emit(applied)
	changed.emit(current, maximum)
	damage_resolved.emit(requested, maxi(0, requested - before))
	if current == 0:
		depleted.emit()
		return true
	return false


# HP回復
func heal(amount: int) -> void:
	var applied := mini(maximum - current, maxi(0, amount)) # 実回復量
	current += applied
	if applied > 0:
		healed.emit(applied)
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


# 最大HP差分追加
func add_modifier_delta(value: int, follow_current: bool) -> void:
	modifier_delta += value
	if follow_current:
		_follow_current_delta += value


# 最大HP倍率追加
func multiply_modifier(value: float) -> void:
	modifier_multiplier *= value


# 最大HP補正適用
func apply_modifiers() -> void:
	var base_maximum := maxi(1, maximum - _applied_modifier_delta) # 基準最大HP
	var next_maximum := maxi(1, roundi(float(base_maximum + modifier_delta) * modifier_multiplier)) # 補正最大HP
	var next_delta := next_maximum - base_maximum # 新適用差分
	var current_delta := _follow_current_delta - _applied_modifier_delta # 現在HP差分
	set_values(next_maximum, current + current_delta)
	_applied_modifier_delta = next_delta
	_follow_current_delta = 0


# 一時補正初期化
func reset_modifiers() -> void:
	modifier_delta = 0
	modifier_multiplier = 1.0
