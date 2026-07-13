class_name EnemyEffectOnAdjacentObjectChanceScaleTakenAcidDamage
extends EnemyEffect

# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.BEFORE_ACID_DAMAGE) or context.target == null: return
	if context.get_adjacent_objects().has(context.target) and context.get_adjacent_objects().size() >= required_count and context.roll(chance): context.damage = roundi(float(context.damage) * damage_multiplier)
