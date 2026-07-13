class_name EnemyEffectOnAdjacentEmptyCellChangeTakenAcidDamage
extends EnemyEffect

# マス毎差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	var count := context.get_open_adjacent_count() # 空隣接数
	context.add_acid_damage_delta(context.source, damage_delta * count)
	context.multiply_acid_damage(context.source, pow(damage_multiplier, count))
