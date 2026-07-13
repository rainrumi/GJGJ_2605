class_name EnemyEffectOnElapsedTimeRecoverAdjacent
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 回復量
@export var recovery := 0
# 自身を含む
@export var include_self := false
# 通常攻撃停止
@export var suppress_default_attack := false

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.resolver.set_default_attack_disabled(context.source, suppress_default_attack); return
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.consume_interval(interval_seconds) # 発火数
	for enemy in context.get_adjacent_objects(): context.recover(enemy, recovery * count)
	if include_self: context.recover(context.source, recovery * count)
