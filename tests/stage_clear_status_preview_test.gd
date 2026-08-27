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
		status_preview.position.is_equal_approx(Vector2(63.0, 122.0)),
		"状態予測の上端がSeedChoice1の上端にそろっている"
	)
	_expect(
		is_equal_approx(status_preview.position.y + status_preview.size.y, 348.0),
		"状態予測の下端がSeedChoice3の下端にそろっている"
	)

	var acid_damage_view := status_preview.get_node("AcidDamageRow/AcidDamageView") as AcidDamageView
	var acid_interval_view := status_preview.get_node("AcidIntervalRow/AcidIntervalView") as AcidIntervalView
	var hp_view := status_preview.get_node("HpRow/HpView") as StageClearHpView
	var hp_icon := status_preview.get_node("HpRow/HpView/Icon") as TextureRect
	var hp_value_label := status_preview.get_node("HpRow/HpView/Value") as Label
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
		hp_icon.texture.resource_path == "res://art/ui/icon/ui_icon_digestiveHP.png",
		"HP文字の代わりにHPアイコンを表示する"
	)
	_expect(hp_value_label.text == "70", "HPアイコンの横にクリア回復後HPを表示する")
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
		owned_seed_button.position.y + owned_seed_button.size.y < abandon_button.position.y,
		"Owned seed button is above abandon button"
	)
	_expect(
		debug_button.position.y + debug_button.size.y < owned_seed_button.position.y,
		"Debug button is above owned seed button"
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

	stage_clear.ui.seed_choice_hovered.emit(0)
	_expect(acid_damage_view.acid_damage_value_label.text == "55", "Preview damage replaces value")
	_expect(
		acid_damage_view.acid_damage_value_label.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"消化ダメージ増加を緑色で表示する"
	)
	stage_clear.ui.seed_choice_hovered.emit(1)
	_expect(hp_value_label.text == "80", "Preview HP replaces value")
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
	_expect(hp_value_label.text == "70", "ホバー終了時にHPを戻す")

	var lower_damage_info := {"total": 50, "base": 50, "seed_buff": 0, "seed_rate": 0.0, "enemy_buff": 0, "enemy_rate": 0.0}
	var longer_interval_info := {"total": 30, "base": 30, "seed_buff": 0, "seed_rate": 0.0, "enemy_buff": 0, "enemy_rate": 0.0}
	stage_clear.ui.set_status_preview(lower_damage_info, longer_interval_info, 70, 45, 31, 60)
	_expect(acid_damage_view.acid_damage_value_label.text == "45", "Lower preview damage replaces value")
	_expect(acid_interval_view.acid_interval_value_label.text == "31min", "Longer preview interval replaces value")
	_expect(hp_value_label.text == "60", "Lower preview HP replaces value")
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
