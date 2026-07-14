class_name EnemyDigestionState
extends RefCounted

signal digested_registered(enemy: Enemy)
signal digestion_batch_resolved(data: AnyDigestedActivationData)

var last_acid_damage := 0 # 直近消化値
var _pending: Array[Enemy] = [] # 消化済み一覧


# 消化状態初期化
func reset() -> void:
	last_acid_damage = 0
	_pending.clear()


# 消化済み登録
func register(enemy: Enemy) -> void:
	if enemy == null or _pending.has(enemy):
		return
	_pending.append(enemy)
	digested_registered.emit(enemy)


# 消化済み消費
func consume() -> Array[Enemy]:
	var values: Array[Enemy] = _pending.duplicate() # 消化済み一覧
	_pending.clear()
	return values


# 直近消化設定
func set_last_damage(value: int) -> void:
	last_acid_damage = maxi(0, value)


# 消化群通知
func notify_digestion_batch(data: AnyDigestedActivationData) -> void:
	digestion_batch_resolved.emit(data)
