class_name EnemyEffectStack
extends RefCounted

var _pending: Array[EnemyEffect] = [] # 待機効果
var _deferred: Array[EnemyEffect] = [] # 次回効果
var _executing := false # 実行中


# スタック初期化
func clear() -> void:
	_pending.clear()
	_deferred.clear()
	_executing = false


# 発動要求追加
func request(effect: EnemyEffect) -> bool:
	if effect == null or not effect.enabled or effect.runtime == null:
		return false
	var destination := _deferred if _executing else _pending # 格納先
	if destination.has(effect):
		return false
	destination.append(effect)
	return true


# 効果順次実行
func execute() -> void:
	if _executing:
		return
	_executing = true
	while not _pending.is_empty():
		_pending.sort_custom(_has_higher_priority)
		var current := _pending.duplicate() # 今回効果
		_pending.clear()
		for effect in current:
			if effect != null and effect.enabled and effect.runtime != null:
				effect.apply()
		if not _deferred.is_empty():
			_pending.append_array(_deferred)
			_deferred.clear()
	_executing = false


# 優先順判定
func _has_higher_priority(a: EnemyEffect, b: EnemyEffect) -> bool:
	return a.priority < b.priority
