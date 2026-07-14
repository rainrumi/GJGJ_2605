class_name EnemyEffectOnAdjacentEnemyAcidRecoverVictim
extends EnemyEffectOnAdjacentAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_acid_damage(self)


# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.recover(source, get_activation_target(), recovery_per_adjacent * EnemyEffectTargetQuery.get_adjacent_enemies(source, enemies).size())
