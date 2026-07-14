class_name EnemyEffectOnAcidDamageAcquireAttack
extends EnemyEffectOnSelfAfterAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_after_acid_damage(self)


var stomach: StomachBoard # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null

# 取得割合
@export var attack_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ライン接触必須
@export var require_acid_line_touch := false

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	if not super.accepts_activation(data):
		return false
	if require_acid_line_touch and EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) == 0:
		return false
	return EnemyEffectValueCalculator.roll(source, chance)


# 効果適用
func apply() -> void:
	source.add_damage(roundi(float(get_activation_damage()) * attack_rate))
