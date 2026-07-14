class_name EnemyEffectOnAdjacentObjectShareAcidDamage
extends EnemyEffect

# 自身を含む
@export var include_self := true
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if not is_before_acid_damage_activation() or get_activation_target() != source: return
	var targets := get_adjacent_objects() # 分配対象
	if targets.size() < minimum_count: return
	if include_self: targets.append(source)
	var split := int(get_activation_damage() / maxi(1, targets.size())) # 分配値
	for enemy in targets:
		if enemy != source: deal_acid_damage(enemy, split)
	set_activation_damage(split)
