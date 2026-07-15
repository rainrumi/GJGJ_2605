class_name EnemyEffectOnSelfAfterAcidDamage
extends EnemyEffectOnAfterAcidDamage


# 自身被弾判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	var damage_data := get_damage_activation_from(data) # 被弾発動値
	return damage_data != null and damage_data.target == owner


# 消化後発動許可
func can_activate_when_owner_digested() -> bool:
	return true
