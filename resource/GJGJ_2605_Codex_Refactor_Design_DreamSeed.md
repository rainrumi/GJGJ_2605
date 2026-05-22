# GJGJ_2605 リファクタリング設計書 for Codex

## 目的

この文書は、Godot プロジェクト `GJGJ_2605` の現在の問題点を、Codex に段階的に修正させるための設計書である。

今回の対象は、主に以下の設計改善である。

```text
1. Game.gd の多責務化を抑える
2. 夢の種ドラッグ機能を専用 Controller へ分離する
3. 夢の種ブロックと悪夢 Enemy の境界を明確化する
4. 夢の種 stock の所有者を UI から Runtime State へ寄せる
5. StageClear.gd の肥大化を抑える
6. 残っているマジックナンバーを定数化する
```

この作業は、ゲーム内容の大幅追加ではなく、既存機能を壊さずに長期開発しやすい構造へ整えることを目的とする。

---

## 重要方針

- 既存の見た目、操作感、ゲームテンポ、文言を不用意に変えない。
- 夢の種ドラッグ機能は開発途中として扱う。
- 開発途中機能を無理に完成させるのではなく、今後実装しやすい責務分離にする。
- `.tscn` / `.tres` の編集は必要最小限にする。
- 大規模な一括リファクタリングではなく、Phase ごとに小さく安全に変更する。
- 変更後は Godot で開ける状態を維持する。
- `.godot/` は編集しない。
- ゲームバランス変更とリファクタリングを同時に行わない。

---

## 明示的な非対象

以下は今回の作業対象にしない。

```text
- タイトル画面の未実装ボタンの完成
- プレイヤー向け status message の動的表示追加
- ゲーム画面への PassiveFlowerSpawner 表示復活
- UI レイアウトやアートの大幅変更
- 夢の種ドラッグ機能の最終仕様確定
- セーブ機能の実装
```

---

# 現状の主な問題

## 問題 1: Game.gd が再び多責務化している

### 現状

`Game.gd` は戦闘司令塔としての責務に加え、現在は夢の種ドラッグ関連の実処理も抱えている。

主な責務:

```text
- 戦闘開始
- 敵ドラッグ
- 夢の種ドラッグ
- 夢の種ブロック生成
- 夢の種ブロック配置
- stock 消費要求
- 消化ターン進行
- HP / 時間管理
- UI 更新
- Debug seed 追加
- BGM同期の受け渡し
```

### 問題

`GameDreamSeedController` が存在しているにもかかわらず、`Game.gd` 側に次のような夢の種ドラッグ状態が残っている。

```gdscript
var dragging_seed_block: Enemy
var dragging_seed_button: DreamSeedSkillButton
```

また、以下のような夢の種ドラッグ用関数が `Game.gd` に残っている。

```gdscript
func _on_seed_skill_drag_started(...)
func _on_seed_skill_drag_moved(...)
func _on_seed_skill_drag_released(...)
func _on_seed_skill_activation_requested(...)
```

### 改善方針

夢の種ドラッグ状態と処理を `GameDreamSeedController` へ移動する。

`Game.gd` は以下だけを担当する。

```text
- 戦闘中かどうかの大枠判定
- Controller への委譲
- SE再生
- 自動消化 pause / resume
- UI refresh
```

---

# Phase 1: GameDreamSeedController へドラッグ状態を移す

## 目的

夢の種ドラッグ処理を `Game.gd` から切り離し、夢の種専用 Controller へ責務を寄せる。

## 対象候補ファイル

```text
scene/main/game/game.gd
scene/main/game/game_dream_seed_controller.gd
scene/ui/battle_ui/battle_ui.gd
scene/ui/dream_seed_skill_button/dream_seed_skill_button.gd
scene/ui/dream_seed_skill_button/dream_seed_skill_button_list.gd
```

## 追加候補: DreamSeedDragResult

新規ファイル候補:

```text
scene/main/game/dream_seed_drag_result.gd
```

内容例:

```gdscript
class_name DreamSeedDragResult
extends RefCounted

var started := false
var placed := false
var cancelled := false
var seed_block: Enemy
var source_button: DreamSeedSkillButton
var source: Resource
var seed_skill: DreamSeedSkillDefinition
```

## GameDreamSeedController の推奨 API

```gdscript
class_name GameDreamSeedController
extends RefCounted

func setup(
	owner: Node,
	stomach: StomachBoard,
	input_controller: GameInputController,
	enemy_definitions: Array[Resource]
) -> void:
	...

func set_flowers(flowers: Array) -> void:
	...

func start_drag(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> DreamSeedDragResult:
	...

func move_drag(mouse_position: Vector2, enemies: Array[Enemy]) -> void:
	...

func release_drag(mouse_position: Vector2, enemies: Array[Enemy]) -> DreamSeedDragResult:
	...

func cancel_drag() -> void:
	...

func is_dragging() -> bool:
	...
```

## Game.gd 側の理想形

`Game.gd` では、夢の種ドラッグ処理を詳細実装しない。

```gdscript
func _on_seed_skill_drag_started(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	if not _can_start_seed_drag():
		return

	var result := dream_seed_controller.start_drag(button, seed_skill, mouse_position)
	if not result.started:
		return

	auto_digest_paused_for_drag = auto_digest_enabled
	_update_auto_digest_timer()
	_play_click_se()
```

```gdscript
func _on_seed_skill_drag_moved(
	_button: DreamSeedSkillButton,
	_seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	if not battle_active:
		return

	dream_seed_controller.move_drag(mouse_position, enemies)
	_set_hovered_enemy(null)
```

```gdscript
func _on_seed_skill_drag_released(
	_button: DreamSeedSkillButton,
	_seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	var result := dream_seed_controller.release_drag(mouse_position, enemies)
	if result.placed:
		_refresh_after_battle_event()

	if auto_digest_enabled:
		auto_digest_paused_for_drag = false
	_update_auto_digest_timer()
	_play_click_se()
```

## 受け入れ条件

- `Game.gd` から `dragging_seed_block` と `dragging_seed_button` が削除される。
- 夢の種ブロック生成処理が `Game.gd` から外れる。
- 夢の種ブロック配置処理が `Game.gd` から外れる。
- 既存の夢の種ドラッグ挙動が壊れない。
- 通常敵ドラッグと夢の種ドラッグが同時に走らない。
- 自動消化中の pause / resume が維持される。

---

# Phase 2: DragMode を導入する

## 目的

通常敵ドラッグと夢の種ドラッグの排他制御を明確化する。

## 現状の問題

現在は以下のような null 判定の組み合わせで排他している。

```gdscript
dragging_enemy != null
dragging_seed_block != null
```

ドラッグ対象が増えると条件が複雑になる。

## 改善案

`Game.gd` に enum を導入する。

```gdscript
enum DragMode {
	NONE,
	ENEMY,
	DREAM_SEED,
}
```

```gdscript
var drag_mode := DragMode.NONE
```

判定例:

```gdscript
func _can_start_enemy_drag() -> bool:
	return battle_active and drag_mode == DragMode.NONE and not digest_turn_in_progress

func _can_start_seed_drag() -> bool:
	return battle_active and drag_mode == DragMode.NONE and not digest_turn_in_progress
```

ドラッグ開始時:

```gdscript
drag_mode = DragMode.ENEMY
```

または

```gdscript
drag_mode = DragMode.DREAM_SEED
```

ドラッグ終了・キャンセル時:

```gdscript
drag_mode = DragMode.NONE
```

## 受け入れ条件

- ドラッグ排他条件が null チェックの組み合わせから enum 判定へ整理される。
- 通常敵ドラッグと夢の種ドラッグが同時に開始されない。
- ドラッグ終了時に必ず `DragMode.NONE` に戻る。
- 例外的なキャンセル時にも DragMode が残留しない。

---

# Phase 3: 夢の種ブロックと悪夢 Enemy の境界を明確化する

## 目的

夢の種ブロックは現在 `Enemy` として生成されている。  
短期的にはこのままでよいが、「悪夢」と「補助ブロック」の仕様境界をコード上で明確にする。

## 現状の問題

夢の種ブロックは `Enemy` として `enemies` 配列に追加される。

そのため、以下の処理に混ざる可能性がある。

```text
- 勝利判定
- 敵攻撃計算
- 悪夢スキル処理
- 隣接判定
- 重力処理
- 消化処理
```

`Enemy.gd` には `is_seed_stomach_block()` があるので、境界を作る準備はできている。

## 改善方針

`Enemy.gd` に意味の明確な判定を追加する。

```gdscript
func is_nightmare() -> bool:
	return not is_seed_stomach_block()
```

必要に応じて、以下のような判定も追加する。

```gdscript
func is_stomach_piece() -> bool:
	return is_active_in_stomach()

func should_count_for_battle_clear() -> bool:
	return is_nightmare()

func should_apply_nightmare_skill() -> bool:
	return is_nightmare()

func should_deal_player_damage() -> bool:
	return is_nightmare()
```

## Game.gd の勝利判定を明確化

現在の `_all_enemies_digested()` が「悪夢だけ」を対象にするなら、名前を変更する。

```gdscript
func _all_nightmares_digested() -> bool:
	for enemy in enemies:
		if not enemy.is_nightmare():
			continue
		if not enemy.digested:
			return false
	return true
```

もし夢の種ブロックも消化対象に含める仕様なら、関数名を以下のように変える。

```gdscript
func _all_stomach_pieces_digested() -> bool:
	...
```

## 受け入れ条件

- 夢の種ブロックが勝利判定に含まれるかどうかがコード上で明確になる。
- 悪夢スキル処理の対象が明確になる。
- プレイヤーダメージ処理の対象が明確になる。
- `Enemy` を流用する場合でも、種ブロックと悪夢の区別が読み取れる。

---

# Phase 4: seed_block_definition を導入する

## 目的

夢の種ブロック生成時に、敵テンプレートの最初の定義を流用する仮実装をやめる。

## 現状の問題

夢の種ブロック作成時、`enemy_definitions` から最初の `EnemyDefinition` を取得している。

```gdscript
func _get_seed_block_template() -> EnemyDefinition:
	for definition in enemy_definitions:
		if definition is EnemyDefinition:
			return definition as EnemyDefinition
	return null
```

これは仮実装としては理解できるが、夢の種ブロックは敵ではないため意味が曖昧。

## 改善案

短期対応として、`Game.gd` または `GameDreamSeedController` に専用の export を追加する。

```gdscript
@export var seed_block_definition: EnemyDefinition
```

`game.tscn` で専用定義を設定する。

新規 Resource 候補:

```text
data/resources/enemies/seed_block.tres
```

または将来用に専用 Resource を作る。

```gdscript
class_name SeedBlockDefinition
extends Resource

@export var texture: Texture2D
@export var stomach_size := Vector2i.ONE
@export var stomach_shape: Array[Vector2i] = [Vector2i.ZERO]
```

ただし、今回は大きくしすぎないため、まずは `EnemyDefinition` の専用定義でよい。

## 受け入れ条件

- 夢の種ブロック生成が通常敵テンプレートに依存しない。
- 夢の種ブロック用の見た目・サイズ・HPが明確になる。
- `enemy_definitions[0]` 的な暗黙依存が消える。

---

# Phase 5: stock の所有者を UI から Runtime State へ寄せる

## 目的

夢の種スキルの残り使用回数を、UI ボタンではなくゲーム状態として扱う。

## 現状の問題

`DreamSeedSkillButton` が `_remaining_stock` を持っている。

```gdscript
var _remaining_stock := 0
```

`set_seed_source()` のたびに以下のように初期化される。

```gdscript
_remaining_stock = seed_skill.stock_count if seed_skill != null else 0
```

これは UI 再生成時に stock が戻るリスクがある。

## 改善方針

短期的には、既存構造を大きく壊さず、`DreamSeedRuntimeState` を導入する。

新規ファイル候補:

```text
scene/main/game/dream_seed_runtime_state.gd
```

内容例:

```gdscript
class_name DreamSeedRuntimeState
extends RefCounted

var source: Resource
var seed_skill: DreamSeedSkillDefinition
var remaining_stock := 0

func can_use_sub_skill() -> bool:
	return seed_skill != null and remaining_stock > 0

func consume_stock() -> void:
	remaining_stock = maxi(0, remaining_stock - 1)
```

`GameDreamSeedController` は `battle_flowers` から `DreamSeedRuntimeState` を作る。

UI ボタンには RuntimeState または remaining_stock を渡す。

## DreamSeedSkillButton の役割

ボタンは stock を所有しない。  
表示と入力だけを担当する。

```gdscript
func set_remaining_stock(value: int) -> void:
	_remaining_stock_for_display = value
	_refresh_tooltip()
	_update_drag_state()
```

理想的には、名前も `_remaining_stock` ではなく `_display_remaining_stock` にする。

## 段階的対応

いきなり完全移行が大きすぎる場合は、次の段階で進める。

### Step 1

`DreamSeedSkillButton` の stock を「表示用」として扱うコメントまたは命名に変える。

```gdscript
var _display_remaining_stock := 0
```

### Step 2

`GameDreamSeedController` に RuntimeState を持たせる。

### Step 3

使用成功時は Controller 側で stock を消費し、UIへ反映する。

## 受け入れ条件

- stock の真の所有者が UI ボタンではなくなる。
- UI 再生成で stock が復活しない。
- stock が 0 になったスキルは使用不可になる。
- 既存の tooltip 表示は維持される。

---

# Phase 6: DreamSeedEffectCalculator のマジックナンバーを定数化する

## 目的

夢の種スキル ID の数値直書きをなくし、可読性を上げる。

## 現状の問題

`DreamSeedEffectCalculator` などに、`2003` のような裸の数値が残っている可能性がある。

例:

```gdscript
match seed_skill.skill_id:
	DREAM_SEED_DIGEST_DAMAGE_UP:
		...
	DREAM_SEED_TIME_REDUCTION:
		...
	2003:
		...
```

## 改善案

定数化する。

```gdscript
const DREAM_SEED_RARE_TIME_REDUCTION := 2003
```

使用箇所:

```gdscript
DREAM_SEED_RARE_TIME_REDUCTION:
	next_time_reduction_bonus_rate += RARE_SKILL_3_ACTIVATION_TIME_REDUCTION_RATE
```

## 受け入れ条件

- `2003` のような裸のスキル ID が消える。
- 既存の効果挙動は変わらない。
- どの ID がどの効果かコード上で読める。

---

# Phase 7: StageClear.gd の肥大化を抑える

## 目的

`StageClear.gd` が報酬画面の神クラス化し始めているため、状態と報酬処理を分離する。

## 現状の責務

`StageClear.gd` は現在、以下を担当している。

```text
- HP表示
- 回復計算
- 種選択
- 種放棄
- 花追加
- 花置き換え
- extra seed choice
- debug表示
- dream seed skill button更新
- UI文言更新
```

## 改善案 1: StageClearState

新規ファイル候補:

```text
scene/main/stage_clear/stage_clear_state.gd
```

内容例:

```gdscript
class_name StageClearState
extends RefCounted

var current_hp := 100
var clear_minutes := 22 * 60
var recovery_applied := false
var remaining_extra_seed_choices := 0
var extra_seed_choice_granted := false
var planted_flowers: Array[FlowerDefinition] = []
```

## 改善案 2: StageClearRewardController

新規ファイル候補:

```text
scene/main/stage_clear/stage_clear_reward_controller.gd
```

責務:

```text
- seed 選択
- flower 作成
- flower 追加
- flower 置換
- extra seed choice 判定
- abandon 回復率計算
```

## 段階的対応

一気に分けると危険なので、まずは純粋処理を切り出す。

優先的に切り出す関数候補:

```gdscript
_create_seed_flower()
_can_plant_seed()
_replace_flower()
_get_preview_flowers_for_seed()
_update_extra_seed_choices()
_apply_selection_recovery()
```

## 受け入れ条件

- `StageClear.gd` の責務が UI 調停寄りになる。
- 報酬選択ルールが専用 Controller に寄る。
- 既存の種選択、放棄、HP回復、extra choice 挙動が壊れない。
- UI の見た目は変えない。

---

# Phase 8: RunState への完全移行を進める

## 目的

HP と植えた花の真の所有者を `RunState` に寄せる。

## 現状の問題

`RunState` はあるが、HP と花はまだ `StageClear` から取得している。

```gdscript
return stage_clear.get_current_hp()
return stage_clear.get_planted_flowers()
```

つまり状態所有者が分散している。

```text
RunState:
- day
- selected_stage
- stomach size

StageClear:
- current_hp
- planted_flowers

Game:
- battle hp
- last_time_over_recovery_percent
```

## 改善案

`StageClear` の選択完了時に結果オブジェクトを返す。

新規ファイル候補:

```text
scene/main/stage_clear/stage_clear_result.gd
```

内容例:

```gdscript
class_name StageClearResult
extends RefCounted

var current_hp := 100
var planted_flowers: Array[FlowerDefinition] = []
var recovered_hp_rate := 0.0
```

signal:

```gdscript
signal selection_finished(result: StageClearResult)
```

`Main.gd` 側:

```gdscript
func _on_stage_clear_selection_finished(result: StageClearResult) -> void:
	run_state.current_hp = result.current_hp
	run_state.planted_flowers = result.planted_flowers.duplicate()
	run_state.current_day += 1
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	show_day_intro()
```

## 段階的対応

互換性のため、最初は既存 signal を残してもよい。

```gdscript
signal selection_finished(recovered_hp_rate: float)
signal selection_result_finished(result: StageClearResult)
```

最終的には result 型へ寄せる。

## 受け入れ条件

- HP と花の真の所有者が `RunState` へ近づく。
- `Main.gd` が `StageClear.get_current_hp()` / `get_planted_flowers()` に依存しすぎない。
- 戦闘開始時の `BattleStartContext` が `RunState` から作られる。
- 既存進行が壊れない。

---

# Codex 作業時の推奨順

以下の順で作業すること。

```text
1. 2003 などのマジックナンバーを定数化する
2. Enemy に is_nightmare() / should_count_for_battle_clear() などを追加する
3. 勝利判定を悪夢対象か全ピース対象か明確化する
4. DragMode enum を導入する
5. GameDreamSeedController にドラッグ状態を移す
6. seed_block_definition を導入する
7. stock を RuntimeState へ寄せる
8. StageClearState / StageClearRewardController を導入する
9. StageClearResult を導入し、RunState への状態移行を進める
```

一度に全て実装しない。  
Phase ごとに小さくコミットできる粒度にする。

---

# Codex への禁止事項

以下は禁止。

```text
- 夢の種ドラッグ機能を勝手に最終仕様化しない
- UI レイアウトを大きく変更しない
- 既存文言を勝手に変更しない
- PassiveFlowerSpawner を戦闘画面に復活させない
- status message の動的表示機能を追加しない
- 既存の敵ドラッグ操作を壊さない
- 既存の消化ターン進行を壊さない
- Resource の uid やパスを不用意に変えない
- `.godot/` を編集しない
- `.tscn` を大規模に並べ替えない
```

---

# 検証チェックリスト

## 起動確認

```text
- Godot で project.godot を開ける
- Main Scene から起動できる
- タイトル画面が表示される
- 最初から開始できる
```

## 基本フロー

```text
- オープニングが進む
- 日付表示が出る
- ステージ選択が出る
- 戦闘画面へ進む
- 敵をドラッグできる
- 胃袋に敵を置ける
- 消化開始できる
- ステージクリアまたはゲームオーバーへ進む
```

## 夢の種関連

```text
- 戦闘中に夢の種スキルボタンが表示される
- 使用可能なサブスキルはドラッグ開始できる
- stock 0 のスキルはドラッグできない
- ドラッグ中に通常敵ドラッグが開始されない
- 通常敵ドラッグ中に夢の種ドラッグが開始されない
- 胃袋に置ける場合だけ seed block が配置される
- 置けない場合は seed block が消える
- 配置成功時に stock が減る
- UI 再生成で stock が復活しない
```

## 種ブロック境界

```text
- 種ブロックが勝利判定に含まれるかどうかが仕様通り
- 種ブロックが敵攻撃計算に混ざらない、または仕様通り混ざる
- 種ブロックが悪夢スキルの対象になるかどうかが仕様通り
- 種ブロックの消化処理が仕様通り
```

## StageClear

```text
- 種を選べる
- 種を放棄できる
- HP 回復表示が壊れない
- extra seed choice が壊れない
- 花の保持状態が次戦闘へ渡る
```

---

# 最終目標

最終的には以下の依存構造を目指す。

```text
Game
- 戦闘全体の司令塔
- 入力結果と Controller 結果の調停
- UI refresh
- battle_finished emit

GameDreamSeedController
- 夢の種の戦闘中状態
- stock 管理
- drag state
- seed block 生成
- seed block 配置
- activation 効果の要求

DreamSeedEffectCalculator
- 継続効果
- 次ターン効果
- 数値計算

Enemy
- 悪夢または胃袋ピースとしての表示・状態
- is_seed_stomach_block()
- is_nightmare()

StageClear
- 報酬画面の UI 調停

StageClearRewardController
- 種選択・花追加・置換ルール

RunState
- 日数
- HP
- ステージ
- 胃袋サイズ
- 植えた花
- 夢の種 runtime state
```

この状態になれば、夢の種機能を増やしても `Game.gd` が再び神クラス化しにくくなる。
