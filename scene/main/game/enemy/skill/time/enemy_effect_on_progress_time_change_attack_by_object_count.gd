class_name EnemyEffectOnProgressTimeChangeAttackByObjectCount
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# モノ毎攻撃
@export var attack_per_object := 0
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	if not is_progress_time_activation(): return
	var count := get_active_objects().size() # モノ数
	if not include_self: count = maxi(0, count - 1)
	source.add_damage(attack_per_object * count - source.get_damage())
