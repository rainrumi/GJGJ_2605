class_name EnemyEffectOnProgressTimeChangeAttackByObjectCount
extends EnemyEffect

# モノ毎攻撃
@export var attack_per_object := 0
# 自身を含む
@export var include_self := true

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.get_active_objects().size() # モノ数
	if not include_self: count = maxi(0, count - 1)
	context.source.add_damage(attack_per_object * count - context.source.get_damage())
