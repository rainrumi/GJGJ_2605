extends SceneTree

const MAX_REWARD_SEED_ICONS := 8

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/stage_select/choice/stage_choice.tscn") as PackedScene
	var stage := load("res://data/resources/area/area_lunova/area_lunova.tres") as StageInfo
	_expect(packed != null, "ステージ選択ボタンSceneを読み込める")
	_expect(stage != null, "確認用のエリアStageInfoを読み込める")
	if packed == null or stage == null:
		quit(_failures)
		return

	var choice := packed.instantiate() as StageSelectChoice
	root.add_child(choice)
	await process_frame
	var more_texture := choice.reward_seed_more_texture
	choice.setup_choice(stage)
	await process_frame

	var reward_container := choice.get_node("RewardCenterContainer/RewardHBoxContainer") as HFlowContainer
	var template := reward_container.get_node("RewardIcon") as TextureRect
	var visible_icons: Array[TextureRect] = []
	for child in reward_container.get_children():
		if child is TextureRect and child.visible:
			visible_icons.append(child as TextureRect)

	var rare_seeds: Array[SeedInfo] = []
	for seed in stage.drop_seed_pool.rare_skills:
		if seed != null and seed.rarity == SeedInfo.Rarity.RARE:
			rare_seeds.append(seed)
	_expect(not template.visible, "RewardIconをテンプレートとして非表示にする")
	_expect(
		visible_icons.size() == mini(rare_seeds.size(), MAX_REWARD_SEED_ICONS),
		"エリアのレア夢の種を最大8個まで表示する"
	)
	var expected_seed_icon_count := (
		mini(rare_seeds.size(), MAX_REWARD_SEED_ICONS - 1)
		if rare_seeds.size() >= 9
		else rare_seeds.size()
	)
	for i in range(expected_seed_icon_count):
		_expect(
			visible_icons[i].texture == rare_seeds[i].tiny_texture,
			"レア夢の種のsmallテクスチャをアイコンへ設定する"
		)
	if rare_seeds.size() >= 9:
		_expect(
			visible_icons[7].texture == more_texture,
			"9個以上の場合は8個目にmoreアイコンを表示する"
		)

	var test_pool := SeedPoolInfo.new()
	var test_seed := SeedInfo.new()
	test_seed.rarity = SeedInfo.Rarity.RARE
	test_seed.tiny_texture = null
	test_pool.rare_skills = [
		test_seed, test_seed, test_seed, test_seed, test_seed, test_seed, test_seed, test_seed
	]
	choice._setup_reward_seed_icons(test_pool)
	_expect(_visible_icon_count(reward_container) == 8, "レア夢の種が8個なら通常アイコンを8個表示する")
	_expect(
		(reward_container.get_child(8) as TextureRect).texture == test_seed.tiny_texture,
		"レア夢の種が8個なら8個目も種アイコンを表示する"
	)
	test_pool.rare_skills.append(test_seed)
	choice._setup_reward_seed_icons(test_pool)
	_expect(_visible_icon_count(reward_container) == 8, "レア夢の種が9個なら表示を8アイコンに制限する")
	_expect(
		(reward_container.get_child(8) as TextureRect).texture == more_texture,
		"レア夢の種が9個なら8個目をmoreアイコンに置き換える"
	)
	_expect(reward_container.get_child_count() == 9, "9個目以降の種アイコンNodeを追加しない")

	choice.setup_choice(null)
	await process_frame
	_expect(reward_container.get_child_count() == 1, "再設定時に複製アイコンを残さない")

	root.remove_child(choice)
	choice.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageChoiceRewardIconTest: %s" % message)


func _visible_icon_count(container: HFlowContainer) -> int:
	var count := 0
	for child in container.get_children():
		if child is TextureRect and child.visible:
			count += 1
	return count
