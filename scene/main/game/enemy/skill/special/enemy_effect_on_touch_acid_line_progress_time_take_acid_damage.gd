class_name EnemyEffectOnTouchAcidLineProgressTimeTakeAcidDamage
extends EnemyEffect

# 固定ダメージ
@export var damage := 0
# 接触毎ダメージ
@export var damage_per_contact := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.PROGRESS_TIME): context.deal_acid_damage(context.source, damage + damage_per_contact * context.get_acid_line_contact_count())
