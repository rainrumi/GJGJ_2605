class_name EnemyEffectOnClockCountGrantAdjacentGuard
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 無効回数
@export_range(1, 64, 1) var guard_count := 1
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.get_state_int("clock_count") + 1 # 時刻回数
	context.set_state("clock_count", count % required_count)
	if count >= required_count:
		for enemy in context.get_targets(target): context.resolver.add_acid_guards(enemy, guard_count)
