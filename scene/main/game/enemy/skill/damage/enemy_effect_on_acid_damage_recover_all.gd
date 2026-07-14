class_name EnemyEffectOnAcidDamageRecoverAll
extends EnemyEffectOnSelfAfterAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_after_acid_damage(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null

# 回復量
@export var recovery := 0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 効果適用
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) and EnemyEffectValueCalculator.roll(source, chance, invert_chance)


# 全体回復適用
func apply() -> void:
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target):
		EnemyEffectBattleActions.recover(source, enemy, recovery)
