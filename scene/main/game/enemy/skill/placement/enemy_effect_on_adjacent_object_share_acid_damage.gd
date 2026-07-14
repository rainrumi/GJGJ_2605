class_name EnemyEffectOnAdjacentObjectShareAcidDamage
extends EnemyEffectOnSelfBeforeAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_before_acid_damage(self)


var enemies: Array[Enemy] = [] # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()
	digestion_state = installer.get_digestion_state()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	digestion_state = null

# 自身を含む
@export var include_self := true
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) and EnemyEffectTargetQuery.get_adjacent_objects(source, enemies).size() >= minimum_count


# 効果適用
func apply() -> void:
	var targets := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 分配対象
	if include_self: targets.append(source)
	var split := int(get_activation_damage() / maxi(1, targets.size())) # 分配値
	for enemy in targets:
		if enemy != source: EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, split)
	set_activation_damage(split)
