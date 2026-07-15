class_name EnemyEffectOnBeforeAcidDamage
extends EnemyEffectOnDamage


# 発動Signal接続
func bind() -> void:
	for enemy in _damage_targets:
		if enemy != null:
			connect_trigger(enemy.data.hp.damage_requested, _on_damage_requested)


# 被弾要求受信
func _on_damage_requested(request: EnemyDamageRequest) -> void:
	if request == null:
		return
	var data := BeforeAcidDamageActivationData.new() # 被弾前発動値
	data.setup_request(request, find_damage_target(request.target))
	queue_activation(data)
