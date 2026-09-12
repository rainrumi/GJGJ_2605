class_name RunState
extends Resource

const DEFAULT_STOMACH_COLUMNS := 4
const DEFAULT_STOMACH_ROWS := 5
const HUWAHUWA_SCHOOL_STAGE_ID := 0
const HUWAHUWA_SCHOOL_UNLOCK_DAY_INTERVAL := 4
const MAX_HUWAHUWA_SCHOOL_STRENGTHENED_ENEMY_INDEX := 5
const STAGE_NOVEL_UNLOCK_DEFEAT_INTERVAL := 3
const MAX_STAGE_NOVEL_INDEX := 3
const BATTLE_START_MINUTES := 22 * 60

var current_day := 1
var current_hp := 100
var current_minutes := BATTLE_START_MINUTES
var max_hp := 100
var stomach_columns := DEFAULT_STOMACH_COLUMNS
var stomach_rows := DEFAULT_STOMACH_ROWS
var selected_stage_id := 0
var selected_stage: StageInfo
var current_area_stage: StageInfo
var planted_flowers: Array[SeedInfo] = []
var stored_seeds: Array[SeedInfo] = []
var permanent_acid_damage_bonus_rate := 0.0
var day_seed_acid_bonus := 0.0
var day_seed_bonus_deadline := -1
var day_elapsed_minutes := 0
var day_start_minutes := BATTLE_START_MINUTES
var last_time_over_recovery_percent := 0
var normal_enemy_preset_indices := {}
var strengthened_enemy_preset_indices := {}
var normal_enemy_defeat_counts := {}
var strengthened_enemy_defeat_counts := {}
var played_stage_novel_indices := {}
var is_lara_unlocked := false
var is_continuous_play_unlocked := false
var has_challenged_area_today := false
var lara_current_location: StageInfo
var previous_area_stage: StageInfo
var lara_interaction_day := 0
var played_lara_area_novels: Dictionary[int, bool] = {}
var lara_digestion_count := 0
var last_lara_judge_day := 0


# 対象初期化
func reset() -> void:
	current_day = 1
	current_hp = max_hp
	current_minutes = BATTLE_START_MINUTES
	stomach_columns = DEFAULT_STOMACH_COLUMNS
	stomach_rows = DEFAULT_STOMACH_ROWS
	selected_stage_id = 0
	selected_stage = null
	current_area_stage = null
	planted_flowers.clear()
	stored_seeds.clear()
	permanent_acid_damage_bonus_rate = 0.0
	day_seed_acid_bonus = 0.0
	day_seed_bonus_deadline = -1
	day_elapsed_minutes = 0
	day_start_minutes = BATTLE_START_MINUTES
	last_time_over_recovery_percent = 0
	normal_enemy_preset_indices.clear()
	strengthened_enemy_preset_indices.clear()
	normal_enemy_defeat_counts.clear()
	strengthened_enemy_defeat_counts.clear()
	played_stage_novel_indices.clear()
	is_lara_unlocked = false
	is_continuous_play_unlocked = false
	has_challenged_area_today = false
	lara_current_location = null
	previous_area_stage = null
	lara_interaction_day = 0
	played_lara_area_novels.clear()
	lara_digestion_count = 0
	last_lara_judge_day = 0


# ラーラ解放
func unlock_lara() -> void:
	is_lara_unlocked = true


func unlock_continuous_play() -> void:
	is_continuous_play_unlocked = true


func mark_area_challenged_today() -> void:
	has_challenged_area_today = true


func reset_daily_challenge_state() -> void:
	has_challenged_area_today = false


# 進行時刻から再計算し、再表示や日またぎで二重加算しない。
func update_lara_progress(schedule: LaraScheduleInfo, candidates: Array[StageInfo]) -> void:
	lara_digestion_count = schedule.get_total_digestion_count(current_day, current_minutes)
	if not is_lara_unlocked:
		lara_current_location = null
		return
	var area := schedule.get_area(current_day, current_minutes)
	for candidate in candidates:
		if candidate != null and candidate.stage_area == area:
			lara_current_location = candidate
			return
	push_error("RunState: ラーラ予定のエリア%dがlara_location_catalogにありません" % area)
	lara_current_location = null


func get_player_digestion_count() -> int:
	var count := 0
	for defeats in [normal_enemy_defeat_counts, strengthened_enemy_defeat_counts]:
		for value: int in defeats.values():
			count += value
	return count


func get_lunova_boss_defeat_count() -> int:
	var count := 0
	for key: String in strengthened_enemy_defeat_counts:
		if key.get_slice(":", 1).to_int() == StageInfo.StageArea.LUNOVA_OLD_CITY:
			count += int(strengthened_enemy_defeat_counts[key])
	return count


# 戦闘ステージ選択
func select_stage(stage: StageInfo) -> void:
	if stage == null:
		return
	selected_stage_id = stage.stage_id
	selected_stage = stage
	if stage.stage_area != StageInfo.StageArea.huwahuwaSchool:
		previous_area_stage = current_area_stage
		current_area_stage = stage


# 敵編成選択
func pick_enemy_preset(stage: StageInfo) -> EnemyPresetInfo:
	if stage == null or stage.enemy_data == null:
		return null
	if stage.is_high_difficulty:
		return _pick_strengthened_enemy_preset(stage)
	return _pick_normal_enemy_preset(stage)


# 通常敵編成選択
func _pick_normal_enemy_preset(stage: StageInfo) -> EnemyPresetInfo:
	# key
	var key := _get_stage_progress_key(stage)
	# 番号
	var index := int(normal_enemy_preset_indices.get(key, 0))
	# 編成
	var preset := stage.enemy_data.get_normal_enemy_preset(index)
	if preset != null:
		return preset
	return stage.enemy_data.pick_endless_enemy_preset()


# 強化敵編成選択
func _pick_strengthened_enemy_preset(stage: StageInfo) -> EnemyPresetInfo:
	# key
	var key := _get_stage_progress_key(stage)
	# 番号
	var index := int(strengthened_enemy_preset_indices.get(key, 0))
	# unlocked数
	var unlocked_count := get_strengthened_enemy_unlock_count(stage)
	if unlocked_count <= 0:
		return null
	# 最大番号
	var max_index := unlocked_count - 1
	if index > max_index:
		index = max_index
	# 編成
	var preset := stage.enemy_data.get_strengthened_enemy_preset(index)
	if preset != null:
		return preset
	return stage.enemy_data.get_last_strengthened_enemy_preset()


# 通常ステージclear記録
func record_normal_stage_clear(stage: StageInfo) -> void:
	if stage == null or stage.is_high_difficulty:
		return
	# key
	var key := _get_stage_progress_key(stage)
	normal_enemy_defeat_counts[key] = int(normal_enemy_defeat_counts.get(key, 0)) + 1
	# 番号
	var index := int(normal_enemy_preset_indices.get(key, 0))
	if stage.enemy_data != null and stage.enemy_data.get_normal_enemy_preset(index) != null:
		normal_enemy_preset_indices[key] = index + 1


# ステージclear記録
func record_stage_clear(stage: StageInfo) -> void:
	if stage == null:
		return
	if stage.is_high_difficulty:
		record_strengthened_stage_clear(stage)
		return
	record_normal_stage_clear(stage)


# 強化ステージclear記録
func record_strengthened_stage_clear(stage: StageInfo) -> void:
	if stage == null or not stage.is_high_difficulty:
		return
	# key
	var key := _get_stage_progress_key(stage)
	strengthened_enemy_defeat_counts[key] = int(strengthened_enemy_defeat_counts.get(key, 0)) + 1
	if stage.enemy_data == null:
		return
	# 番号
	var index := int(strengthened_enemy_preset_indices.get(key, 0))
	# 最大番号
	var max_index := get_strengthened_enemy_unlock_count(stage) - 1
	if max_index < 0:
		return
	index = mini(index, max_index)
	if stage.enemy_data.get_strengthened_enemy_preset(index) != null:
		strengthened_enemy_preset_indices[key] = index + 1


# ステージexploration割合取得
func get_stage_exploration_percent(stage: StageInfo) -> int:
	if stage == null or stage.enemy_data == null:
		return 0
	# 通常数
	var normal_count := _get_exploration_normal_enemy_count(stage)
	# 強化数
	var strengthened_count := stage.enemy_data.strengthened_enemy_presets.size()
	# 合計weight
	var total_weight := normal_count + strengthened_count * 2
	if total_weight <= 0:
		return 0
	# key
	var key := _get_stage_progress_key(stage)
	# cleared通常数
	var cleared_normal_count := mini(int(normal_enemy_defeat_counts.get(key, 0)), normal_count)
	# cleared強化数
	var cleared_strengthened_count := mini(int(strengthened_enemy_defeat_counts.get(key, 0)), strengthened_count)
	# clearedweight
	var cleared_weight := cleared_normal_count + cleared_strengthened_count * 2
	return clampi(roundi(float(cleared_weight) / float(total_weight) * 100.0), 0, 100)


# 強化敵解放数取得
func get_strengthened_enemy_unlock_count(stage: StageInfo) -> int:
	if stage != null and stage.stage_id == HUWAHUWA_SCHOOL_STAGE_ID:
		return mini(MAX_HUWAHUWA_SCHOOL_STRENGTHENED_ENEMY_INDEX, int(current_day / HUWAHUWA_SCHOOL_UNLOCK_DAY_INTERVAL))
	return get_stage_novel_unlock_count(stage)


# 挑戦可能な未クリア強化敵がいるか
func has_pending_strengthened_enemy(stage: StageInfo) -> bool:
	if stage == null:
		return false
	var unlocked_count := get_strengthened_enemy_unlock_count(stage)
	var defeated_count := int(strengthened_enemy_defeat_counts.get(_get_stage_progress_key(stage), 0))
	return defeated_count < unlocked_count


# ステージノベル解放数取得
func get_stage_novel_unlock_count(stage: StageInfo) -> int:
	if stage == null:
		return 0
	# defeat数
	var defeat_count := int(normal_enemy_defeat_counts.get(_get_stage_progress_key(stage), 0))
	# availableノベル数
	var available_novel_count := stage.stage_unlock_novel_texts.size()
	# 最大ノベル数
	var max_novel_count := mini(MAX_STAGE_NOVEL_INDEX, available_novel_count)
	return mini(max_novel_count, int(defeat_count / STAGE_NOVEL_UNLOCK_DEFEAT_INTERVAL))


# ノベル番号取得
func get_unplayed_unlocked_stage_novel_indices(stage: StageInfo) -> Array[int]:
	# 番号
	var indices: Array[int] = []
	# unlocked数
	var unlocked_count := get_stage_novel_unlock_count(stage)
	# played数
	var played_count := int(played_stage_novel_indices.get(_get_stage_progress_key(stage), 0))
	for scenario_index in range(played_count + 1, unlocked_count + 1):
		indices.append(scenario_index)
	return indices


# markステージノベルplayed処理
func mark_stage_novel_played(stage: StageInfo, scenario_index: int) -> void:
	if stage == null:
		return
	# key
	var key := _get_stage_progress_key(stage)
	played_stage_novel_indices[key] = maxi(int(played_stage_novel_indices.get(key, 0)), scenario_index)


# exploration通常敵数取得
func _get_exploration_normal_enemy_count(stage: StageInfo) -> int:
	if not stage.has_normal_stage:
		return 0
	return mini(MAX_STAGE_NOVEL_INDEX, stage.stage_unlock_novel_texts.size()) * STAGE_NOVEL_UNLOCK_DEFEAT_INTERVAL


# ステージprogresskey取得
func _get_stage_progress_key(stage: StageInfo) -> String:
	return "%d:%d" % [stage.stage_id, stage.stage_area]


func apply_day_finished_seed_effects() -> void:
	var increment := 0.0
	var expired := day_seed_bonus_deadline >= 0 and current_minutes > day_seed_bonus_deadline
	for seed in planted_flowers:
		if seed == null or seed.get_main_skill() == null:
			continue
		for effect in seed.get_main_skill().get_effects():
			if effect is SeedEffectOnDayFinishedChangeAcidDamage:
				day_seed_bonus_deadline = effect.before_minutes
				if current_minutes > effect.before_minutes:
					expired = true
				else:
					increment += effect.get_day_finished_bonus(0.0, current_minutes)
	day_seed_acid_bonus = 0.0 if expired else day_seed_acid_bonus + increment
