class_name NightmareTooltipView
extends Panel

const EFFECT_ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const EFFECT_EMPTY_COLOR := Color(0.2666667, 0.2666667, 0.2666667, 1.0)

@onready var name_label: Label = $Content/NameLabel
@onready var debug_number_label: Label = $Content/DebugNumberLabel
@onready var category_label: Label = $Content/CategoryLabel
@onready var category_detail_label: Label = $Content/CategoryDetailLabel
@onready var status_title_label: Label = $Content/StatusTitleLabel
@onready var hp_label: Label = $Content/HpLabel
@onready var damage_label: Label = $Content/DamageLabel
@onready var main_effect_title_label: Label = $Content/MainEffectTitleLabel
@onready var main_effect_label: Label = $Content/MainEffectLabel
@onready var sub_effect_title_label: Label = $Content/SubEffectTitleLabel
@onready var sub_effect_label: Label = $Content/SubEffectLabel


func show_enemy(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	var main_effect_text := enemy.get_main_effect_text()
	var sub_effect_text := enemy.get_sub_effect_text()
	name_label.text = enemy.get_display_name()
	debug_number_label.text = debug_number_text
	debug_number_label.visible = debug_numbers_visible
	category_label.text = enemy.get_category_name()
	category_detail_label.text = enemy.get_category_detail()
	_update_optional_text_color(category_label, category_detail_label, category_label.text)
	status_title_label.text = "ステータス"
	hp_label.text = "HP: %d" % enemy.max_hp
	damage_label.text = "攻撃力: %d" % enemy.get_damage()
	main_effect_title_label.text = "メイン効果"
	main_effect_label.text = _get_effect_text(main_effect_text)
	sub_effect_title_label.text = "サブ効果"
	sub_effect_label.text = _get_effect_text(sub_effect_text)
	_update_optional_text_color(main_effect_title_label, main_effect_label, main_effect_text)
	_update_optional_text_color(sub_effect_title_label, sub_effect_label, sub_effect_text)
	visible = true


func hide_tooltip() -> void:
	visible = false
	debug_number_label.visible = false


func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_number_label.visible = visible and is_visible


func _get_effect_text(text: String) -> String:
	if text.is_empty():
		return "-"
	return text


func _update_optional_text_color(title_label: Label, detail_label: Label, text: String) -> void:
	var effect_color := EFFECT_ACTIVE_COLOR
	if text.is_empty() or text == "-":
		effect_color = EFFECT_EMPTY_COLOR
	title_label.add_theme_color_override("font_color", effect_color)
	detail_label.add_theme_color_override("font_color", effect_color)
