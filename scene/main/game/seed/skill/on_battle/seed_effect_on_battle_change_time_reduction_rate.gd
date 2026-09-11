class_name SeedEffectOnBattleChangeTimeReductionRate
extends SeedEffect


@export var rate := 1.0 # 基礎の消化間隔倍率
@export var hp_loss_rate := 1.0 # HP減少1回あたりの間隔倍率
@export var elapsed_step_rate := 1.0 # 時間経過1回あたりの間隔倍率
@export var min_interval_rate := -999.0 # 最小間隔率
@export var max_interval_rate := 999.0 # 最大間隔率


var _digested_progress_count := -1


func is_unconditional_status_change() -> bool:
	return is_equal_approx(hp_loss_rate, 1.0) and is_equal_approx(elapsed_step_rate, 1.0)


# 時間率取得
func get_time_reduction_rate(state: DreamSeedSkillState, _context: Dictionary) -> float:
	var value := rate + float(state.hp_loss_count) * (hp_loss_rate - 1.0)
	var progress_count := state.progress_time_count if _digested_progress_count < 0 else _digested_progress_count
	# 各回の増減は基礎間隔に加算し、指数的には累乗しない。
	value += (elapsed_step_rate - 1.0) * float(progress_count)
	return _clamp_interval_rate(value)


func get_initial_time_reduction_rate(state: DreamSeedSkillState) -> float:
	var value := rate + float(state.hp_loss_count) * (hp_loss_rate - 1.0)
	return _clamp_interval_rate(value)


# elapsed数
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	_digested_progress_count = state.progress_time_count
	return true


func persists_after_seed_digested() -> bool:
	return true


# 間隔率制限
func _clamp_interval_rate(interval_rate: float) -> float:
	var min_rate := minf(min_interval_rate, max_interval_rate) # 下限率
	var max_rate := maxf(min_interval_rate, max_interval_rate) # 上限率
	return clampf(interval_rate, min_rate, max_rate)
