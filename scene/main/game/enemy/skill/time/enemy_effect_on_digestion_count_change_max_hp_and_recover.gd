class_name EnemyEffectOnDigestionCountChangeMaxHpAndRecover
extends EnemyEffect

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.ANY_DIGESTED): return
	var count := context.get_state_int("digestion_count") + context.digested_enemies.size() # 消化数
	var triggers := int(count / required_count) # 発火数
	context.set_state("digestion_count", count % required_count)
	if triggers > 0: context.source.add_max_hp(max_hp_delta * triggers, false); context.recover(context.source, recovery * triggers)
