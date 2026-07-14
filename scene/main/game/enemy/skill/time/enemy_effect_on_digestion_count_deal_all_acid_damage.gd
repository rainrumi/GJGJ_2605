class_name EnemyEffectOnDigestionCountDealAllAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_any_digested(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()
	stomach = installer.get_stomach()
	digestion_state = installer.get_digestion_state()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null
	digestion_state = null

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ
@export var damage := 0
# 攻撃回数
@export_range(1, 64, 1) var hit_count := 1
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

# 効果適用
func apply() -> void:
	var count := get_state_int("digestion_count") + get_activation_digested_enemies().size() # 消化数
	var triggers := int(count / required_count) # 発火数
	set_state("digestion_count", count % required_count)
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target): EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, damage, hit_count * triggers)
