class_name EnemyEffectOnSelfAfterAcidDamage
extends EnemyEffectOnDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_after_acid_damage(self)


# 自身被弾判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return get_activation_target_from(data) == source


# 消化後発動許可
func can_activate_when_owner_digested() -> bool:
	return true
