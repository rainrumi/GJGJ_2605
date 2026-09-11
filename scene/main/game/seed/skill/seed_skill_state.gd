class_name DreamSeedSkillState
extends RefCounted

var next_acid_damage_bonus_rate := 0.0 # 次酸倍率
var next_time_reduction_bonus_rate := 0.0 # 次短縮率
var next_acid_damage_flat_bonus := 0 # 次酸加算
var progress_acid_damage_bonus_rate := 0.0 # 時酸倍率
var next_player_damage_rate := 0.0 # 次被弾率
var next_heal_bonus_rate := 0.0 # 次回復率
var max_hp_bonus_rate := 0.0 # 最大HP率
var recovery_accumulated_for_max_hp := 0 # 回復累計
var last_acid_damage_total := 0 # 酸総量
var last_hp_loss := 0 # 直近減HP
var revive_count := 0 # 復活数
var day := 1 # 日数
var remove_from_stomach_disabled := false # 取出無効
var persistent_acid_damage_bonus_rate := 0.0
var persistent_time_reduction_bonus_rate := 0.0
var persistent_stomach_rows_bonus := 0
var progress_time_count := 0
var hp_loss_count := 0
var pending_clock_rewind_minutes := 0
var persistent_interval_minutes_delta := 0
var persistent_stomach_columns_bonus := 0
var persistent_acid_line_bonus := 0
var remove_damage_multiplier := 1.0
var last_damaged_object_count := 0
var sunflower_max_hp_bonus := 0.0


# 初期化
func reset() -> void:
	sunflower_max_hp_bonus = 0.0
	last_damaged_object_count = 0
	remove_damage_multiplier = 1.0
	persistent_acid_line_bonus = 0
	persistent_stomach_columns_bonus = 0
	persistent_interval_minutes_delta = 0
	pending_clock_rewind_minutes = 0
	next_acid_damage_bonus_rate = 0.0
	next_time_reduction_bonus_rate = 0.0
	next_acid_damage_flat_bonus = 0
	progress_acid_damage_bonus_rate = 0.0
	next_player_damage_rate = 0.0
	next_heal_bonus_rate = 0.0
	max_hp_bonus_rate = 0.0
	recovery_accumulated_for_max_hp = 0
	last_acid_damage_total = 0
	last_hp_loss = 0
	revive_count = 0
	remove_from_stomach_disabled = false
	persistent_acid_damage_bonus_rate = 0.0
	persistent_time_reduction_bonus_rate = 0.0
	persistent_stomach_rows_bonus = 0
	progress_time_count = 0
	hp_loss_count = 0
