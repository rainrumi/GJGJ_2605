class_name EnemyEffectOnAdjacentWeakerAbsorbAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


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

# 消化ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTracking.get_new_adjacent_objects(state, source, enemies):
		if enemy.get_damage() < source.get_damage(): EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, damage); source.add_damage(enemy.get_damage())
