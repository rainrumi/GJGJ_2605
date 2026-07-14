class_name PlayerHealth
extends RefCounted

signal damage_requested(amount: int)

var _pending_damage: Array[int] = [] # 待機ダメージ


# ダメージ要求
func request_damage(amount: int) -> void:
	if amount <= 0:
		return
	_pending_damage.append(amount)
	damage_requested.emit(amount)


# 要求一覧消費
func consume_damage() -> Array[int]:
	var values: Array[int] = _pending_damage.duplicate() # 要求一覧
	_pending_damage.clear()
	return values


# 要求初期化
func clear() -> void:
	_pending_damage.clear()
