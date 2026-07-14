class_name DamageActivationData
extends EnemyEffectActivationData

var amount := 0 # 今回ダメージ
var overkill_amount := 0 # 超過ダメージ
var target: EnemyData # 対象データ


# 発動値初期化
func _init(value := 0, overkill := 0, target_data: EnemyData = null) -> void:
	amount = maxi(0, value)
	overkill_amount = maxi(0, overkill)
	target = target_data
