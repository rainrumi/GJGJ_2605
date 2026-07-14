class_name EnemyEffectOnAdjacentEmptyCellChangeTakenAcidDamage
extends EnemyEffect

# マス毎差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.REFRESH): return
	var count := runtime.get_open_adjacent_count() # 空隣接数
	runtime.add_acid_damage_delta(runtime.source, damage_delta * count)
	runtime.multiply_acid_damage(runtime.source, pow(damage_multiplier, count))
