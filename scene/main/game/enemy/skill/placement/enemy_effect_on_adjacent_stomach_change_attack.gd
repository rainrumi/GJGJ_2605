class_name EnemyEffectOnAdjacentStomachChangeAttack
extends EnemyEffect

# 接触毎差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH): runtime.add_attack_delta(runtime.source, attack_delta * runtime.get_stomach_edge_contact_count())
