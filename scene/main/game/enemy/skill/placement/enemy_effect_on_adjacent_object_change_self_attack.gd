class_name EnemyEffectOnAdjacentObjectChangeSelfAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

