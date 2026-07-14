class_name TimeActivationData
extends EnemyEffectActivationData

var elapsed_seconds := 0 # 経過秒数
var current_seconds := 0 # 現在秒数


# 発動値初期化
func _init(elapsed := 0, current := 0) -> void:
	elapsed_seconds = maxi(0, elapsed)
	current_seconds = maxi(0, current)
