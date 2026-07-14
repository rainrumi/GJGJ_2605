class_name EnemyEffectOnBattleIgnoreAcidDamageAtMost
extends EnemyEffect

# 閾値
@export var threshold := 0
# 閾値参照元
@export var threshold_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.BEFORE_ACID_DAMAGE) and runtime.target == runtime.source and runtime.damage <= runtime.resolve_value(threshold_source, threshold): runtime.damage = 0
