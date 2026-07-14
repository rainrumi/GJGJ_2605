class_name EnemyEffectOnProgressTimeSpawnEnemy
extends EnemyEffectOnTimeProgressed


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var spawn_queue: EnemySpawnQueue # 効果依存


# 生成要求設定
func setup_spawn_queue(value: EnemySpawnQueue) -> void:
	spawn_queue = value


# 依存関係解除
func clear_dependencies() -> void:
	spawn_queue = null

# 生成敵定義
@export var enemy_info: EnemyInfo
# 生成スキル
@export var spawn_skill: EnemySkill
# 生成数
@export_range(1, 64, 1) var spawn_count := 1
# 生成上限
@export_range(0, 64, 1) var max_spawn_count := 0
# 生成範囲
@export var spawn_area: EnemyEffect.SpawnArea = EnemyEffect.SpawnArea.EMPTY_STOMACH
# 生成HP
@export var spawn_hp := -1
# 生成攻撃力
@export var spawn_attack := -1

# 効果適用
func apply() -> void:
	EnemyEffectWorldActions.spawn_enemy(self, spawn_queue, enemy_info, spawn_skill, spawn_count, max_spawn_count, spawn_area, spawn_hp, spawn_attack)
