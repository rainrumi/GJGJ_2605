extends Node2D

@onready var ui: CanvasLayer = $UI


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_sync_ui_visibility()


func _on_visibility_changed() -> void:
	_sync_ui_visibility()


func _sync_ui_visibility() -> void:
	if ui == null:
		return
	ui.visible = visible
