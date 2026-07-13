class_name EnemyEffectOnStomachEdgeProgressTimeDealAcidDamage
extends EnemyEffect

# ダメージ
@export var damage := 0
# 対象選択
@export var selection: EnemyEffect.TargetSelection = EnemyEffect.TargetSelection.RANDOM_ONE
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

