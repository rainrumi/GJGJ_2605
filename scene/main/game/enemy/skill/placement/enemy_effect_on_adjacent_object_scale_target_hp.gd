class_name EnemyEffectOnAdjacentObjectScaleTargetHp
extends EnemyEffect

# HP倍率
@export var hp_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	var targets := context.get_adjacent_objects() # 隣接対象
	if targets.size() < required_count: return
	for enemy in targets: context.multiply_hp(enemy, hp_multiplier)
