class_name EnemyEffectOnAdjacentObjectChangeSelfHp
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# HP差分
@export var hp_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

# 効果適用
func apply() -> void:
	for _enemy in EnemyEffectTracking.get_activatable_new_adjacent(state, source, enemies, max_activations_per_target): EnemyEffectStatChanges.change_hp(source, source, hp_delta)
