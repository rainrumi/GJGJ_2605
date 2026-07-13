class_name EnemyEffectOnAdjacentObjectCountChangeSelfOrTargetAttack
extends EnemyEffect

# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.SELF
# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

