# GJGJ_2605 現状コードレビュー & Codex向けリファクタリング指示書

対象: `ddd.zip` 内の現行 Godot プロジェクト  
観点: 責務分離 / 可読性 / 依存性 / 肥大化抑制 / 既存コード範囲内での安全な改善  
前提: 未実装・開発途中の仕様を完成させるのではなく、現状存在するコードの範囲で破綻しにくい構造へ整える。

---

## 0. Codexへの最重要指示

今回のリファクタリングでは、**新機能を完成させない**こと。

やることは次の通り。

```text
- 既存コードの責務を整理する
- 既存の曖昧な境界を明確化する
- Game.gd / StageClear.gd / GameDreamSeedController.gd の肥大化を抑える
- 夢の種ドラッグ機能の途中実装を、今後拡張しやすい形へ整える
```

やらないこと。

```text
- 未実装の夢の種効果を新規実装しない
- UIレイアウトを大きく変えない
- プレイヤー向け文言を変えない
- PassiveFlowerSpawner を戦闘画面へ復活させない
- status message の動的表示を追加しない
- ゲームバランスを変更しない
- .godot/ を編集しない
```

---

# 1. 現状レビューまとめ

## 1-1. すでに改善されている点

以下はすでに良くなっているため、Codexに重複作業させない。

### RunState / BattleStartContext は導入済み

`RunState` が日数、HP、胃袋サイズ、選択ステージ、植えた花、敵プリセット進行を保持する形になっている。

`BattleStartContext` も、戦闘開始時の入力データとして以下を持っている。

```gdscript
var starting_hp := 100
var day := 1
var stage_id := 0
var stage: StageDefinition
var enemy_preset: EnemyPresetDefinition
var stomach_columns := RunState.DEFAULT_STOMACH_COLUMNS
var stomach_rows := RunState.DEFAULT_STOMACH_ROWS
var flowers: Array[FlowerDefinition] = []
```

これは方向性として良い。

### DragMode は導入済み

`Game.gd` に以下がある。

```gdscript
enum DragMode {
	NONE,
	ENEMY,
	DREAM_SEED,
}
```

敵ドラッグと夢の種ドラッグの排他が、以前より読みやすくなっている。  
この方針は維持する。

### GameDreamSeedController は導入済み

夢の種まわりの処理が `GameDreamSeedController` に切り出されている。  
`Game.gd` からドラッグ中の seed block 変数も削除されており、これは良い。

### DreamSeedDragResult は導入済み

`DreamSeedDragResult` により、夢の種ドラッグの結果が構造化されている。

```gdscript
var started := false
var placed := false
var cancelled := false
var seed_block: Enemy
var source_button: DreamSeedSkillButton
var source: Resource
var seed_skill: DreamSeedSkillDefinition
```

これも良い。

### 夢の種ブロック用の定義 Resource が導入済み

`DreamSeedDragBlockDefinition` があり、夢の種ブロックの HP、damage、texture、胃袋形状を定義できる。

```gdscript
@export var max_hp := 1
@export var damage := 0
@export var texture: Texture2D
@export var stomach_size := Vector2i.ONE
@export var stomach_shape: Array[Vector2i] = [Vector2i.ZERO]
```

これは、通常敵テンプレート流用から一歩進んでいる。

### Enemy に種ブロック判定が入っている

`Enemy.gd` に以下のような境界メソッドがある。

```gdscript
func is_seed_stomach_block() -> bool:
	return seed_skill_definition != null

func is_nightmare() -> bool:
	return not is_seed_stomach_block()

func should_count_for_battle_clear() -> bool:
	return is_nightmare()

func should_apply_nightmare_skill() -> bool:
	return is_nightmare() and nightmare_skill_enabled

func should_deal_player_damage() -> bool:
	return is_nightmare()
```

これは良い。  
ただし、後述する通り、まだ消化順や連鎖反応側に種ブロックが混ざる余地がある。

### 夢の種スキル ID の定数化は進んでいる

`DreamSeedEffectCalculator` 側で `DREAM_SEED_RARE_TIME_REDUCTION := 2003` などが定数化されている。  
裸の `2003` を直す作業はほぼ不要。

---

# 2. 残っている主な問題

## 問題A: Game.gd はまだ司令塔として重い

`Game.gd` はかなり改善されているが、まだ以下を同時に担当している。

```text
- 戦闘開始
- 敵ドラッグ
- 夢の種ドラッグの委譲
- 消化ターン進行
- HP / 時間管理
- UI更新
- Debug操作
- 夢の種 depleted 通知
- BGM同期の受け渡し
```

夢の種ドラッグ状態そのものは `GameDreamSeedController` に移ったが、`Game.gd` にはまだ結果処理が散らばっている。

現在の典型例。

```gdscript
var result := dream_seed_controller.release_drag(mouse_position, enemies)
if result.started:
	_play_click_se()
if result.placed:
	_refresh_after_battle_event()
	if result.source_button != null and is_instance_valid(result.source_button):
		result.source_button.consume_sub_skill_use()
		dream_seed_controller.remove_source_while_in_stomach(result.source_button, result.seed_block)
		_sync_dream_seed_sources()
if auto_digest_enabled:
	auto_digest_paused_for_drag = false
drag_mode = DragMode.NONE
_update_auto_digest_timer()
```

この処理は動くが、`Game.gd` が夢の種使用後処理を知りすぎている。

---

## 問題B: GameDreamSeedController が肥大化し始めている

`GameDreamSeedController.gd` は約 288 行あり、以下を持っている。

```text
- 戦闘中の花リスト管理
- debug seed 生成
- seed block 生成
- seed block ドラッグ
- seed block 配置
- depleted source 管理
- digested seed effect 適用
- rest time skip 管理
```

これは現時点では許容範囲だが、このまま夢の種効果が増えるとすぐ太る。

特に以下は分離候補。

```text
- debug seed 生成
- seed block 生成
- digested seed effect 適用
```

---

## 問題C: 夢の種ブロックが digest_order / 連鎖反応に混ざる可能性がある

`Enemy` 側では `is_nightmare()` と `should_apply_nightmare_skill()` があるため、悪夢スキルの発動対象から種ブロックを除外する準備はある。

しかし、`NightmareDigestController` の以下の処理では、`digested_enemies` 全体を扱っているため、種ブロックが混ざる可能性がある。

```text
- digest_order の加算
- 奇数/偶数消化順スキル
- chain reaction
- single digest spawn 判定
```

具体的に危険な構造。

```gdscript
for enemy in digested_enemies:
	digest_order += 1
	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_ODD_ORDER_DAMAGE) and digest_order % 2 == 1:
		...
```

種ブロックが `digested_enemies` に含まれると、悪夢ではないのに `digest_order` を進める可能性がある。  
これは「悪夢の消化順」を参照するスキルに影響する。

また、以下のような判定も危険。

```gdscript
if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_SINGLE_DIGEST_SPAWN) and digested_enemies.size() == 1:
```

夢の種ブロックと悪夢が同時に消化された場合、悪夢1体しか消化していなくても `digested_enemies.size()` が 2 になり、効果が発動しない可能性がある。

---

## 問題D: DreamSeedSkillButton が使用回数を所有している

`DreamSeedSkillButton` に `_remaining_sub_skill_uses` がある。

```gdscript
var _remaining_sub_skill_uses := 0
```

現在はサブスキル使用回数が 1 回固定なので大きな問題ではない。  
ただし、これは UI がゲーム状態を持っている構造であり、長期的には危険。

現状では、配置成功時に次の処理が行われている。

```gdscript
result.source_button.consume_sub_skill_use()
dream_seed_controller.remove_source_while_in_stomach(result.source_button, result.seed_block)
_sync_dream_seed_sources()
```

この構造は短期的には成立している。  
ただし、将来的に「複数回使用」「戦闘をまたいだ残数」「UI再生成後も残数維持」をやるなら破綻しやすい。

今回は未実装仕様を増やさない前提なので、完全な RuntimeState 化は必須ではない。  
ただし、**UI所有であることを明確にし、Controller 側へ少し寄せる**のが良い。

---

## 問題E: StageClear.gd が肥大化している

`StageClear.gd` は約 428 行あり、以下をまとめて持っている。

```text
- HP表示
- 回復計算
- 種選択
- 種放棄
- 花追加
- 花置き換え
- stage drop item 反映
- reroll debug
- extra seed choice
- dream seed button 更新
- guide text 更新
```

現状動くなら問題ないが、機能が増えると修正箇所が読みづらくなる。

特に切り出しやすいのは次の処理。

```text
- seed_options の生成・復元・stage drop 反映
- seed から FlowerDefinition を作る処理
- 植えられるか / 置き換えるかの処理
- preview flowers の作成
- extra seed choice 判定
```

---

## 問題F: Main.gd が RunState を使い切れていない

`RunState` は導入されているが、HP と花はまだ `StageClear` から取得している。

```gdscript
if stage_clear.has_method("get_current_hp"):
	return stage_clear.get_current_hp()
```

```gdscript
if stage_clear.has_method("get_planted_flowers"):
	return stage_clear.get_planted_flowers()
```

現状は移行途中として理解できる。  
ただし、`RunState` を真のゲーム進行状態にしたいなら、HP と花の同期処理を `Main.gd` に明示した方がよい。

---

# 3. Codexに依頼する修正 Phase

## Phase 1: NightmareDigestController で種ブロックを消化順から除外する

### 目的

夢の種ブロックが、悪夢の消化順・連鎖反応・単独消化判定に混ざらないようにする。

### 対象ファイル

```text
scene/object/enemy/enemy.gd
scene/main/game/nightmare_digest_controller.gd
```

### 追加する Enemy メソッド候補

```gdscript
func should_count_for_digest_order() -> bool:
	return is_nightmare()

func should_trigger_nightmare_reactions() -> bool:
	return is_nightmare()
```

既存の `should_count_for_battle_clear()` などと同じ方針でよい。

### NightmareDigestController の修正方針

#### 1. digest_order は悪夢だけで進める

現在のように `digested_enemies` 全体で `digest_order += 1` しない。

修正イメージ。

```gdscript
for enemy in digested_enemies:
	if enemy.should_count_for_digest_order():
		digest_order += 1

	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_ODD_ORDER_DAMAGE) and digest_order % 2 == 1:
		...
```

ただし、`digest_order` を進めない種ブロックに対して、直前の悪夢順を使ってしまわないよう注意する。  
安全には、以下のようにローカル変数を使う。

```gdscript
var current_order := -1
if enemy.should_count_for_digest_order():
	digest_order += 1
	current_order = digest_order

if current_order >= 0 and _has_nightmare_effect(enemy, NIGHTMARE_SKILL_ODD_ORDER_DAMAGE) and current_order % 2 == 1:
	...
```

#### 2. chain reaction は悪夢消化だけをトリガーにする

現在の `_apply_chain_reactions(enemies, digested_enemies)` は、種ブロックが混ざる可能性がある。

修正方針。

```gdscript
var digested_nightmares := _get_digested_nightmares(digested_enemies)
_apply_chain_reactions(enemies, digested_nightmares)
```

#### 3. single digest spawn は「消化された悪夢数」で判定する

現在の `digested_enemies.size() == 1` ではなく、悪夢だけを数える。

```gdscript
var digested_nightmares := _get_digested_nightmares(digested_enemies)

if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_SINGLE_DIGEST_SPAWN) and digested_nightmares.size() == 1:
	...
```

#### 4. helper を追加する

```gdscript
func _get_digested_nightmares(digested_enemies: Array[Enemy]) -> Array[Enemy]:
	var nightmares: Array[Enemy] = []
	for enemy in digested_enemies:
		if enemy != null and enemy.is_nightmare():
			nightmares.append(enemy)
	return nightmares
```

### 受け入れ条件

```text
- 夢の種ブロックが digest_order を進めない
- 夢の種ブロックだけが消化されても悪夢の奇数/偶数効果に影響しない
- chain reaction が夢の種ブロック消化で発動しない
- single digest spawn の判定が「悪夢の消化数」で行われる
- 既存の悪夢スキル挙動は変えない
```

---

## Phase 2: Game.gd の夢の種ドラッグ結果処理を helper にまとめる

### 目的

`Game.gd` の可読性を上げ、夢の種ドラッグ後処理を散らばらせない。

### 対象ファイル

```text
scene/main/game/game.gd
```

### 現状の問題

`_on_seed_skill_drag_released()` 内で以下を直接行っている。

```text
- SE再生
- placed判定
- UI refresh
- button use 消費
- source remove予約
- dream seed sources 同期
- auto digest resume
- DragMode解除
- timer更新
```

### 修正方針

以下の helper に分ける。

```gdscript
func _handle_seed_drag_result(result: DreamSeedDragResult) -> void:
	if result.started:
		_play_click_se()
	if result.placed:
		_apply_placed_seed_drag_result(result)
```

```gdscript
func _apply_placed_seed_drag_result(result: DreamSeedDragResult) -> void:
	_refresh_after_battle_event()
	if result.source_button == null or not is_instance_valid(result.source_button):
		return
	result.source_button.consume_sub_skill_use()
	dream_seed_controller.remove_source_while_in_stomach(result.source_button, result.seed_block)
	_sync_dream_seed_sources()
```

```gdscript
func _finish_drag_operation() -> void:
	if auto_digest_enabled:
		auto_digest_paused_for_drag = false
	drag_mode = DragMode.NONE
	_update_auto_digest_timer()
```

`_on_seed_skill_drag_released()` は次の程度に薄くする。

```gdscript
func _on_seed_skill_drag_released(...) -> void:
	if drag_mode != DragMode.DREAM_SEED:
		return
	var result := dream_seed_controller.release_drag(mouse_position, enemies)
	_handle_seed_drag_result(result)
	_finish_drag_operation()
```

### 受け入れ条件

```text
- 挙動は変わらない
- _on_seed_skill_drag_released() が短くなる
- button consume / source remove / sync の順番は維持される
- auto digest resume と DragMode reset が必ず実行される
```

---

## Phase 3: GameDreamSeedController から seed block 生成依存を整理する

### 目的

`GameDreamSeedController` が `enemy_definitions` に依存して seed block を作る曖昧さを減らす。

### 対象ファイル

```text
scene/main/game/game_dream_seed_controller.gd
```

### 現状の問題

`_get_seed_block_template()` が、まず `enemy_definitions` の最初の `EnemyDefinition` を返す。

```gdscript
for definition in enemy_definitions:
	if definition is EnemyDefinition:
		return definition as EnemyDefinition
return _create_seed_block_template(seed_skill)
```

しかし夢の種ブロックは通常敵ではない。  
すでに `DreamSeedDragBlockDefinition` があるので、通常敵定義に寄せる必要は薄い。

### 修正方針

`_enemy_definitions` 依存を削除、または後方互換 fallback に下げる。

推奨は、seed skill から専用定義を作ること。

```gdscript
func _get_seed_block_template(seed_skill: DreamSeedSkillDefinition) -> EnemyDefinition:
	return _create_seed_block_template(seed_skill)
```

`setup()` から `enemy_definitions` 引数を削除できるなら削除する。

```gdscript
func setup(
	owner: Node,
	stomach: StomachBoard,
	input_controller: GameInputController
) -> void:
	...
```

ただし、影響範囲が大きい場合は、今回は `_get_seed_block_template()` の優先順位だけ変更する。

```gdscript
func _get_seed_block_template(enemy_definitions: Array[Resource], seed_skill: DreamSeedSkillDefinition) -> EnemyDefinition:
	var seed_definition := _create_seed_block_template(seed_skill)
	if seed_definition != null:
		return seed_definition
	for definition in enemy_definitions:
		if definition is EnemyDefinition:
			return definition as EnemyDefinition
	return null
```

### 受け入れ条件

```text
- 夢の種ブロックが通常敵テンプレートに暗黙依存しない
- drag_block_definition がある場合、その値が優先される
- 既存の夢の種ブロック表示と配置が壊れない
```

---

## Phase 4: GameDreamSeedController 内の debug seed 生成を分離する

### 目的

`GameDreamSeedController` の肥大化を抑える。

### 対象ファイル

```text
scene/main/game/game_dream_seed_controller.gd
新規候補: scene/main/game/dream_seed_debug_factory.gd
```

### 現状の問題

`GameDreamSeedController` が debug seed 生成も持っている。

```gdscript
func add_random_debug_seed() -> bool:
	...
```

内部には以下もある。

```gdscript
_get_random_debug_seed_flower()
_get_debug_seed_flower_candidates()
_append_debug_seed_flower_candidates()
```

これらは本体機能ではなくデバッグ補助。

### 修正方針

新規クラスへ切り出す。

```gdscript
class_name DreamSeedDebugFactory
extends RefCounted

const DREAM_SEED_SKILL_CATALOG: DreamSeedSkillCatalog = preload("res://data/resources/seeds/dream_seed_skill_catalog.tres")

func create_random_debug_seed_flower() -> FlowerDefinition:
	...
```

`GameDreamSeedController` 側。

```gdscript
var debug_factory := DreamSeedDebugFactory.new()

func add_random_debug_seed() -> bool:
	var flower := debug_factory.create_random_debug_seed_flower()
	if flower == null:
		return false
	_flowers.append(flower)
	return true
```

### 受け入れ条件

```text
- GameDreamSeedController の行数が減る
- debug seed 生成が本体ロジックから分離される
- debug seed 追加の挙動は変わらない
```

---

## Phase 5: DreamSeedSkillButton の使用回数を「UI表示用」と明確化する

### 目的

未実装仕様を増やさずに、UIがゲーム状態を所有している曖昧さを減らす。

### 対象ファイル

```text
scene/ui/dream_seed_skill_button/dream_seed_skill_button.gd
scene/main/game/game.gd
scene/main/game/game_dream_seed_controller.gd
```

### 現状の問題

`DreamSeedSkillButton` が `_remaining_sub_skill_uses` を持っている。  
ただし現状はサブスキル 1 回使用前提なので、すぐに RuntimeState を導入する必要はない。

### 修正方針

今回やることは、完全な状態移行ではなく、名前と責務を明確化すること。

#### 1. 変数名を表示用に寄せる

```gdscript
var _display_remaining_sub_skill_uses := 0
```

またはコメントを追加する。

```gdscript
# 現状はUI表示兼一時使用回数。永続状態が必要になったらRuntimeStateへ移す。
var _remaining_sub_skill_uses := 0
```

#### 2. Game.gd 側の消費処理を helper に隔離する

Phase 2 の `_apply_placed_seed_drag_result()` 内に閉じ込める。  
将来 RuntimeState 化する時、この関数だけ差し替えやすくする。

### 受け入れ条件

```text
- 現在の 1 回使用挙動は維持される
- UIが持つ使用回数が仮状態であることがコード上で分かる
- 将来 RuntimeState 化する際の差し替え箇所が明確になる
```

---

## Phase 6: StageClear.gd の seed option / reward 処理を helper class に切り出す

### 目的

`StageClear.gd` の肥大化を抑える。  
未実装仕様は増やさず、現在ある報酬選択処理だけを分離する。

### 対象ファイル

```text
scene/main/stage_clear/stage_clear.gd
新規候補: scene/main/stage_clear/stage_clear_reward_service.gd
```

### 切り出し候補

以下は UI 依存が薄く、切り出しやすい。

```gdscript
_create_seed_flower(seed)
_replace_flower(seed, flower)
_get_preview_flowers_for_seed(seed)
_apply_stage_drop_options(stage)
_restore_base_seed_options()
_can_plant_seed(seed)
```

### 推奨クラス

```gdscript
class_name StageClearRewardService
extends RefCounted
```

推奨 API。

```gdscript
func create_seed_flower(seed: SeedOptionDefinition) -> FlowerDefinition:
	...

func can_plant_seed(seed: SeedOptionDefinition, planted_flowers: Array[FlowerDefinition], max_flowers: int) -> bool:
	...

func replace_first_flower(planted_flowers: Array[FlowerDefinition], flower: FlowerDefinition) -> void:
	...

func get_preview_flowers_for_seed(
	seed: SeedOptionDefinition,
	planted_flowers: Array[FlowerDefinition],
	max_flowers: int
) -> Array[FlowerDefinition]:
	...

func get_stage_seed_options(
	base_seed_options: Array[Resource],
	stage: StageDefinition
) -> Array[Resource]:
	...
```

### StageClear.gd 側

`StageClear.gd` は UI と画面状態の調停に寄せる。

```gdscript
var reward_service := StageClearRewardService.new()
```

### 受け入れ条件

```text
- StageClear.gd の報酬ロジックが減る
- 種選択、植える、植え替える、放棄する挙動は変わらない
- stage drop item の反映は維持される
- UI文言や見た目は変えない
```

---

## Phase 7: Main.gd に RunState同期 helper を追加する

### 目的

HP と花がまだ `StageClear` に残っている現状を、いきなり大改造せずに整理する。

### 対象ファイル

```text
scene/main/main.gd
```

### 現状の問題

`Main.gd` が戦闘開始時に `StageClear` から HP と花を取得している。

```gdscript
return stage_clear.get_current_hp()
return stage_clear.get_planted_flowers()
```

### 修正方針

今回、Signal型や StageClearResult までは変えない。  
その代わり、同期 helper を追加して所有境界を明示する。

```gdscript
func _sync_run_state_from_stage_clear() -> void:
	if stage_clear.has_method("get_current_hp"):
		run_state.current_hp = stage_clear.get_current_hp()
	if stage_clear.has_method("get_planted_flowers"):
		run_state.planted_flowers = stage_clear.get_planted_flowers()
```

ステージクリア選択完了時。

```gdscript
func _on_stage_clear_selection_finished(_recovered_hp_rate: float) -> void:
	_sync_run_state_from_stage_clear()
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	_finish_current_day()
```

ゲームオーバー後の HP セット後も必要なら同期する。

`_get_starting_hp()` と `_get_planted_flowers()` は、最終的には `RunState` を優先する。

```gdscript
func _get_starting_hp(reset_player_state: bool) -> int:
	if reset_player_state:
		return run_state.max_hp
	return run_state.current_hp
```

```gdscript
func _get_planted_flowers() -> Array[FlowerDefinition]:
	return run_state.planted_flowers.duplicate()
```

ただし、既存挙動が崩れる場合は段階的に移行する。

### 受け入れ条件

```text
- HP と花の同期場所が明確になる
- StageClear から直接取得する処理が helper に集約される
- BattleStartContext は RunState 由来の値で作れる方向へ近づく
- 既存進行は壊れない
```

---

# 4. 優先順位

Codexは以下の順で作業すること。

```text
1. Phase 1: NightmareDigestController で種ブロックを消化順・連鎖・単独判定から除外
2. Phase 2: Game.gd の夢の種ドラッグ結果処理を helper 化
3. Phase 3: seed block 生成の通常敵定義依存を弱める
4. Phase 4: debug seed 生成を DreamSeedDebugFactory へ分離
5. Phase 5: DreamSeedSkillButton の使用回数を表示用/仮状態として明確化
6. Phase 6: StageClearRewardService を導入して StageClear.gd を軽くする
7. Phase 7: Main.gd に RunState同期 helper を追加
```

一度に全部やらない。  
1 Phase ごとに動作確認し、差分を小さく保つこと。

---

# 5. 禁止事項

```text
- 新しい夢の種効果を実装しない
- 未実装仕様を勝手に完成させない
- UIレイアウトを変更しない
- 既存文言を変更しない
- プレイヤー向け status message 動的表示を追加しない
- PassiveFlowerSpawner を復活させない
- ゲームバランスを変更しない
- .godot/ を編集しない
- .tscn を大規模に並べ替えない
- Resource の uid やパスを不用意に変えない
- 既存の敵ドラッグ、夢の種ドラッグ、消化ターンを壊さない
```

---

# 6. 検証チェックリスト

## 基本起動

```text
- Godotで project.godot を開ける
- タイトルから開始できる
- オープニングが進む
- 日付表示が出る
- ステージ選択が出る
- 戦闘画面へ進める
```

## 戦闘

```text
- 敵をドラッグできる
- 胃袋に敵を置ける
- 胃袋外へ出した時のHPダメージが壊れていない
- 消化開始できる
- 自動消化が止まらない
- 戦闘勝利 / 敗北が従来通り動く
```

## 夢の種ドラッグ

```text
- 夢の種スキルボタンが表示される
- サブスキルがあるボタンだけドラッグできる
- 夢の種ドラッグ中に敵ドラッグが始まらない
- 敵ドラッグ中に夢の種ドラッグが始まらない
- 胃袋に置ける場合だけ seed block が配置される
- 置けない場合は seed block が queue_free される
- 配置成功時に使用回数が減る
- 使用済みソースの削除予約が維持される
```

## 種ブロック境界

```text
- 種ブロックが悪夢の消化順を進めない
- 種ブロック消化で chain reaction が発動しない
- single digest spawn は悪夢の消化数で判定される
- 種ブロックが勝利判定に含まれない
```

## StageClear

```text
- 種を選べる
- 種を放棄できる
- stage drop item が選択肢に反映される
- reroll debug が壊れない
- HP回復予定表示が壊れない
- 花の保持状態が次戦闘へ渡る
```

---

# 7. 期待する最終状態

今回のリファクタリング後は、以下を目指す。

```text
Game.gd
- 戦闘司令塔
- Controller結果の受け取り
- UI refresh
- SE再生
- battle_finished emit

GameDreamSeedController.gd
- 夢の種の戦闘中状態
- seed block drag
- depleted source 管理
- digested seed effect 適用

DreamSeedDebugFactory.gd
- debug seed 生成

NightmareDigestController.gd
- 悪夢の消化処理
- 種ブロックを悪夢順・悪夢反応から除外

Enemy.gd
- 悪夢 / 種ブロック / 胃袋ピースの判定を明示

StageClear.gd
- 報酬画面のUI調停

StageClearRewardService.gd
- 種選択・花作成・置換・preview処理

Main.gd
- RunState同期場所を明示
```

この状態になれば、未実装の夢の種効果を今後追加しても、`Game.gd` と `StageClear.gd` がさらに肥大化しにくくなる。
