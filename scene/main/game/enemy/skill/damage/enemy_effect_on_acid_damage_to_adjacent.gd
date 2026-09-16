class_name EnemyEffectOnAcidDamageToAdjacent
extends EnemyEffectOnSelfBeforeAcidDamage


var enemies: Array[Enemy] = [] # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	digestion_state = null


# 効果適用
func apply() -> void:
	var damage := get_activation_damage()
	if damage <= 0:
		return
	for enemy in EnemyEffectTargetQuery.get_adjacent_objects(source, enemies):
		EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, damage)
