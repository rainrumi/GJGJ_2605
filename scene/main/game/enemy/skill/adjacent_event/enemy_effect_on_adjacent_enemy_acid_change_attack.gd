class_name EnemyEffectOnAdjacentEnemyAcidChangeAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if is_adjacent_acid_damage_activation() and get_adjacent_enemies().has(get_activation_target()): source.add_damage(roundi(scale_value(float(attack_delta))))
