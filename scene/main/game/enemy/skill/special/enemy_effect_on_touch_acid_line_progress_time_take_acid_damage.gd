class_name EnemyEffectOnTouchAcidLineProgressTimeTakeAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var stomach: StomachBoard # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	stomach = installer.get_stomach()
	digestion_state = installer.get_digestion_state()


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null
	digestion_state = null

# 固定ダメージ
@export var damage := 0
# 接触毎ダメージ
@export var damage_per_contact := 0

# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, source, damage + damage_per_contact * EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach))
