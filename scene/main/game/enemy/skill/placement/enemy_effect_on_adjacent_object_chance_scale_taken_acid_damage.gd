class_name EnemyEffectOnAdjacentObjectChanceScaleTakenAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_before_acid_damage(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	var target_enemy := get_activation_target_from(data) # 被弾対象
	return target_enemy != null \
		and EnemyEffectTargetQuery.get_adjacent_objects(source, enemies).has(target_enemy) \
		and EnemyEffectTargetQuery.get_adjacent_objects(source, enemies).size() >= required_count \
		and EnemyEffectValueCalculator.roll(source, chance)


# 効果適用
func apply() -> void:
	set_activation_damage(roundi(float(get_activation_damage()) * damage_multiplier))
