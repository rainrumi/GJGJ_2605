class_name EnemyEffectOnClockCountChangeAttack
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.get_state_int("clock_count") + 1 # 時刻回数
	context.set_state("clock_count", count % required_count)
	if count >= required_count: context.source.add_damage(roundi(context.scale_value(float(attack_delta))))
