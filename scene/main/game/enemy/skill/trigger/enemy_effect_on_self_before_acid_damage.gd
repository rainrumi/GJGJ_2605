class_name EnemyEffectOnSelfBeforeAcidDamage
extends EnemyEffectOnBeforeAcidDamage


# 自身被弾判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	var damage_data := get_damage_activation_from(data) # 被弾発動値
	return damage_data != null and damage_data.target == owner
