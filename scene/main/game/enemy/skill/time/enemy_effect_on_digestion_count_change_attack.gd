class_name EnemyEffectOnDigestionCountChangeAttack
extends EnemyEffectOnDigestionBatch


# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	var count := get_state_int("digestion_count") + get_activation_digested_enemies().size() # 消化数
	var triggers := int(count / required_count) # 発火数
	set_state("digestion_count", count % required_count)
	if triggers > 0: source.add_damage(roundi(EnemyEffectValueCalculator.scale(source, float(attack_delta * triggers))))
