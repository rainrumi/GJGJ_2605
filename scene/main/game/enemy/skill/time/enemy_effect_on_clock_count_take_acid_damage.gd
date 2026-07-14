class_name EnemyEffectOnClockCountTakeAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_DIGESTION_STATE

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	if not is_progress_time_activation(): return
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count: deal_acid_damage(source, damage)
