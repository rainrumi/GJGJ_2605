class_name EnemyEffectOnDigestionCountChangeMaxHpAndRecover
extends EnemyEffectOnDigestionBatch


# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

# 効果適用
func apply() -> void:
	var count := get_state_int("digestion_count") + get_activation_digested_enemies().size() # 消化数
	var triggers := int(count / required_count) # 発火数
	set_state("digestion_count", count % required_count)
	if triggers > 0: source.add_max_hp(max_hp_delta * triggers, false); EnemyEffectBattleActions.recover(source, source, recovery * triggers)
