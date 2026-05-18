# GJGJ_2605 リファクタリング仕様書 for Codex

## 目的

この仕様書は、Godot プロジェクト `GJGJ_2605` を長期開発に耐える構造へ整理するための Codex 向けリファクタリング指示である。

今回の目的は、ゲーム内容の追加ではなく、以下を改善すること。

- 責務分離
- 可読性
- 依存方向
- 状態管理
- データ駆動設計
- 将来のステージ拡張・セーブ対応・効果追加への準備

既存のゲーム体験、見た目、操作感、文言は原則として変更しない。

---

## Codex が最初に読むファイル

作業前に以下を読むこと。

```text
AGENTS.md
.codex/project-overview.md
.codex/gdscript-style.md
.codex/scene-contracts.md
.codex/workflow-checks.md
```

作業内容が戦闘や責務分離に関わる場合は、追加で以下を読むこと。

```text
.codex/godot_scene_refactor.md
```

---

## 前提

このプロジェクトは、悪夢を胃袋に配置して消化する Godot 4.x の 2D ゲームである。

現在の主な設計上の課題は次の通り。

```text
1. ゲーム進行状態が Main / Game / StageClear に分散している
2. StageSelect の選択結果が戦闘内容へ十分に接続されていない
3. Game.gd が戦闘司令塔としてまだ多くの責務を持つ
4. NightmareDigestController が敵生成や Node 操作に依存している
5. skill_id のマジックナンバーが多い
6. BattleUI の Tooltip 管理が増え、責務が重くなり始めている
```

---

## 明示的な非対象

以下は今回のリファクタリング対象にしない。

### 1. タイトルの「始める」「続ける」など未実装 UI

開発途中であるため、未実装ボタンの完成や仕様変更は行わない。

### 2. ゲーム画面での PassiveFlower 表示

ゲーム画面では花を表示しない方針で進める。

したがって、`PassiveFlowerSpawner` をゲーム画面で使う処理は不要である。  
戦闘中の花表示を復活させる変更は行わない。

### 3. Status message の動的文言表示

プレイヤー向けステータスメッセージの文字列は固定方針とする。  
「胃がいっぱい」「置けません」などをプレイヤー向け表示として追加・変更しない。

既存の `START_MESSAGE` や UI 文言を勝手に変更しない。  
動的ステータスメッセージ表示を新機能として整備しない。

### 4. 見た目の大幅変更

UI レイアウト、アート、フォント、色、演出をリファクタリングと同時に大幅変更しない。

---

# Phase 0: 安全確認

## 0-1. 現在の参照関係を確認する

Codex は作業前に以下を検索する。

```text
PassiveFlowerSpawner
PassiveFlower
setup_flowers
_set_status_message
set_debug_message
selected_stage_id
stage_selected
start_battle
skill_id
```

## 0-2. Godot 管理ファイルの編集方針

`.tscn` を編集する場合は差分を最小限にすること。  
削除するノードや ext_resource がある場合、参照が残っていないか確認すること。

---

# Phase 1: 不要コードの整理

## 1-1. ゲーム画面の PassiveFlower 表示経路を削除する

### 背景

ゲーム画面では花を表示しない方針である。  
そのため、戦闘画面上の `PassiveFlowerSpawner` 関連コードは不要。

### 対象候補

```text
scene/main/game/game.gd
scene/main/game/game.tscn
scene/object/dreamseed/passive_flower_spawner.gd
```

### 作業方針

1. `Game.gd` から `passive_flower` 参照を削除する。
2. `Game.start_battle()` 内の `passive_flower.setup_flowers(...)` 呼び出しを削除する。
3. `game.tscn` の `PassiveFlower` ノードを削除する。
4. `game.tscn` 内の `passive_flower_spawner.gd` ext_resource が不要になれば削除する。
5. `passive_flower_spawner.gd` が他で参照されていない場合は削除候補とする。
6. ただし、他シーンで使われている場合は削除せず、その用途を確認して残す。

### 受け入れ条件

- 戦闘開始時に PassiveFlower 表示処理が呼ばれない。
- `Game.gd` が `PassiveFlowerSpawner` に依存しない。
- `game.tscn` に未使用の `PassiveFlower` ノードが残らない。
- 未使用スクリプトを削除した場合、参照切れがない。

---

## 1-2. 動的 status message 経路を整理する

### 背景

プレイヤー向けメッセージは固定方針であり、動的な文言変更は行わない。  
したがって、ゲームロジック上のイベントを可変メッセージとして UI に渡す処理は不要。

### 対象候補

```text
scene/main/game/game.gd
scene/ui/battle_ui/battle_ui.gd
scene/ui/battle_ui/status_panel_view.gd
```

### 作業方針

1. `START_MESSAGE` は維持する。
2. `ui.reset_for_battle(..., START_MESSAGE, ...)` のような初期表示は維持してよい。
3. `_set_status_message(message: String)` が実質的に可変メッセージ表示のためだけに存在するなら、削除または簡素化する。
4. `_set_status_message("胃がいっぱいで置けません")` のような呼び出しは、可変メッセージ表示目的では使わない。
5. 呼び出し箇所は必要に応じて `_refresh_ui()` または状態更新後の明確な関数へ置き換える。
6. Debug 用のボタンや数値表示は、既存仕様として必要なら維持する。ただし通常メッセージ表示と混ぜない。

### 推奨する簡素化例

```gdscript
func _refresh_after_battle_event() -> void:
	_refresh_ui()
```

または、単に呼び出し箇所で `_refresh_ui()` を実行する。

### 受け入れ条件

- プレイヤー向け文言は固定のまま。
- ゲームロジックが UI に可変ステータスメッセージを渡す構造を持たない。
- Debug 表示が必要な場合でも、通常メッセージ表示と責務が混ざっていない。
- 既存の戦闘進行は変わらない。

---

# Phase 2: ステージ選択を戦闘へ接続する

## 2-1. selected_stage_id を Game に渡す

### 背景

`StageSelect` はランダムな3択から `stage_id` を emit し、`Main` は `selected_stage_id` に保存している。  
しかし現状では `selected_stage_id` が `Game.start_battle()` に渡っていない可能性がある。

### 作業方針

短期対応として、`selected_stage_id` を `Game.start_battle()` に渡す。

```gdscript
game.start_battle(
	_get_starting_hp(reset_player_state),
	current_day,
	selected_stage_id,
	_get_planted_flowers()
)
```

`Game.start_battle()` 側も、引数を明示する。

```gdscript
func start_battle(
	starting_hp: int = MAX_HP,
	day: int = 1,
	stage_id: int = 0,
	flowers: Array = []
) -> void:
```

### 受け入れ条件

- 選択した `stage_id` が戦闘開始時に `Game` へ渡る。
- 既存の `current_day` と `flowers` の受け渡しが壊れない。
- まだ `stage_id` を戦闘内容に反映しない場合でも、引数として保持できる。

---

## 2-2. 長期的には StageDefinition を渡す

### 推奨方針

長期的には `stage_id` ではなく `StageDefinition` を渡す。

```gdscript
signal stage_selected(stage: StageDefinition)
```

```gdscript
var selected_stage: StageDefinition
```

```gdscript
func start_battle(
	starting_hp: int,
	day: int,
	stage: StageDefinition,
	flowers: Array[FlowerDefinition]
) -> void:
```

ただし、今回のリファクタリングで変更範囲が大きくなる場合は、まず `stage_id` 接続だけでよい。

---

# Phase 3: RunState を導入する

## 3-1. 目的

`Main`, `Game`, `StageClear` に分散しているゲーム進行状態を一元化する。

現在分散している状態の例。

```text
current_day
current_hp
selected_stage_id
planted_flowers
last_time_over_recovery_percent
```

## 3-2. 推奨実装

```gdscript
class_name RunState
extends Resource

var current_day := 1
var current_hp := 100
var max_hp := 100
var selected_stage_id := 0
var selected_stage: StageDefinition
var planted_flowers: Array[FlowerDefinition] = []
var last_time_over_recovery_percent := 0

func reset() -> void:
	current_day = 1
	current_hp = max_hp
	selected_stage_id = 0
	selected_stage = null
	planted_flowers.clear()
	last_time_over_recovery_percent = 0
```

## 3-3. 作業方針

1. まず `RunState` クラスを追加する。
2. `Main.gd` に `var run_state := RunState.new()` を持たせる。
3. すぐに全状態を移す必要はない。
4. まず `current_day`, `selected_stage_id` から移す。
5. 次に HP と花を移す。
6. 変更範囲が大きくなりすぎる場合は段階的に行う。

## 3-4. 受け入れ条件

- `Main.gd` が直接持つ進行状態が減る。
- 日数、HP、花、選択ステージの所有者が明確になる。
- 将来セーブデータへ変換しやすい構造になる。

---

# Phase 4: BattleStartContext を導入する

## 4-1. 目的

`Game.start_battle()` の引数増加を防ぎ、戦闘開始条件を明確にする。

## 4-2. 推奨実装

```gdscript
class_name BattleStartContext
extends RefCounted

var starting_hp := 100
var day := 1
var stage_id := 0
var stage: StageDefinition
var flowers: Array[FlowerDefinition] = []
```

## 4-3. 作業方針

1. `BattleStartContext` を作成する。
2. `Main` または `RunState` から `BattleStartContext` を組み立てる。
3. `Game.start_battle(context: BattleStartContext)` に移行する。
4. 移行中は旧シグネチャを一時的に残してもよいが、最終的には Context に寄せる。

## 4-4. 受け入れ条件

- `Game.start_battle()` の引数が整理される。
- 戦闘開始に必要な値が1つの構造にまとまる。
- StageDefinition 接続や将来の難易度補正を追加しやすくなる。

---

# Phase 5: StageDefinition を戦闘用データへ育てる

## 5-1. 背景

現在の `StageDefinition` は表示用データが中心である。  
長期的にはステージごとに戦闘条件を変えられるようにする。

## 5-2. 追加候補

```gdscript
@export var enemy_pool: Array[EnemyDefinition] = []
@export var nightmare_skill_catalog: NightmareSkillCatalog
@export var min_enemy_count := 2
@export var max_enemy_count := 4
@export var stomach_columns := 4
@export var stomach_rows := 5
@export var start_hour := 22
@export var end_hour := 30
@export var reward_pool: Array[SeedOptionDefinition] = []
```

## 5-3. 作業方針

1. いきなり全項目を実装しない。
2. まず `enemy_pool` または `stomach_columns/rows` のどちらか小さい項目から導入する。
3. 既存ステージ `.tres` に未設定でも動くデフォルト値を用意する。
4. 既存の戦闘挙動を維持する。

## 5-4. 受け入れ条件

- ステージデータが表示だけでなく戦闘に影響できる。
- 未設定ステージでもクラッシュしない。
- ステージ差別化がコード分岐ではなく Resource で可能になる。

---

# Phase 6: skill_id マジックナンバーを定数化する

## 6-1. 背景

`NightmareDigestController` や `DreamSeedEffectCalculator` には `skill_id` の数値直書きがある。  
これは長期的に可読性を落とす。

## 6-2. 最低限の対応

```gdscript
const NIGHTMARE_SKILL_OPEN_CELL_ATTACK := 1
const NIGHTMARE_SKILL_DAMAGE_SHARE := 2
const NIGHTMARE_SKILL_OPEN_CELL_DEFENSE := 3
const NIGHTMARE_SKILL_BOTTOM_ATTACK := 4
const NIGHTMARE_SKILL_LATE_DIGEST_WEAKEN := 5
const NIGHTMARE_SKILL_TIME_DELAY := 6
const NIGHTMARE_SKILL_RANDOM_HP := 7
const NIGHTMARE_SKILL_SPAWN_BLOCKS := 8
const NIGHTMARE_SKILL_CHAIN_GROWTH := 9
const NIGHTMARE_SKILL_ODD_ORDER_DAMAGE := 10
const NIGHTMARE_SKILL_EVEN_ORDER_REVIVE := 11
const NIGHTMARE_SKILL_SINGLE_DIGEST_SPAWN := 12
```

夢の種側も同様に定数化する。

```gdscript
const DREAM_SEED_DIGEST_DAMAGE_UP := 1
const DREAM_SEED_CLEAR_RECOVERY_UP := 2
const DREAM_SEED_TIME_REDUCTION := 3
const DREAM_SEED_REST_RECOVERY := 4
```

## 6-3. 長期方針

スキル数が増えたら、`effect_type: StringName` または効果 Resource 化を検討する。  
今回のリファクタリングでは定数化まででよい。

## 6-4. 受け入れ条件

- `_has_nightmare_effect(enemy, 6)` のような直書きが減る。
- 数字の意味がコード上で読める。
- 既存スキル挙動は変わらない。

---

# Phase 7: 依存方向の整理

## 7-1. NightmareDigestController から敵生成依存を減らす

### 現状の課題

`NightmareDigestController` が `GameEnemySetupController` を受け取り、消化結果として邪魔悪夢を直接生成させている可能性がある。

これは依存方向として重い。

```text
NightmareDigestController
→ GameEnemySetupController
→ owner Node
→ add_child
```

### 推奨方針

消化処理は「何が起きたか」を返す。  
実際の Node 生成は `Game` または `NuisanceEnemySpawner` が行う。

```gdscript
class_name DigestResult
extends RefCounted

var digested_enemies: Array[Enemy] = []
var player_damage_values: Array[int] = []
var spawn_requests: Array[NuisanceSpawnRequest] = []
```

```gdscript
class_name NuisanceSpawnRequest
extends RefCounted

var source_enemy: Enemy
var cell: Vector2i
var hp_rate := 0.5
var damage := 0
```

## 7-2. 受け入れ条件

- 消化ロジックが scene tree 操作を直接要求しない方向へ近づく。
- 敵生成の責務が Spawner 側に寄る。
- ただし、変更範囲が大きい場合は後続タスクとして TODO 化してよい。

---

# Phase 8: BattleUI の責務整理

## 8-1. TooltipManager を検討する

`BattleUI` に `show_xxx_tooltip()` / `hide_xxx_tooltip()` が増えている場合、Tooltip 管理を専用クラスへ分ける。

```gdscript
class_name TooltipManager
extends RefCounted

var tooltips: Array[Control] = []

func show_only(target: Control) -> void:
	for tooltip in tooltips:
		tooltip.hide()
	if target != null:
		target.show()
```

## 8-2. BattleViewState を検討する

`Game._refresh_ui()` が UI の各項目を個別に呼び出しすぎる場合、表示用状態にまとめる。

```gdscript
class_name BattleViewState
extends RefCounted

var hp := 100
var max_hp := 100
var minutes := 0
var digest_damage_breakdown := {}
var digest_efficiency_breakdown := {}
var rest_recovery_bonus_rate := 0.0
var active_digest_count := 0
var can_press_digest := true
```

```gdscript
ui.apply_state(view_state)
```

## 8-3. 受け入れ条件

- `Game` が UI 内部仕様に依存しすぎない。
- `BattleUI` の Tooltip 相互排他処理が読みやすくなる。
- 見た目は変えない。

---

# Codex への禁止事項

以下を行わないこと。

1. ゲーム画面に花表示を復活させない。
2. プレイヤー向け status message の文言を動的に変更する機能を追加しない。
3. タイトルの未実装ボタンを勝手に完成させない。
4. 大規模な UI 見た目変更を同時に行わない。
5. `.godot/` を編集しない。
6. 未確認の NodePath を推測で変更しない。
7. 既存 Resource の uid やパスを不用意に変更しない。
8. すべてを巨大 Manager や Autoload に逃がさない。
9. リファクタリングとゲームバランス変更を同時に行わない。
10. Godot で検証していないのに検証済みと報告しない。

---

# 推奨作業順

```text
1. PassiveFlowerSpawner のゲーム画面依存を削除
2. 動的 status message 経路を簡素化
3. selected_stage_id を Game.start_battle() に渡す
4. skill_id を定数化
5. RunState を追加
6. BattleStartContext を追加
7. StageDefinition に戦闘用データを少しずつ追加
8. DigestResult / NuisanceSpawnRequest を検討
9. TooltipManager / BattleViewState を検討
```

一度に全 Phase を行わない。  
Phase ごとに差分を小さくし、毎回起動確認する。

---

# 検証手順

可能なら以下を実行する。

```bash
godot --headless --path . --quit
```

環境により以下も試す。

```bash
godot4 --headless --path . --quit
```

実行できない場合は、その事実を報告する。

最低限、以下を確認する。

- `main.tscn` から起動できる
- タイトルから開始できる
- ステージ選択が表示される
- 3択から選択できる
- 戦闘に遷移できる
- 消化開始が動作する
- ステージクリアまたはゲームオーバーへ進める
- 既存の文言・見た目が意図せず変わっていない
