class_name EnemyDigestionInput
extends RefCounted

var enemies: Array[Enemy] = [] # 処理対象一覧
var stomach: StomachBoard # 胃袋盤面
var minutes := 0 # 現在分数
var elapsed_minutes := 0 # 経過分数
var acid_damage_per_cell := 0 # セル消化値


# 入力値設定
func setup(
	targets: Array[Enemy],
	board: StomachBoard,
	current_minutes: int,
	elapsed: int,
	per_cell: int
) -> void:
	enemies.assign(targets)
	stomach = board
	minutes = maxi(0, current_minutes)
	elapsed_minutes = maxi(0, elapsed)
	acid_damage_per_cell = maxi(0, per_cell)
