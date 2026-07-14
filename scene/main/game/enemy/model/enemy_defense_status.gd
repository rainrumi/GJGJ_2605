class_name EnemyDefenseStatus
extends RefCounted

signal changed

var attack_guard_count := 0 # 攻撃無効回数
var acid_guard_count := 0 # 消化無効回数
var default_attack_disabled := false # 通常攻撃停止
var acid_damage_delta := 0 # 消化差分
var acid_damage_multiplier := 1.0 # 消化倍率
var permanent_acid_delta := 0 # 永続消化差分
var permanent_acid_multiplier := 1.0 # 永続消化倍率
var taken_acid_multiplier := 1.0 # 被消化倍率
var global_acid_multiplier := 1.0 # 全体消化倍率
var effect_multiplier := 1.0 # 効果倍率
var chance_delta := 0.0 # 確率差分
var extra_attack_count := 0 # 追加攻撃回数


# 防御状態初期化
func reset() -> void:
	attack_guard_count = 0
	acid_guard_count = 0
	permanent_acid_delta = 0
	permanent_acid_multiplier = 1.0
	taken_acid_multiplier = 1.0
	global_acid_multiplier = 1.0
	extra_attack_count = 0
	reset_refresh_modifiers()
	changed.emit()


# 一時補正初期化
func reset_refresh_modifiers() -> void:
	default_attack_disabled = false
	acid_damage_delta = 0
	acid_damage_multiplier = 1.0
	effect_multiplier = 1.0
	chance_delta = 0.0
	changed.emit()


# 攻撃無効追加
func add_attack_guards(value: int) -> void:
	attack_guard_count += maxi(0, value)
	changed.emit()


# 攻撃無効消費
func consume_attack_guard() -> bool:
	if attack_guard_count <= 0:
		return false
	attack_guard_count -= 1
	changed.emit()
	return true


# 消化無効追加
func add_acid_guards(value: int) -> void:
	acid_guard_count += maxi(0, value)
	changed.emit()


# 消化無効消費
func consume_acid_guard() -> bool:
	if acid_guard_count <= 0:
		return false
	acid_guard_count -= 1
	changed.emit()
	return true


# 通常攻撃設定
func disable_default_attack(value: bool) -> void:
	default_attack_disabled = value
	changed.emit()


# 消化差分追加
func add_acid_damage_delta(value: int) -> void:
	acid_damage_delta += value
	changed.emit()


# 消化倍率追加
func multiply_acid_damage(value: float) -> void:
	acid_damage_multiplier *= value
	changed.emit()


# 永続消化補正
func add_permanent_acid_modifier(delta: int, multiplier: float) -> void:
	permanent_acid_delta += delta
	permanent_acid_multiplier *= multiplier
	changed.emit()


# 被消化倍率設定
func set_taken_acid_multiplier(value: float) -> void:
	taken_acid_multiplier = maxf(0.0, value)
	changed.emit()


# 全体消化倍率設定
func set_global_acid_multiplier(value: float) -> void:
	global_acid_multiplier = maxf(0.0, value)
	changed.emit()


# 効果倍率追加
func multiply_effect(value: float) -> void:
	effect_multiplier *= value
	changed.emit()


# 確率差分追加
func add_chance_delta(value: float) -> void:
	chance_delta += value
	changed.emit()


# 追加攻撃追加
func add_extra_attacks(value: int) -> void:
	extra_attack_count += maxi(0, value)
	changed.emit()
