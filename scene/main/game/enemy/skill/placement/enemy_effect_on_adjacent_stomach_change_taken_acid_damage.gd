class_name EnemyEffectOnAdjacentStomachChangeTakenAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null

# 接触毎差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	var count := EnemyEffectTargetQuery.get_stomach_edge_contact_count(source, stomach) # 接触数
	EnemyEffectStatChanges.add_acid_damage_delta(source, source, damage_delta * count)
	EnemyEffectStatChanges.multiply_acid_damage(source, source, pow(damage_multiplier, count))
