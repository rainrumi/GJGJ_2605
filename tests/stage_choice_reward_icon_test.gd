extends SceneTree

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
	_expect(visible_icons.size() == rare_seeds.size(), "エリアのレア夢の種だけアイコンを表示する")
	for i in range(mini(visible_icons.size(), rare_seeds.size())):
		_expect(
			visible_icons[i].texture == rare_seeds[i].tiny_texture,
			"レア夢の種のsmallテクスチャをアイコンへ設定する"
		)

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
