class_name EnemyEffectOnAdjacentObjectShareAcidDamage
extends EnemyEffect

# 自身を含む
@export var include_self := true
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.BEFORE_ACID_DAMAGE) or runtime.target != runtime.source: return
	var targets := runtime.get_adjacent_objects() # 分配対象
	if targets.size() < minimum_count: return
	if include_self: targets.append(runtime.source)
	var split := int(runtime.damage / maxi(1, targets.size())) # 分配値
	for enemy in targets:
		if enemy != runtime.source: runtime.deal_acid_damage(enemy, split)
	runtime.damage = split
