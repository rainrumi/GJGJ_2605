class_name EnemyEffectOnAdjacentEmptyCellChangeTakenAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null

# マス毎差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	var count := EnemyEffectTargetQuery.get_open_adjacent_count(source, enemies, stomach) # 空隣接数
	EnemyEffectStatChanges.add_acid_damage_delta(source, source, damage_delta * count)
	EnemyEffectStatChanges.multiply_acid_damage(source, source, pow(damage_multiplier, count))
