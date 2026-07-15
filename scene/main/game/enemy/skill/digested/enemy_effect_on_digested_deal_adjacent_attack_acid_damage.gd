class_name EnemyEffectOnDigestedDealAdjacentAttackAcidDamage
extends EnemyEffectOnSelfDigested



var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null
	digestion_state = null

# 攻撃倍率
@export var attack_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target):
		EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, roundi(float(source.get_damage()) * attack_multiplier))
