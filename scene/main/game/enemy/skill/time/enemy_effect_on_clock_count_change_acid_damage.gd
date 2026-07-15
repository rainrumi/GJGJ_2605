class_name EnemyEffectOnClockCountChangeAcidDamage
extends EnemyEffectOnTimeProgressed


# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count: EnemyEffectStatChanges.add_permanent_acid_modifier(source, damage_delta, damage_multiplier)
