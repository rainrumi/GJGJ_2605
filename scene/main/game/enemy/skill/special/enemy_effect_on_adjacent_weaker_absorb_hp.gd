class_name EnemyEffectOnAdjacentWeakerAbsorbHp
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


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

# 消化ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTracking.get_new_adjacent_objects(state, source, enemies):
		if enemy.get_damage() < source.get_damage(): EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, damage); source.heal(enemy.get_current_hp())
