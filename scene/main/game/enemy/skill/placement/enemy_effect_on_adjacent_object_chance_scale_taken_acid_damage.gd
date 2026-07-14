class_name EnemyEffectOnAdjacentObjectChanceScaleTakenAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_BEFORE_ACID_DAMAGE

# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply() -> void:
	if not is_before_acid_damage_activation() or get_activation_target() == null: return
	if get_adjacent_objects().has(get_activation_target()) and get_adjacent_objects().size() >= required_count and roll(chance): set_activation_damage(roundi(float(get_activation_damage()) * damage_multiplier))
