class_name GameConfirmationDialog
extends CanvasLayer

signal confirmed
signal canceled

@onready var message_label: Label = $Screen/Center/Panel/Margin/Content/Message
@onready var confirm_button: Button = $Screen/Center/Panel/Margin/Content/Buttons/ConfirmButton
@onready var cancel_button: Button = $Screen/Center/Panel/Margin/Content/Buttons/CancelButton


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func open_dialog(message: String, confirm_text: String = "はい", cancel_text: String = "いいえ") -> void:
	message_label.text = message
	confirm_button.text = confirm_text
	cancel_button.text = cancel_text
	visible = true
	confirm_button.grab_focus()


func _on_confirm_pressed() -> void:
	visible = false
	confirmed.emit()


func _on_cancel_pressed() -> void:
	visible = false
	canceled.emit()
