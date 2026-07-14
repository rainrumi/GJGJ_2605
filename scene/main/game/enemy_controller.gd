class_name EnemyController
extends RefCounted

const STEP_MINUTES := 30
const ACID_DAMAGE := 300

var digestion_resolver: EnemyDigestionResolver # 消化処理
var digestion_processor: EnemyDigestionProcessor # 消化進行
var attack_resolver: EnemyAttackResolver # 攻撃処理
var turn_processor: EnemyTurnProcessor # ターン処理
var enemy_effects: EnemyEffectSystem # 効果窓口


# 依存関係設定
func setup(
	digestion: EnemyDigestionResolver,
	attack: EnemyAttackResolver,
	turns: EnemyTurnProcessor,
	effects: EnemyEffectSystem,
	processor: EnemyDigestionProcessor = null
) -> void:
	digestion_resolver = digestion
	digestion_processor = processor
	attack_resolver = attack
	turn_processor = turns
	enemy_effects = effects


# 開始分設定
func set_battle_start_minutes(value: int) -> void:
	attack_resolver.set_battle_start_minutes(value)
	turn_processor.set_battle_start_minutes(value)


# 効果状態初期化
func reset_enemy_effects() -> void:
	enemy_effects.reset()


# 敵効果更新
func refresh_enemy_effects(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	enemy_effects.refresh(enemies, stomach)


# ターン処理実行
func process_turn(input: EnemyTurnInput) -> BattleTurnResultData:
	turn_processor.begin_turn(input.enemies, input.stomach, input.minutes)
	var digested := acid_nightmares(
		input.enemies,
		input.stomach,
		input.minutes,
		input.elapsed_minutes
	) # 消化済み一覧
	var attack_values := attack_resolver.resolve(input.enemies, input.stomach, input.minutes) # 敵攻撃一覧
	var result := turn_processor.build_result(digested) # ターン結果
	result.player_damage_values = attack_values
	return result


# 消化内訳取得
func get_acid_damage_breakdown(
	enemies: Array[Enemy],
	minutes: int,
	consume_pending_bonus := false,
	stomach: StomachBoard = null
) -> Dictionary:
	return digestion_resolver.get_damage_breakdown(
		enemies,
		minutes,
		ACID_DAMAGE,
		consume_pending_bonus,
		stomach
	)


# 進行分取得
func get_step_minutes(enemies: Array[Enemy], minutes := 0) -> int:
	return turn_processor.get_step_minutes(enemies, minutes)


# 基準分取得
func get_base_step_minutes() -> int:
	return turn_processor.get_base_step_minutes()


# 進行内訳取得
func get_step_minutes_breakdown(
	enemies: Array[Enemy],
	consume_pending_bonus := false,
	minutes := 0
) -> Dictionary:
	return turn_processor.get_step_minutes_breakdown(enemies, consume_pending_bonus, minutes)


# ターン開始処理
func apply_turn_start_effects(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> void:
	turn_processor.begin_turn(enemies, stomach, minutes)


# 消化処理解決
func acid_nightmares(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	elapsed_minutes: int = STEP_MINUTES
) -> Array[Enemy]:
	var per_cell := int(get_acid_damage_breakdown(enemies, minutes, true, stomach)["total"]) # セル消化値
	var input := EnemyDigestionInput.new() # 消化入力
	input.setup(enemies, stomach, minutes, elapsed_minutes, per_cell)
	if digestion_processor == null:
		return digestion_resolver.resolve(input).digested_enemies
	return digestion_processor.process(input).digested_enemies


# 敵攻撃解決
func resolve_enemy_attacks(enemies: Array[Enemy], stomach: StomachBoard, minutes: int) -> Array[int]:
	return attack_resolver.resolve(enemies, stomach, minutes)


# 時間進行処理
func apply_progress_time(
	previous_minutes: int,
	minutes: int,
	enemies: Array[Enemy],
	stomach: StomachBoard
) -> BattleTurnResultData:
	return turn_processor.progress_time(previous_minutes, minutes, enemies, stomach)


# ターン結果構築
func build_turn_result(digested_enemies: Array[Enemy]) -> BattleTurnResultData:
	return turn_processor.build_result(digested_enemies)


# 遅延敵有効化
func activate_deferred_nuisance_enemies(enemies: Array[Enemy]) -> void:
	turn_processor.activate_deferred_enemies(enemies)


# 遅延重力解除
func unlock_deferred_nuisance_gravity(enemies: Array[Enemy]) -> void:
	turn_processor.unlock_deferred_gravity(enemies)
