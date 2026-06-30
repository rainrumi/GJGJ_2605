class_name DreamSeedSkillState
extends RefCounted

var next_acid_damage_bonus_rate := 0.0
var next_time_reduction_bonus_rate := 0.0
var next_acid_damage_flat_bonus := 0
var next_player_damage_multiplier_bonus := 0.0
var next_heal_bonus_rate := 0.0
var max_hp_bonus_rate := 0.0
var recovery_accumulated_for_max_hp := 0
var last_acid_damage_total := 0
var last_hp_loss := 0
var revive_count := 0
var day := 1
var remove_from_stomach_disabled := false


# 初期化
func reset() -> void:
	next_acid_damage_bonus_rate = 0.0
	next_time_reduction_bonus_rate = 0.0
	next_acid_damage_flat_bonus = 0
	next_player_damage_multiplier_bonus = 0.0
	next_heal_bonus_rate = 0.0
	max_hp_bonus_rate = 0.0
	recovery_accumulated_for_max_hp = 0
	last_acid_damage_total = 0
	last_hp_loss = 0
	revive_count = 0
	remove_from_stomach_disabled = false
