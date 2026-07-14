class_name EnemyEffectOnAcidDamageCountAttack
extends EnemyEffectOnSelfAfterAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_after_acid_damage(self)


var player_health: PlayerHealth # 効果依存


# プレイヤーHP設定
func setup_player_health(value: PlayerHealth) -> void:
	player_health = value


# 依存関係解除
func clear_dependencies() -> void:
	player_health = null

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	var count := get_state_int("hit_count") + 1 # 被弾数
	set_state("hit_count", count % required_count)
	if count >= required_count: EnemyEffectBattleActions.attack_player(source, player_health, fixed_damage if fixed_damage > 0 else source.get_damage(), attack_count)
