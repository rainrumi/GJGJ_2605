class_name EnemyEffectOnClockCountGrantAdjacentGuard
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 無効回数
@export_range(1, 64, 1) var guard_count := 1
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

