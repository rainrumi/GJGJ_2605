class_name EnemyEffectOnAdjacentObjectChanceScaleTakenAcidDamage
extends EnemyEffect

# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.BEFORE_ACID_DAMAGE) or runtime.target == null: return
	if runtime.get_adjacent_objects().has(runtime.target) and runtime.get_adjacent_objects().size() >= required_count and runtime.roll(chance): runtime.damage = roundi(float(runtime.damage) * damage_multiplier)
