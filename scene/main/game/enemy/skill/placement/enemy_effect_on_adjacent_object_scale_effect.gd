class_name EnemyEffectOnAdjacentObjectScaleEffect
extends EnemyEffect

# 効果倍率
@export var effect_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.REFRESH): return
	var targets := runtime.get_adjacent_objects() # 隣接対象
	if targets.size() < required_count: return
	for enemy in targets: runtime.multiply_effect(enemy, effect_multiplier)
