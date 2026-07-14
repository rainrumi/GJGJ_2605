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
func apply() -> void:
	if runtime.is_event(Event.REFRESH): runtime.resolver.set_default_attack_disabled(runtime.source, suppress_default_attack); return
	if not runtime.is_event(Event.PROGRESS_TIME): return
	var count := runtime.consume_interval(interval_seconds) # 発火数
	for enemy in runtime.get_adjacent_objects(): runtime.recover(enemy, recovery * count)
	if include_self: runtime.recover(runtime.source, recovery * count)
