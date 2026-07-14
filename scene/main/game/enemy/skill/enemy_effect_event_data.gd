class_name EnemyEffectEventData
extends RefCounted

signal damage_changed(value: int)

var event: EnemyEffect.Event = EnemyEffect.Event.REFRESH # 発火種別
var target: Enemy # 発火対象
var damage := 0 # 被ダメージ
var overkill_damage := 0 # 超過ダメージ
var clock := BattleClock.new() # 戦闘時刻
var elapsed_seconds: int:
	get: return clock.elapsed_seconds
	set(value): clock.elapsed_seconds = value
var current_seconds: int:
	get: return clock.current_seconds
	set(value): clock.current_seconds = value
var digested_enemies: Array[Enemy] = [] # 消化済み一覧


# イベント判定
func is_event(value: EnemyEffect.Event) -> bool:
	return event == value


# ダメージ設定
func set_damage(value: int) -> void:
	damage = maxi(0, value)
	damage_changed.emit(damage)
