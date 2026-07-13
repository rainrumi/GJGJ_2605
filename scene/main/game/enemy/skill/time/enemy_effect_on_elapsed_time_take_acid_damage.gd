class_name EnemyEffectOnElapsedTimeTakeAcidDamage
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# ダメージ
@export var damage := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.PROGRESS_TIME): context.deal_acid_damage(context.source, damage, context.consume_interval(interval_seconds))
