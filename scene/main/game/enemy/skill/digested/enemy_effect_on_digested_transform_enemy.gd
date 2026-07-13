class_name EnemyEffectOnDigestedTransformEnemy
extends EnemyEffect

# 次形態定義
@export var next_enemy_info: EnemyInfo
# 次形態スキル
@export var next_skill: EnemySkill
# 胃袋外へ出す
@export var remove_from_stomach := true

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.DIGESTED) and context.target == context.source: context.spawn_enemy(next_enemy_info, next_skill, 1, 1, SpawnArea.OUTSIDE_STOMACH if remove_from_stomach else SpawnArea.SAME_CELLS, -1, -1)
