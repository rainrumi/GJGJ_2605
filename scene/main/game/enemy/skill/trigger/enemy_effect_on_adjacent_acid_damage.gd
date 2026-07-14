class_name EnemyEffectOnAdjacentAcidDamage
extends EnemyEffectOnDamage

var enemies: Array[Enemy] = [] # 判定対象一覧


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_acid_damage(self)


# 隣接被弾判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return EnemyEffectTargetQuery.get_adjacent_enemies(source, enemies).has(get_activation_target_from(data))


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []


# 消化後発動許可
func can_activate_when_owner_digested() -> bool:
	return true
