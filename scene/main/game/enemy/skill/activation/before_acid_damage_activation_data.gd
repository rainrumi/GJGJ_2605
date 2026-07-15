class_name BeforeAcidDamageActivationData
extends DamageActivationData

var request: EnemyDamageRequest # 元ダメージ要求


# ダメージ要求設定
func setup_request(value: EnemyDamageRequest, target_enemy_node: Enemy) -> void:
	request = value
	amount = request.amount if request != null else 0
	target = request.target if request != null else null
	target_enemy = target_enemy_node


# ダメージ設定
func set_amount(value: int) -> void:
	super.set_amount(value)
	if request != null:
		request.set_amount(amount)
