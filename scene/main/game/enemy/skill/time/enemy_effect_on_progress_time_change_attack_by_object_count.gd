class_name EnemyEffectOnProgressTimeChangeAttackByObjectCount
extends EnemyEffect

# モノ毎攻撃
@export var attack_per_object := 0
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.PROGRESS_TIME): return
	var count := runtime.get_active_objects().size() # モノ数
	if not include_self: count = maxi(0, count - 1)
	runtime.source.add_damage(attack_per_object * count - runtime.source.get_damage())
