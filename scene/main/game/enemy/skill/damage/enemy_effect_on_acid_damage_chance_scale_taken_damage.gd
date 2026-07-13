class_name EnemyEffectOnAcidDamageChanceScaleTakenDamage
extends EnemyEffect

# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.BEFORE_ACID_DAMAGE) and context.target == context.source and context.roll(chance): context.damage = roundi(float(context.damage) * damage_multiplier)
