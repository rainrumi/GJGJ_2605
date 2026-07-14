class_name EnemyEffectOnDigestionCountAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_any_digested(self)


var player_health: PlayerHealth # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	player_health = installer.get_player_health()


# 依存関係解除
func clear_dependencies() -> void:
	player_health = null

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply() -> void:
	var count := get_state_int("digestion_count") + get_activation_digested_enemies().size() # 消化数
	var triggers := int(count / required_count) # 発火数
	set_state("digestion_count", count % required_count)
	EnemyEffectBattleActions.attack_player(source, player_health, fixed_damage if fixed_damage > 0 else source.get_damage(), attack_count * triggers)
