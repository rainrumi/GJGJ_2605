class_name BattleInfo
extends RefCounted

var starting_hp := 100
var day := 1
var stage_id := 0
var stage: StageInfo
var enemy_preset: EnemyPresetInfo
var stomach_columns := RunState.DEFAULT_STOMACH_COLUMNS
var stomach_rows := RunState.DEFAULT_STOMACH_ROWS
var flowers: Array[SeedInfo] = []
var permanent_acid_damage_bonus_rate := 0.0
