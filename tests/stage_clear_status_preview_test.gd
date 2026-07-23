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
	_expect(status_preview != null, "左上の状態予測が縦並びで配置されている")
	if status_preview == null:
		get_tree().quit(_failures)
		return

	var acid_damage_view := status_preview.get_node("AcidDamageRow/AcidDamageView") as AcidDamageView
	var acid_damage_delta := status_preview.get_node("AcidDamageRow/Delta") as Label
	var acid_interval_view := status_preview.get_node("AcidIntervalRow/AcidIntervalView") as AcidIntervalView
	var acid_interval_delta := status_preview.get_node("AcidIntervalRow/Delta") as Label
	var hp_view := status_preview.get_node("HpRow/HpView") as TextureRect
	var hp_icon := status_preview.get_node("HpRow/HpView/Icon") as TextureRect
	var hp_value_label := status_preview.get_node("HpRow/HpView/Value") as Label
	var hp_delta := status_preview.get_node("HpRow/Delta") as Label
	_expect(
		acid_damage_view.scene_file_path == "res://scene/ui/battle_ui/view/acid_damage_view.tscn",
		"戦闘画面と同じ消化ダメージ表示を使用する"
	)
	_expect(
		acid_interval_view.scene_file_path == "res://scene/ui/battle_ui/view/acid_interval_view.tscn",
		"戦闘画面と同じ消化間隔表示を使用する"
	)
	_expect(acid_damage_view.acid_damage_value_label.text == "50", "通常時の消化ダメージを表示する")
	_expect(acid_interval_view.acid_interval_value_label.text == "30min", "通常時の消化間隔を表示する")
	_expect(
		hp_icon.texture.resource_path == "res://art/ui/icon/ui_icon_digestiveHP.png",
		"HP文字の代わりにHPアイコンを表示する"
	)
	_expect(hp_value_label.text == "70", "HPアイコンの横にクリア回復後HPを表示する")
	_expect(acid_damage_delta.text.is_empty(), "通常時は消化ダメージ差分を表示しない")
	_expect(acid_interval_delta.text.is_empty(), "通常時は消化間隔差分を表示しない")
	_expect(hp_delta.text.is_empty(), "通常時はHP差分を表示しない")
	var character_hp_view := stage_clear.get_node("CharacterArea/HpView") as HpView
	character_hp_view.mouse_entered.emit()
	_expect(character_hp_view.hp_tooltip.visible, "HPバーのホバーでHPの説明を表示する")
	character_hp_view.mouse_exited.emit()
	_expect(hp_view.mouse_filter == Control.MOUSE_FILTER_STOP, "HP表示全体がマウスhoverを受け取る")
	_expect(hp_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HPアイコンがHP表示のhoverを妨げない")
	_expect(hp_value_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HP数値がHP表示のhoverを妨げない")
	hp_view.mouse_entered.emit()
	_expect(character_hp_view.hp_tooltip.visible, "HPアイコン表示のホバーでHPバーの説明を表示する")
	_expect(
		character_hp_view.hp_tooltip.tooltip_label.text.contains("HP: 20/100"),
		"HPバーと同じHP情報を表示する"
	)
	var expected_hp_tooltip_position := TooltipPositioner.get_tooltip_position(
		hp_view.global_position,
		character_hp_view.hp_tooltip.tooltip_panel.size,
		get_viewport().get_visible_rect(),
		LeftTooltip.TOOLTIP_OFFSET
	)
	_expect(
		character_hp_view.hp_tooltip.tooltip_panel.global_position.is_equal_approx(
			expected_hp_tooltip_position
		),
		"HPアイコン表示を基準にほかの状態ツールと同じ位置関係で表示する"
	)
	hp_view.mouse_exited.emit()
	_expect(not character_hp_view.hp_tooltip.visible, "HPアイコン表示のホバー終了でHPバーの説明を隠す")
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
	_expect(acid_damage_view.acid_damage_value_label.text == "50", "ホバー中も既存消化ダメージを維持する")
	_expect(acid_damage_delta.text == "(+5)", "消化ダメージ増加を差分表示する")
	_expect(
		acid_damage_delta.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"消化ダメージ増加を緑色で表示する"
	)
	stage_clear.ui.seed_choice_hovered.emit(1)
	_expect(hp_value_label.text == "70", "ホバー中も既存HPを維持する")
	_expect(hp_delta.text == "(+10)", "HP増加を差分表示する")
	_expect(
		hp_delta.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"HP増加を緑色で表示する"
	)
	stage_clear.ui.seed_choice_hovered.emit(2)
	_expect(acid_interval_view.acid_interval_value_label.text == "30min", "ホバー中も既存消化間隔を維持する")
	_expect(acid_interval_delta.text == "(-1)", "消化間隔減少を差分表示する")
	_expect(
		acid_interval_delta.get_theme_color("font_color") == StageClearUi.BENEFICIAL_DELTA_COLOR,
		"消化間隔減少を緑色で表示する"
	)
	stage_clear.ui.seed_choice_unhovered.emit()
	_expect(acid_damage_view.acid_damage_value_label.text == "50", "ホバー終了時に消化ダメージを戻す")
	_expect(acid_interval_view.acid_interval_value_label.text == "30min", "ホバー終了時に消化間隔を戻す")
	_expect(hp_value_label.text == "70", "ホバー終了時にHPを戻す")
	_expect(acid_damage_delta.text.is_empty(), "ホバー終了時に消化ダメージ差分を消す")
	_expect(acid_interval_delta.text.is_empty(), "ホバー終了時に消化間隔差分を消す")
	_expect(hp_delta.text.is_empty(), "ホバー終了時にHP差分を消す")

	var lower_damage_info := {"total": 50, "base": 50, "seed_buff": 0, "seed_rate": 0.0, "nightmare_buff": 0, "nightmare_rate": 0.0}
	var longer_interval_info := {"total": 30, "base": 30, "seed_buff": 0, "seed_rate": 0.0, "nightmare_buff": 0, "nightmare_rate": 0.0}
	stage_clear.ui.set_status_preview(lower_damage_info, longer_interval_info, 70, 45, 31, 60)
	_expect(acid_damage_delta.text == "(-5)", "消化ダメージ減少を差分表示する")
	_expect(acid_interval_delta.text == "(+1)", "消化間隔増加を差分表示する")
	_expect(hp_delta.text == "(-10)", "HP減少を差分表示する")
	_expect(
		acid_damage_delta.get_theme_color("font_color") == StageClearUi.HARMFUL_DELTA_COLOR,
		"消化ダメージ減少を赤色で表示する"
	)
	_expect(
		acid_interval_delta.get_theme_color("font_color") == StageClearUi.HARMFUL_DELTA_COLOR,
		"消化間隔増加を赤色で表示する"
	)
	_expect(
		hp_delta.get_theme_color("font_color") == StageClearUi.HARMFUL_DELTA_COLOR,
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
