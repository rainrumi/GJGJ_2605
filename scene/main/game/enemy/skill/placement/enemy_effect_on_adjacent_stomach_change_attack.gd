class_name EnemyEffectOnAdjacentStomachChangeAttack
extends EnemyEffect

# 接触毎差分
@export var attack_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.add_attack_delta(context.source, attack_delta * context.get_stomach_edge_contact_count())
