class_name SeedEffectOnBattleChangeTimeReductionRate
extends SeedEffect


@export var rate := 0.0 # 短縮率
@export var hp_loss_rate := 0.0 # 被弾率
@export var elapsed_step_rate := 0.0 # 経過率
@export var min_interval_rate := -999.0 # 最小間隔率
@export var max_interval_rate := 999.0 # 最大間隔率


func is_unconditional_status_change() -> bool:
	return is_zero_approx(hp_loss_rate) and is_zero_approx(elapsed_step_rate)


# 時間率取得
func get_time_reduction_rate(state: DreamSeedSkillState, _context: Dictionary) -> float:
	var value := rate # 適用値
	value -= float(state.hp_loss_count) * hp_loss_rate
	var start_count := int(state.effect_start_progress_counts.get(get_instance_id(), 0))
	value += elapsed_step_rate * float(state.progress_time_count - start_count)
	return _clamp_interval_rate(value)


# elapsed数
func on_finish_acid_seed(state: DreamSeedSkillState, _context: Dictionary) -> bool:
	state.effect_start_progress_counts[get_instance_id()] = state.progress_time_count
	return true


func persists_after_seed_digested() -> bool:
	return true


# 間隔率制限
func _clamp_interval_rate(reduction_rate: float) -> float:
	var min_rate := minf(min_interval_rate, max_interval_rate) # 下限率
	var max_rate := maxf(min_interval_rate, max_interval_rate) # 上限率
	return clampf(reduction_rate, min_rate, max_rate)
