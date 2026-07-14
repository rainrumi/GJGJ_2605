class_name EnemyEffectOnAdjacentEmptyCellChangeTakenAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_STOMACH

# マス毎差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	var count := get_open_adjacent_count() # 空隣接数
	add_acid_damage_delta(source, damage_delta * count)
	multiply_acid_damage(source, pow(damage_multiplier, count))
