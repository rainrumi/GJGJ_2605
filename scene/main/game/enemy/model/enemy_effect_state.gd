class_name EnemyEffectState
extends RefCounted

var _values: Dictionary = {} # 継続値


# 状態取得
func get_value(key: String, default_value: Variant = null) -> Variant:
	return _values.get(key, default_value)


# 状態設定
func set_value(key: String, value: Variant) -> void:
	_values[key] = value


# 状態初期化
func clear() -> void:
	_values.clear()
