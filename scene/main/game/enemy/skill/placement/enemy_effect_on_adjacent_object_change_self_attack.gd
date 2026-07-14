class_name EnemyEffectOnAdjacentObjectChangeSelfAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 攻撃差分
@export var attack_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

# 効果適用
func apply() -> void:
	for _enemy in EnemyEffectTracking.get_activatable_new_adjacent(state, source, enemies, max_activations_per_target): source.add_damage(roundi(EnemyEffectValueCalculator.scale(source, float(attack_delta))))
