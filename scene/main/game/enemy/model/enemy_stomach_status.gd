class_name EnemyStomachStatus
extends RefCounted

signal placement_changed(is_placed: bool)
signal digested
signal revived
signal elapsed_changed(minutes: int)
signal digestion_resolved(
	damage: int,
	overkill: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[EnemyData]
)

var is_digesting := false # 消化中
var is_digested := false # 消化済み
var gravity_locked := false # 重力固定
var activation_deferred := false # 起動保留
var cell := Vector2i.ZERO # 配置セル
var elapsed_minutes := 0 # 経過分数
var revive_count := 0 # 復活回数


# 状態初期化
func reset() -> void:
	is_digesting = false
	is_digested = false
	gravity_locked = false
	activation_deferred = false
	cell = Vector2i.ZERO
	elapsed_minutes = 0
	revive_count = 0
	placement_changed.emit(false)
	elapsed_changed.emit(elapsed_minutes)


# 消化中設定
func set_digesting(value: bool) -> void:
	if is_digesting != value:
		set_elapsed_minutes(0)
	is_digesting = value
	placement_changed.emit(is_digesting and not is_digested)


# 消化済み設定
func set_digested(value: bool) -> void:
	var was_digested := is_digested # 変更前状態
	is_digested = value
	if is_digested:
		is_digesting = false
		digested.emit()
	elif was_digested:
		revived.emit()
	placement_changed.emit(is_digesting and not is_digested)


# 経過分設定
func set_elapsed_minutes(value: int) -> void:
	elapsed_minutes = maxi(0, value)
	elapsed_changed.emit(elapsed_minutes)


# 経過分追加
func add_elapsed_minutes(value: int) -> void:
	set_elapsed_minutes(elapsed_minutes + value)


# 復活記録
func record_revive() -> void:
	revive_count += 1


# 消化結果通知
func publish_digestion(
	damage: int,
	overkill: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_enemies: Array[EnemyData]
) -> void:
	digestion_resolved.emit(
		maxi(0, damage),
		maxi(0, overkill),
		maxi(0, elapsed_seconds),
		maxi(0, current_seconds),
		digested_enemies
	)
