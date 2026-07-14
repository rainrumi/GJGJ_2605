class_name EnemyEffectOnClockCountGrantAdjacentGuard
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES | DEPENDENCY_STOMACH

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 無効回数
@export_range(1, 64, 1) var guard_count := 1
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	if not is_progress_time_activation(): return
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count:
		for enemy in get_targets(target): add_acid_guards(enemy, guard_count)
