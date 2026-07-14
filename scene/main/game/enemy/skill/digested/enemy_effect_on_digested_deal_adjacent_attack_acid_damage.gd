class_name EnemyEffectOnDigestedDealAdjacentAttackAcidDamage
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	if is_digested_activation() and get_activation_target() == source:
		for enemy in get_targets(target): deal_acid_damage(enemy, roundi(float(source.get_damage()) * attack_multiplier))
