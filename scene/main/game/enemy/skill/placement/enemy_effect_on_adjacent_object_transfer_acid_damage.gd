class_name EnemyEffectOnAdjacentObjectTransferAcidDamage
extends EnemyEffect

# 譲渡率
@export_range(0.0, 1.0, 0.01) var transfer_rate := 0.0
# 対象選択
@export var selection: EnemyEffect.AdjacentSelection = EnemyEffect.AdjacentSelection.ALL
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

