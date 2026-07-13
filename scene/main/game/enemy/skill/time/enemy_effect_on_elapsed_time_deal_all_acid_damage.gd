class_name EnemyEffectOnElapsedTimeDealAllAcidDamage
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS
# ダメージ
@export var damage := 0
# 攻撃回数
@export_range(1, 64, 1) var hit_count := 1

