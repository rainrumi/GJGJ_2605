extends Node

const STAGE_CLEAR_SCENE_PATH := "res://scene/main/stage_clear/stage_clear.tscn"

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_clear_packed := load(STAGE_CLEAR_SCENE_PATH) as PackedScene
	_expect(stage_clear_packed != null, "ステージクリアSceneを読み込める")
	if stage_clear_packed == null:
		get_tree().quit(_failures)
		return
	var stage_clear := stage_clear_packed.instantiate()
	add_child(stage_clear)
	await get_tree().process_frame
	stage_clear.setup_clear_result(20, 22 * 60)

	var status_preview := stage_clear.get_node("UI/StatusPreview") as VBoxContainer
	_expect(status_preview != null, "状態予測が縦並びで配置されている")
	if status_preview == null:
		get_tree().quit(_failures)
		return
	_expect(
		status_preview.position.is_equal_approx(Vector2(34.0, 41.0)),
		"状態予測が左上の所定位置に配置されている"
	)
	_expect(
		is_equal_approx(status_preview.position.y + status_preview.size.y, 191.0),
		"状態予測が所定の高さで表示されている"
	)

	var acid_damage_view := status_preview.get_node("AcidDamageView") as AcidDamageView
	var acid_interval_view := status_preview.get_node("AcidIntervalView") as AcidIntervalView
	var hp_view := status_preview.get_node("HpView") as StageClearHpView
	for view: Control in [acid_damage_view, acid_interval_view, hp_view]:
		_expect(view.get_parent() == status_preview, "%s is a direct child of StatusPreview" % view.name)
		_expect(
			view.size_flags_horizontal == Control.SIZE_SHRINK_CENTER,
			"%s uses horizontal center sizing" % view.name
		)
		_expect(
			is_equal_approx(view.position.x + view.size.x * 0.5, status_preview.size.x * 0.5),
			"%s is horizontally centered in StatusPreview" % view.name
		)
	var hp_icon := status_preview.get_node("HpView/Icon") as TextureRect
	var hp_value_label := status_preview.get_node("HpView/Value") as Label
	_expect(status_preview.get_node_or_null("AcidDamageRow/Delta") == null, "AcidDamage Delta removed")
	_expect(status_preview.get_node_or_null("AcidIntervalRow/Delta") == null, "AcidInterval Delta removed")
	_expect(status_preview.get_node_or_null("HpRow/Delta") == null, "HP Delta removed")
	_expect(
		acid_damage_view.scene_file_path == "res://scene/ui/battle_ui/view/acid_damage_view.tscn",
		"戦闘画面と同じ消化ダメージ表示を使用する"
	)
	_expect(
		acid_interval_view.scene_file_path == "res://scene/ui/battle_ui/view/acid_interval_view.tscn",
		"戦闘画面と同じ消化間隔表示を使用する"
	)
	_expect(
		hp_view.scene_file_path == "res://scene/ui/battle_ui/view/hp_view.tscn",
		"戦闘画面の表示部品と同じ配置規約でHP表示を使用する"
	)
	_expect(acid_damage_view.acid_damage_value_label.text == "50", "通常時の消化ダメージを表示する")
	_expect(acid_interval_view.acid_interval_value_label.text == "30min", "通常時の消化間隔を表示する")
	_expect(
		hp_icon.texture.resource_path == "res://resource/image/ui/icon/ui_icon_digestiveHP.png",
		"HP文字の代わりにHPアイコンを表示する"
	)
	_expect(hp_value_label.text == "70/100", "HPアイコンの横に現在HP/最大HPを表示する")
	_expect(hp_view.mouse_filter == Control.MOUSE_FILTER_STOP, "HP表示全体がマウスhoverを受け取る")
	_expect(hp_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HPアイコンがHP表示のhoverを妨げない")
	_expect(hp_value_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HP数値がHP表示のhoverを妨げない")
	_expect(
		stage_clear.get_node_or_null("CharacterArea/HpView") == null,
		"ステージクリア画面ではStatusPreview以外のHPバーを表示しない"
	)
	_expect(
		stage_clear.get_node_or_null("UI/OwnedSeedOpenButton") != null,
		"ステージクリア画面に所持中の夢の種ボタンを表示する"
	)
	var owned_seed_button := stage_clear.get_node("UI/OwnedSeedOpenButton") as TextureButton
	var debug_button := stage_clear.get_node("UI/DebugButton") as Button
	var abandon_button := stage_clear.get_node("UI/AbandonButton") as Button
	_expect(
		owned_seed_button.position.x + owned_seed_button.size.x < abandon_button.position.x,
		"Owned seed button is left of abandon button"
	)
	_expect(
		owned_seed_button.position.y + owned_seed_button.size.y < debug_button.position.y,
		"Debug button is below owned seed button"
	)
	acid_damage_view.mouse_entered.emit()
	_expect(acid_damage_view.acid_damage_view_tooltip.visible, "消化ダメージの説明をホバー表示する")
	_expect(
		acid_damage_view.acid_damage_view_tooltip.tooltip_label.text.contains("消化ダメージ"),
		"消化ダメージの説明文を表示する"
	)
	acid_damage_view.mouse_exited.emit()
	acid_interval_view.mouse_entered.emit()
	_expect(acid_interval_view.acid_interval_view_tooltip.visible, "消化間隔の説明をホバー表示する")
	_expect(
		acid_interval_view.acid_interval_view_tooltip.tooltip_label.text.contains("消化ダメージを与えます"),
		"消化間隔の説明文を表示する"
	)
	acid_interval_view.mouse_exited.emit()
	hp_view.mouse_entered.emit()
	_expect(hp_view.hp_tooltip.visible, "HPの説明をホバー表示する")
	_expect(
		hp_view.hp_tooltip.tooltip_label.text.contains("HP: 70/100"),
		"ゲーム画面と同じ現在HPと最大HPを表示する"
	)
	_expect(hp_view.hp_tooltip.tooltip_label.text.contains("10%"), "ゲーム画面と同じ休憩回復率を表示する")
	hp_view.mouse_exited.emit()
	_expect(not hp_view.hp_tooltip.visible, "HPのホバー終了時に説明を隠す")

	stage_clear.ui.seed_choice_hovered.emit(0)
	_expect(acid_damage_view.acid_damage_value_label.text == "55", "Preview damage replaces value")
	_expect(
		acid_damage_view.acid_damage_value_label.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"消化ダメージ増加を緑色で表示する"
	)
	stage_clear.ui.seed_choice_hovered.emit(1)
	_expect(hp_value_label.text == "80/100", "Preview HP replaces current value and keeps max value")
	_expect(
		hp_value_label.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"HP増加を緑色で表示する"
	)
	stage_clear.ui.seed_choice_hovered.emit(2)
	_expect(acid_interval_view.acid_interval_value_label.text == "29min", "Preview interval replaces value")
	_expect(
		acid_interval_view.acid_interval_value_label.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"消化間隔減少を緑色で表示する"
	)
	stage_clear.ui.seed_choice_unhovered.emit()
	_expect(acid_damage_view.acid_damage_value_label.text == "50", "ホバー終了時に消化ダメージを戻す")
	_expect(acid_interval_view.acid_interval_value_label.text == "30min", "ホバー終了時に消化間隔を戻す")
	_expect(hp_value_label.text == "70/100", "ホバー終了時に現在HP/最大HPを戻す")
	_expect(
		hp_value_label.get_theme_color("font_color") == Color(0.94, 0.88, 1.0, 1.0),
		"HPの通常文字色をHpViewシーンのエディター設定へ戻す"
	)

	var conditional_acid := SeedEffectOnAcidDamageChangeAcidDamageRateByStomachCount.new()
	conditional_acid.rate = 0.5
	conditional_acid.max_stomach_count = 99
	var conditional_interval := SeedEffectOnTargetClockChangeTimeReductionRateAfterClock.new()
	conditional_interval.rate = 0.5
	conditional_interval.start_minutes = 0
	var conditional_hp := SeedEffectOnSelectedRewerdChangeHpAfterClock.new()
	conditional_hp.recovery_rate = 0.2
	conditional_hp.start_minutes = 0
	var unconditional_acid := SeedEffectOnBattleChangeAcidDamageRate.new()
	unconditional_acid.rate = 0.1
	var mixed_skill := SeedSkill.new()
	mixed_skill.effects.assign([
		conditional_acid,
		conditional_interval,
		conditional_hp,
		unconditional_acid,
	])
	var mixed_seed := SeedInfo.new()
	mixed_seed.main_skill = mixed_skill
	stage_clear.seed_options.assign([mixed_seed])
	stage_clear.ui.seed_choice_hovered.emit(0)
	_expect(
		acid_damage_view.acid_damage_value_label.text == "55",
		"hover preview includes the unconditional damage effect"
	)
	_expect(
		acid_interval_view.acid_interval_value_label.text == "30min",
		"hover preview excludes the clock-conditioned interval effect"
	)
	_expect(
		hp_value_label.text == "70/100",
		"hover preview excludes the clock-conditioned HP effect"
	)
	stage_clear.ui.seed_choice_unhovered.emit()
	stage_clear.seed_options.clear()
	mixed_skill.effects.clear()
	mixed_seed = null
	mixed_skill = null
	conditional_acid = null
	conditional_interval = null
	conditional_hp = null
	unconditional_acid = null

	var lower_damage_info := {"total": 50, "base": 50, "seed_buff": 0, "seed_rate": 0.0, "enemy_buff": 0, "enemy_rate": 0.0}
	var longer_interval_info := {"total": 30, "base": 30, "seed_buff": 0, "seed_rate": 0.0, "enemy_buff": 0, "enemy_rate": 0.0}
	stage_clear.ui.set_status_preview(
		lower_damage_info,
		longer_interval_info,
		70,
		45,
		31,
		60,
		100,
		30,
		0.1,
		0.0
	)
	_expect(acid_damage_view.acid_damage_value_label.text == "45", "Lower preview damage replaces value")
	_expect(acid_interval_view.acid_interval_value_label.text == "31min", "Longer preview interval replaces value")
	_expect(hp_value_label.text == "60/100", "Lower preview HP replaces current value and keeps max value")
	_expect(
		acid_damage_view.acid_damage_value_label.get_theme_color("font_color") == StageClearUi.HARMFUL_DELTA_COLOR,
		"消化ダメージ減少を赤色で表示する"
	)
	_expect(
		acid_interval_view.acid_interval_value_label.get_theme_color("font_color") == StageClearUi.HARMFUL_DELTA_COLOR,
		"消化間隔増加を赤色で表示する"
	)
	_expect(
		hp_value_label.get_theme_color("font_color") == StageClearUi.HARMFUL_DELTA_COLOR,
		"HP減少を赤色で表示する"
	)

	remove_child(stage_clear)
	stage_clear.free()
	stage_clear_packed = null
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageClearStatusPreviewTest: %s" % message)
