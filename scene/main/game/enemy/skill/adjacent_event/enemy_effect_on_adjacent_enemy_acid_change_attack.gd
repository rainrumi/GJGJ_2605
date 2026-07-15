class_name EnemyEffectOnAdjacentEnemyAcidChangeAttack
extends EnemyEffectOnAdjacentAcidDamage



# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	source.add_damage(roundi(EnemyEffectValueCalculator.scale(source, float(attack_delta))))
