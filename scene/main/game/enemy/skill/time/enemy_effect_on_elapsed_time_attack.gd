class_name EnemyEffectOnElapsedTimeAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_default_attack_refresh(self, suppress_default_attack)
	installer.connect_progress_time(self)


var player_health: PlayerHealth # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	player_health = installer.get_player_health()


# 依存関係解除
func clear_dependencies() -> void:
	player_health = null

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0
# 通常攻撃停止
@export var suppress_default_attack := false
# ダメージ参照元
@export var damage_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.SELF_ATTACK

# 効果適用
func apply() -> void:
	var triggers := consume_interval(interval_seconds) # 発火数
	EnemyEffectBattleActions.attack_player(source, player_health, resolve_value(damage_source, fixed_damage), attack_count * triggers)
