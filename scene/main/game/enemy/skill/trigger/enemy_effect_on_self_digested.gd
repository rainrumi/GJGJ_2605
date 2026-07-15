class_name EnemyEffectOnSelfDigested
extends EnemyEffectOnDigested


# 自身消化判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	var digestion_data := data as DigestionActivationData # 消化発動値
	return digestion_data != null and digestion_data.target_enemy == source
