class_name EnemyEffectOnElapsedTimeTakeAcidDamage
extends EnemyEffectOnTimeProgressed



var digestion_state: EnemyDigestionState # 効果依存


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


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
