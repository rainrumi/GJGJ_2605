class_name EnemyEffectOnAdjacentObjectChangeTargetMaxHpAndHp
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

# 最大HP差分
@export var max_hp_delta := 0
# 現在HP差分
@export var hp_delta := 0

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTargetQuery.get_adjacent_objects(source, enemies): EnemyEffectStatChanges.add_max_hp_delta(source, enemy, max_hp_delta, false)
	for enemy in EnemyEffectTracking.get_new_adjacent_objects(state, source, enemies): EnemyEffectStatChanges.change_hp(source, enemy, hp_delta)
