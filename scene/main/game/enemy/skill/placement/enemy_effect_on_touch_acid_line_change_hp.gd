class_name EnemyEffectOnTouchAcidLineChangeHp
extends EnemyEffect

# HP差分
@export var hp_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH):
		var active := 1 if context.get_acid_line_contact_count() > 0 else 0 # 接触状態
		var previous := context.get_state_int("active") # 直前状態
		context.set_state("active", active); context.change_hp(context.source, hp_delta * (active - previous))
