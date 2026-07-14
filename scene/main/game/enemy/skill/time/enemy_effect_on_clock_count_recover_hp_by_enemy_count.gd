class_name EnemyEffectOnClockCountRecoverHpByEnemyCount
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 敵毎回復量
@export var recovery_per_enemy := 0
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	if not is_progress_time_activation(): return
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count:
		var enemy_count := get_active_enemies().size() # 敵数
		if not include_self: enemy_count = maxi(0, enemy_count - 1)
		recover(source, recovery_per_enemy * enemy_count)
