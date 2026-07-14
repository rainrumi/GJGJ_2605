class_name EnemyEffectOnElapsedTimeGrantExtraAttack
extends EnemyEffectOnTimeProgressed


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_default_attack_refresh(self, suppress_default_attack)
	installer.connect_progress_time(self)


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

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS
# 追加攻撃数
@export_range(1, 64, 1) var extra_attack_count := 1
# 重複上限
@export_range(0, 64, 1) var stack_limit := 1
# 通常攻撃停止
@export var suppress_default_attack := false

# 効果適用
func apply() -> void:
	var count := consume_interval(interval_seconds) # 発火数
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target): EnemyEffectStatChanges.add_extra_attacks(enemy, mini(stack_limit, extra_attack_count * count))
