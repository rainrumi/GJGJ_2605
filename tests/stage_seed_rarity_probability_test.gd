extends Node

const POOL_PATHS := [
	"res://data/resources/seeds/location_pool/area_iriyu_seed_pool.tres",
	"res://data/resources/seeds/location_pool/area_elmena_seed_pool.tres",
	"res://data/resources/seeds/location_pool/area_riran_seed_pool.tres",
	"res://data/resources/seeds/location_pool/area_lunova_seed_pool.tres",
]
const SAMPLE_COUNT := 10000
const PROBABILITY_TOLERANCE := 0.03

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var reward := StageClearReward.new()
	for pool_path in POOL_PATHS:
		var pool := load(pool_path) as SeedPoolInfo
		_expect(pool != null, "%sを読み込める" % pool_path)
		if pool == null:
			continue
		_expect(pool.use_stage_clear_rarity_probabilities, "%sでレア度抽選を有効化" % pool_path)
		_expect(is_equal_approx(pool.normal_probability, 0.25), "%sの通常確率が25%%" % pool_path)
		_expect(is_equal_approx(pool.rare_probability, 0.75), "%sのレア確率が75%%" % pool_path)
		_check_distribution(reward, pool, pool_path)
		_check_no_duplicate_options(reward, pool, pool_path)

	print("StageSeedRarityProbabilityTest: %d failures" % _failures)
	get_tree().quit(_failures)


func _check_distribution(reward: StageClearReward, pool: SeedPoolInfo, pool_path: String) -> void:
	var stage := StageInfo.new()
	stage.drop_seed_pool = pool
	var base_options: Array[SeedInfo] = [SeedInfo.new()]
	var normal_count := 0
	var rare_count := 0
	seed(20260916)
	for _index in range(SAMPLE_COUNT):
		var options := reward.get_stage_seed_options(base_options, stage)
		_expect(options.size() == 1, "%sの抽選候補が1件" % pool_path)
		if options.is_empty():
			continue
		if options[0].rarity == SeedInfo.Rarity.NORMAL:
			normal_count += 1
		elif options[0].rarity == SeedInfo.Rarity.RARE:
			rare_count += 1

	var normal_rate := float(normal_count) / SAMPLE_COUNT
	var rare_rate := float(rare_count) / SAMPLE_COUNT
	_expect(absf(normal_rate - 0.25) <= PROBABILITY_TOLERANCE, "%sの通常抽選率が約25%%" % pool_path)
	_expect(absf(rare_rate - 0.75) <= PROBABILITY_TOLERANCE, "%sのレア抽選率が約75%%" % pool_path)


func _check_no_duplicate_options(
	reward: StageClearReward, pool: SeedPoolInfo, pool_path: String
) -> void:
	var stage := StageInfo.new()
	stage.drop_seed_pool = pool
	var base_options: Array[SeedInfo] = [SeedInfo.new(), SeedInfo.new(), SeedInfo.new()]
	seed(20260917)
	for _index in range(100):
		var options := reward.get_stage_seed_options(base_options, stage)
		var skill_ids: Dictionary[int, bool] = {}
		for seed_info in options:
			_expect(not skill_ids.has(seed_info.skill_id), "%sの1回の候補内で種が重複しない" % pool_path)
			skill_ids[seed_info.skill_id] = true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("FAIL: %s" % message)
