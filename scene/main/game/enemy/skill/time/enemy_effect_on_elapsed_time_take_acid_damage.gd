class_name EnemyEffectOnElapsedTimeTakeAcidDamage
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

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# ダメージ
@export var damage := 0

# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, source, damage, consume_interval(interval_seconds))
