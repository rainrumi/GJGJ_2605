class_name EnemyEffectOnElapsedTimeTriggerAdjacentAcidDamage
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 消化回数
@export_range(1, 64, 1) var hit_count := 1
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.consume_interval(interval_seconds) # 発火数
	for enemy in context.get_targets(target): context.deal_acid_damage(enemy, context.resolver.get_last_acid_damage(), hit_count * count)
