class_name EnemyEffectOnAfterAcidDamage
extends EnemyEffectOnDamage


# 発動Signal接続
func bind() -> void:
	for enemy in _damage_targets:
		if enemy == null:
			continue
		var callback := _on_damage_resolved.bind(enemy) # 対象付き受信
		connect_trigger(enemy.data.hp.damage_resolved, callback)


# 被弾結果受信
func _on_damage_resolved(amount: int, overkill: int, target_enemy: Enemy) -> void:
	var target_data := target_enemy.data if target_enemy != null else null # 対象データ
	queue_activation(AfterAcidDamageActivationData.new(amount, overkill, target_data, target_enemy))
