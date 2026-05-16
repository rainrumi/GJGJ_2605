class_name HpTooltipView
extends LeftTooltipView


func _ready() -> void:
	super()
	set_title("HP(プレイヤー)")


func set_hp_info(
	current_hp: int,
	max_hp: int,
	rest_minutes: int,
	rest_hp_rate: float,
	rest_recovery_bonus_rate: float
) -> void:
	var rest_hp_percent := roundi(rest_hp_rate * 100.0)
	var rest_recovery_bonus_percent := roundi(rest_recovery_bonus_rate * 100.0)
	var total_rest_recovery_percent := rest_hp_percent + rest_recovery_bonus_percent
	set_entries([
		{
			"explanation": "ステータス",
			"value": "HP: %d/%d" % [current_hp, max_hp],
		},
		{
			"explanation": "蘇生回復量",
			"value": "最大HP%d%%(+%d%%)" % [rest_hp_percent, rest_recovery_bonus_percent],
		},
	])
	set_note(
		"HPが0になるとペナルティとして%d分経過し、HPを%d%%回復します。" % [rest_minutes, total_rest_recovery_percent],
		true
	)
