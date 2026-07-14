class_name EnemyEffectOnAdjacentObjectTransferAcidDamage
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

# 譲渡率
@export_range(0.0, 1.0, 0.01) var transfer_rate := 0.0
# 対象選択
@export var selection: EnemyEffect.AdjacentSelection = EnemyEffect.AdjacentSelection.ALL
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) and EnemyEffectTargetQuery.get_adjacent_objects(source, enemies).size() >= minimum_count


# 効果適用
func apply() -> void:
	var targets := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 譲渡対象
	if selection == AdjacentSelection.LOWEST_HP: targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_current_hp() < b.get_current_hp()); targets = [targets[0]]
	elif selection == AdjacentSelection.RANDOM_ONE: targets = [targets.pick_random()]
	var amount := roundi(float(get_activation_damage()) * transfer_rate / float(targets.size())) # 譲渡値
	for enemy in targets: EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, amount)
	set_activation_damage(maxi(0, get_activation_damage() - amount * targets.size()))
