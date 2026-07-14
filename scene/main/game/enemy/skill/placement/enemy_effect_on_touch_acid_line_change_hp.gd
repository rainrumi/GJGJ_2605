class_name EnemyEffectOnTouchAcidLineChangeHp
extends EnemyEffect

# HP差分
@export var hp_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH):
		var active := 1 if runtime.get_acid_line_contact_count() > 0 else 0 # 接触状態
		var previous := runtime.get_state_int("active") # 直前状態
		runtime.set_state("active", active); runtime.change_hp(runtime.source, hp_delta * (active - previous))
