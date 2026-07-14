class_name EnemyEffectOnAdjacentEnemyAcidChangeAttack
extends EnemyEffectOnAdjacentAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_acid_damage(self)


# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	source.add_damage(roundi(EnemyEffectValueCalculator.scale(source, float(attack_delta))))
