class_name EnemyEffectOnSelfBeforeAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_before_acid_damage(self)


# 自身被弾判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return get_activation_target_from(data) == source
