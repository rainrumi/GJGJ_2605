class_name EnemyEffectOnDigestedDealAdjacentAttackAcidDamage
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.DIGESTED) and runtime.target == runtime.source:
		for enemy in runtime.get_targets(target): runtime.deal_acid_damage(enemy, roundi(float(runtime.source.get_damage()) * attack_multiplier))
