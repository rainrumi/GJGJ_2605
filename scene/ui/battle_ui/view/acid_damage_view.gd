class_name AcidDamageView
extends TextureRect

signal tooltip_requested(view: AcidDamageView)
signal tooltip_hide_requested(view: AcidDamageView)

@onready var acid_damage_icon: Control = $AcidDamageView_icon
@onready var acid_damage_value_label: Label = $AcidDamageView_value
@onready var acid_damage_view_tooltip: AcidDamageViewTooltip = $AcidDamageView_tooltip


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# ダメージ情報設定
func set_damage_info(
	total_damage: int,
	base_damage: int,
	seed_buff: int,
	seed_rate: float,
	enemy_buff: int,
	enemy_rate: float
) -> void:
	set_damage(total_damage)
	acid_damage_view_tooltip.set_damage_info(total_damage, base_damage, seed_buff, seed_rate, enemy_buff, enemy_rate)


# ダメージ設定
func set_damage(total_damage: int) -> void:
	acid_damage_value_label.text = "%d" % total_damage


# ツール表示
func show_tooltip() -> void:
	acid_damage_view_tooltip.show_tooltip_at(global_position)


# ツール非表示
func hide_tooltip() -> void:
	acid_damage_view_tooltip.hide_tooltip()


# 入力準備
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	acid_damage_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	acid_damage_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# hover開始
func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)


# hover終了
func _on_mouse_exited() -> void:
	tooltip_hide_requested.emit(self)
