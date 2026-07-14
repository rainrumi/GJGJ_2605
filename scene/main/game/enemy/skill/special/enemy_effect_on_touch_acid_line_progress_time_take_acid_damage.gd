class_name EnemyEffectOnTouchAcidLineProgressTimeTakeAcidDamage
extends EnemyEffect

# 固定ダメージ
@export var damage := 0
# 接触毎ダメージ
@export var damage_per_contact := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.PROGRESS_TIME): runtime.deal_acid_damage(runtime.source, damage + damage_per_contact * runtime.get_acid_line_contact_count())
