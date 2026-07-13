class_name EnemyEffectOnBattleIgnoreAcidDamageAtMost
extends EnemyEffect

# 閾値
@export var threshold := 0
# 閾値参照元
@export var threshold_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.BEFORE_ACID_DAMAGE) and context.target == context.source and context.damage <= context.resolve_value(threshold_source, threshold): context.damage = 0
