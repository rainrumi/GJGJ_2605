class_name EnemyEffectOnClockCountTakeAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var digestion_state: EnemyDigestionState # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	digestion_state = installer.get_digestion_state()


# 依存関係解除
func clear_dependencies() -> void:
	digestion_state = null

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	var count := get_state_int("clock_count") + 1 # 時刻回数
	set_state("clock_count", count % required_count)
	if count >= required_count: EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, source, damage)
