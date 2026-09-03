class_name EnemyEffectOnDigestionNotTouchAcidLineTakeAcidDamage
extends EnemyNodeEffect

var stomach: StomachBoard # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


# 発動Signal接続
func bind() -> void:
	if digestion_state != null:
		connect_trigger(digestion_state.acid_line_damage_started, _on_acid_line_damage_started)


# 消化ラインダメージ開始受信
func _on_acid_line_damage_started() -> void:
	queue_activation(EnemyEffectActivationData.new())


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null
	digestion_state = null


# 消化ダメージ
@export var damage := 0


# 効果適用
func apply() -> void:
	if not source.is_active_in_stomach():
		return
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0:
		return
	EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, source, damage)
