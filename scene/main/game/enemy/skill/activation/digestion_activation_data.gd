class_name DigestionActivationData
extends TimeActivationData

var target_enemy: Enemy # 消化対象
var damage := 0 # 消化ダメージ
var overkill_damage := 0 # 超過ダメージ
var digested_enemies: Array[Enemy] = [] # 消化済み一覧


# 消化値初期化
func setup(
	target: Enemy,
	value: int,
	overkill: int,
	elapsed: int,
	current: int,
	digested: Array[Enemy]
) -> void:
	target_enemy = target
	damage = maxi(0, value)
	overkill_damage = maxi(0, overkill)
	elapsed_seconds = maxi(0, elapsed)
	current_seconds = maxi(0, current)
	digested_enemies = digested
