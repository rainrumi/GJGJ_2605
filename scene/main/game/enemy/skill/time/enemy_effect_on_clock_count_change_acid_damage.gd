class_name EnemyEffectOnClockCountChangeAcidDamage
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.get_state_int("clock_count") + 1 # 時刻回数
	context.set_state("clock_count", count % required_count)
	if count >= required_count: context.resolver.add_permanent_acid_modifier(context.source, damage_delta, damage_multiplier)
