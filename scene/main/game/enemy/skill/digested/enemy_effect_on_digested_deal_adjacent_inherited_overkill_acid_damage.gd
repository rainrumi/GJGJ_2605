class_name EnemyEffectOnDigestedDealAdjacentInheritedOverkillAcidDamage
extends EnemyEffectOnSelfDigested


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_digested(self)


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

# 超過倍率
@export var overkill_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target):
		EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, roundi(float(get_activation_overkill_damage()) * overkill_multiplier))
