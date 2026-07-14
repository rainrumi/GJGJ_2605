class_name EnemyEffectOnDigestedTransformEnemy
extends EnemyEffectOnSelfDigested


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_digested(self)


var spawn_queue: EnemySpawnQueue # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	spawn_queue = installer.get_spawn_queue()


# 依存関係解除
func clear_dependencies() -> void:
	spawn_queue = null

# 次形態定義
@export var next_enemy_info: EnemyInfo
# 次形態スキル
@export var next_skill: EnemySkill
# 胃袋外へ出す
@export var remove_from_stomach := true

# 効果適用
func apply() -> void:
	EnemyEffectWorldActions.spawn_enemy(self, spawn_queue, next_enemy_info, next_skill, 1, 1, SpawnArea.OUTSIDE_STOMACH if remove_from_stomach else SpawnArea.SAME_CELLS, -1, -1)
