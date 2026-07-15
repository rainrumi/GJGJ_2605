class_name EnemyDamageRequest
extends RefCounted

var amount := 0 # 要求ダメージ
var target: EnemyData # 対象データ


# ダメージ要求初期化
func _init(value: int, target_data: EnemyData) -> void:
	amount = maxi(0, value)
	target = target_data


# ダメージ値設定
func set_amount(value: int) -> void:
	amount = maxi(0, value)
