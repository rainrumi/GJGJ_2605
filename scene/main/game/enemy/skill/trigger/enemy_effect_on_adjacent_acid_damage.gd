class_name EnemyEffectOnAdjacentAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_acid_damage(self)


# 隣接被弾判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return EnemyEffectTargetQuery.get_adjacent_enemies(source, enemies).has(get_activation_target_from(data))
