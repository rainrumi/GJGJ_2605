class_name EnemyEffectOnSelfDigested
extends EnemyEffectOnDigested


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_digested(self)


# 自身消化判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return get_activation_target_from(data) == source
