class_name EnemyEffectOnAdjacentObjectChangeTargetHp
extends EnemyEffectOnRefresh



var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# HP差分
@export var hp_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTracking.get_activatable_new_adjacent(state, source, enemies, max_activations_per_target): EnemyEffectStatChanges.change_hp(source, enemy, hp_delta)
