class_name EnemyEffectOnDigestedTransformEnemy
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_DIGESTED

# 次形態定義
@export var next_enemy_info: EnemyInfo
# 次形態スキル
@export var next_skill: EnemySkill
# 胃袋外へ出す
@export var remove_from_stomach := true

# 効果適用
func apply() -> void:
	if is_digested_activation() and get_activation_target() == source: spawn_enemy(next_enemy_info, next_skill, 1, 1, SpawnArea.OUTSIDE_STOMACH if remove_from_stomach else SpawnArea.SAME_CELLS, -1, -1)
