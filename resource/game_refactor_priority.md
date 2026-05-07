# game.gd 責務分散リファクタリング指示書

対象シーン: `res://scene/main/game/game.tscn`  
対象スクリプト: `res://scene/main/game/game.gd`

## 目的

`game.gd` に集中している責務を、Godot のシーン単位の設計に沿って分散する。

現在の `Game` ルートノードは、以下の責務を一括で持っている。

- バトル進行
- 時間管理
- HP管理
- 敵データ管理
- 敵表示更新
- ドラッグ入力
- 胃袋グリッド判定
- 胃袋内の重力処理
- 消化処理
- UI更新
- Tween演出
- デバッグメッセージ
- 一時的なプレビュー表示

この状態はプロトタイプとしては許容できるが、機能追加時に `game.gd` が肥大化し続ける。  
以後は `Game.gd` を全体進行の調停役に寄せ、UI・敵・胃袋グリッド・ドラッグ操作・データ定義を個別シーンまたは個別スクリプトに分離する。

## Godot流の設計方針

Godotでは、Unityのように1つのGameObjectへ多数のComponentを積むより、**Sceneを自己完結したオブジェクト単位として扱う**方針を優先する。

基本方針:

- `Enemy.tscn` のルートには `Enemy.gd` を付け、敵自身の状態・表示・演出を持たせる。
- `Stomach.tscn` のルートには `StomachBoard.gd` を付け、胃袋グリッド・配置判定・重力処理を持たせる。
- `BattleUI.tscn` または `UI` ノードには `BattleUI.gd` を付け、UI表示更新を持たせる。
- `Game.gd` はバトル全体の状態遷移と各シーン間の接続に集中する。
- 子シーンから親シーンへ状態変化を伝える場合は signal を優先する。
- 単純な問い合わせ、例えば `board.can_place(enemy, cell)` は signal ではなく通常の関数呼び出しでよい。

## 現在の game.tscn の前提

`game.tscn` は現在おおむね以下の構造を持つ。

```text
Game
├── Background
├── PassiveFlower
├── EnemyLeft      # enemy.tscn のインスタンス
├── EnemyCenter    # enemy.tscn のインスタンス
├── EnemyRight     # enemy.tscn のインスタンス
├── Stomach        # stomach.tscn のインスタンス
├── Character
└── UI             # CanvasLayer
    ├── PassiveGuideFrame
    ├── HpFrame
    ├── TimeBar
    ├── DigestionFrame
    └── StatusPanel
```

すでに `EnemyLeft` / `EnemyCenter` / `EnemyRight` は `res://scene/object/enemy/enemy.tscn` のインスタンスであり、`Stomach` も `res://scene/object/stomach/stomach.tscn` のインスタンスになっている。  
このため、最優先で行うべきことは **既存インスタンスに対応するシーン側へ責務を戻すこと** である。

---

# 優先度A: 必ず最初に解決すること

## A-1. `Enemy` の状態と表示更新を `enemy.tscn` 側へ移す

### 現状の問題

`game.gd` は敵に関する以下をすべて直接管理している。

- 敵名
- 最大HP
- 残りHP
- 胃袋内サイズ
- 胃袋内形状
- 消化中かどうか
- 消化済みかどうか
- 胃袋内セル位置
- 敵テクスチャ
- 敵HPラベル更新
- 敵のhover Tween
- 敵の消化コスト表示パルス

また、以下のような並列配列に依存している。

```gdscript
ENEMY_TEXTURES
ENEMY_START_POSITIONS
ENEMY_STOMACH_SIZES
ENEMY_STOMACH_SHAPES
enemies
enemy_nodes
original_enemy_positions
enemy_base_scales
enemy_cost_base_scales
```

これは敵の追加・削除・順番変更に弱い。

### Codexへの指示

`res://scene/object/enemy/enemy.tscn` のルートに `Enemy.gd` をアタッチし、敵1体の責務をそこへ移す。

`Enemy.gd` が持つべき責務:

- 敵名
- 最大HP
- 現在HP
- 消化中状態
- 消化済み状態
- 胃袋内セル位置
- 胃袋内サイズ
- 胃袋内形状
- 開始位置
- HPラベル更新
- テクスチャ設定
- hover演出
- コスト/HP表示の演出
- 胃袋配置時の見た目リサイズ
- 元位置へ戻る処理

`Game.gd` からは以下のような高レベル操作だけを呼ぶ形にする。

```gdscript
enemy.setup(definition)
enemy.take_digest_damage(amount)
enemy.set_digesting(true)
enemy.set_digested(true)
enemy.return_to_origin()
enemy.set_stomach_cell(cell)
enemy.get_occupied_cells(cell)
```

### 完了条件

- `Game.gd` が `enemy["remaining_hp"]` のような Dictionary キーへ直接アクセスしない。
- `Game.gd` が敵のHPラベルを直接更新しない。
- `Game.gd` が敵のテクスチャを直接設定しない。
- `Game.gd` が `ENEMY_TEXTURES` / `ENEMY_STOMACH_SIZES` / `ENEMY_STOMACH_SHAPES` のような並列配列を持たない。

---

## A-2. 敵データを `Dictionary` ではなく型付きデータにする

### 現状の問題

現在は `var enemies: Array[Dictionary]` として敵データを管理している。  
これはキー名のタイプミスに弱く、Codexが今後修正する際にも破綻しやすい。

例:

```gdscript
enemy["remaining_hp"]
enemy["digesting"]
enemy["stomach_cell"]
```

### Codexへの指示

敵の固定データと実行時状態を分離する。

推奨構成:

```text
res://scene/object/enemy/enemy_definition.gd
res://scene/object/enemy/enemy.gd
```

`EnemyDefinition.gd`:

```gdscript
class_name EnemyDefinition
extends Resource

@export var display_name: String
@export var texture: Texture2D
@export var max_hp: int
@export var size: int
@export var damage: int
@export var start_position: Vector2
@export var stomach_size: Vector2i
@export var stomach_shape: Array[Vector2i]
```

`Enemy.gd` 側は `EnemyDefinition` を受け取り、現在HP・消化状態などのランタイム状態だけを持つ。

### 完了条件

- `Game.gd` 内の `Array[Dictionary]` を廃止する。
- 敵の固定パラメータを1つの定義にまとめる。
- 敵の実行時状態は `Enemy.gd` 側で保持する。

---

## A-3. 胃袋グリッド処理を `Stomach` シーンへ移す

### 現状の問題

`game.gd` が胃袋に関する以下をすべて持っている。

- 胃袋グリッドの原点計算
- セルサイズ計算
- 胃袋矩形判定
- ドロップ位置計算
- 配置可能判定
- 占有セル取得
- 胃袋内重力処理
- 最下段接触判定
- 消化ライン位置計算
- プレビュー表示

これらは `Stomach` シーンの責務であり、`Game.gd` が持つべきではない。

### Codexへの指示

`res://scene/object/stomach/stomach.tscn` のルートに `StomachBoard.gd` をアタッチし、胃袋内の盤面処理を移す。

`StomachBoard.gd` が持つべき責務:

- `columns`
- `rows`
- `cell_size`
- `grid_origin`
- `get_cell_from_global_position(global_position)`
- `get_global_position_for_cell(cell, size)`
- `contains_global_position(global_position)`
- `can_place(enemy, top_left_cell)`
- `place(enemy, top_left_cell)`
- `remove(enemy)`
- `apply_gravity(enemies)`
- `get_current_fullness(enemies)`
- `has_bottom_touching_enemy(enemies)`
- `show_preview(enemy, mouse_position, valid)`
- `hide_preview()`

`Game.gd` は以下のように扱う。

```gdscript
var cell := stomach.get_drop_cell(enemy, mouse_position)
if stomach.can_place(enemy, cell):
    stomach.place(enemy, cell)
else:
    enemy.return_to_origin()
```

### 完了条件

- `Game.gd` から `STOMACH_COLUMNS` / `STOMACH_ROWS` / `stomach_grid_origin` / `stomach_grid_cell_size` / `stomach_grid_step` を撤去する。
- `Game.gd` から `_can_place_enemy_at()` / `_get_enemy_occupied_cells()` / `_apply_stomach_gravity()` 相当の実装を撤去する。
- 胃袋の座標変換は `StomachBoard.gd` に閉じる。

---

## A-4. UI更新を `BattleUI.gd` に分離する

### 現状の問題

`game.gd` が以下のUI要素を直接操作している。

- `TimeBar`
- `TimeText`
- `HpFrame`
- `HpGauge`
- `HpText`
- `MessageText`
- `DebugMessageButton`
- `PassiveGuideText`
- `DigestionFrame`
- `DigestionLabel`
- 時間経過ラベル
- HPダメージプレビュー
- UI用Tween

`Game.gd` はUIの内部ノード構造を知りすぎている。

### Codexへの指示

`game.tscn` の `UI` ノードに `BattleUI.gd` をアタッチする。  
可能なら後続で `BattleUI.tscn` として別シーン化する。

`BattleUI.gd` が持つべき責務:

- HP表示更新
- HPゲージ更新
- 時刻表示更新
- 時間経過演出
- 消化ボタン表示
- 消化ボタンhover演出
- メッセージ表示
- デバッグメッセージ表示
- パッシブガイド表示
- HPダメージプレビュー表示

`Game.gd` からは以下のような高レベルAPIのみ呼ぶ。

```gdscript
ui.set_hp(hp, max_hp)
ui.set_time(minutes)
ui.set_message(message)
ui.set_digestion_button_visible(visible)
ui.show_time_elapsed(amount_minutes)
ui.show_hp_damage_preview(amount, global_position)
ui.hide_hp_damage_preview()
```

消化ボタン押下は `BattleUI.gd` から signal で通知する。

```gdscript
signal digestion_requested
```

`Game.gd` 側:

```gdscript
ui.digestion_requested.connect(_start_auto_digest)
```

### 完了条件

- `Game.gd` が `TimeText` / `HpGauge` / `DigestionLabel` などのUI内部ノードを直接参照しない。
- `Game.gd` のUI更新は `ui.set_*()` 呼び出しに限定される。
- 消化ボタン入力は `BattleUI.gd` から signal で通知される。

---

## A-5. `Game.gd` を全体進行の調停役に限定する

### 目標

`Game.gd` は以下だけを担当する。

- バトル開始
- バトル終了判定
- 時間進行
- プレイヤーHPの増減
- 胃袋・敵・UIの接続
- signal の購読
- ターン進行の指揮

`Game.gd` は個別UI・個別敵・胃袋セル計算・Tween詳細を持たない。

### 完了条件

`Game.gd` の関数はおおむね以下の粒度に収まる。

```gdscript
func start_battle() -> void
func _advance_digest_turn() -> void
func _digest_nightmares() -> void
func _apply_digest_damage() -> void
func _check_battle_end() -> void
func _on_enemy_released(enemy, mouse_position) -> void
func _on_digestion_requested() -> void
func _on_enemy_died(enemy) -> void
```

---

# 優先度B: A完了後に解決すること

## B-1. ドラッグ操作を `DragController.gd` に分離する

### 現状の問題

`Game.gd` が `_input()` 内で以下をすべて行っている。

- マウス押下判定
- 敵矩形判定
- ドラッグ開始
- ドラッグ中座標更新
- ドロップ判定
- 胃袋から取り出した時の処理
- 自動消化一時停止
- プレビュー更新

### Codexへの指示

`DragController.gd` を作成する。  
ドラッグ入力の低レベル処理をここに移す。

`DragController.gd` は、敵を直接配置せず、signal でイベントを通知する。

```gdscript
signal enemy_drag_started(enemy)
signal enemy_drag_moved(enemy, mouse_position)
signal enemy_drag_released(enemy, mouse_position)
```

`Game.gd` は release を受けて `StomachBoard` に問い合わせる。

### 完了条件

- `Game.gd` の `_input()` が大幅に短くなる、または無くなる。
- ドラッグ中の見た目更新は `Enemy.gd` または `DragController.gd` に寄る。
- 配置可否判定は `DragController.gd` ではなく `StomachBoard.gd` が行う。

---

## B-2. 消化自動進行を小さな責務に分ける

### 現状の問題

`game.gd` は `Timer` を生成し、自動消化の開始・停止・一時停止・再開を直接管理している。

### Codexへの指示

必要に応じて `DigestRunner.gd` または `BattleTurnTimer.gd` を作る。  
ただし、Aの責務分離が完了するまでは無理に切り出さなくてよい。

候補API:

```gdscript
signal tick_requested

func start(interval: float) -> void
func stop() -> void
func pause() -> void
func resume() -> void
func set_speed_scale(scale: float) -> void
```

### 完了条件

- `Game.gd` が `Timer.new()` を直接行わない。
- `Game.gd` は `tick_requested` を受けて `_advance_digest_turn()` を呼ぶだけになる。

---

## B-3. `EnemyLeft` / `EnemyCenter` / `EnemyRight` 固定参照を減らす

### 現状の問題

`game.gd` は以下のように敵ノードを固定配列で持っている。

```gdscript
@onready var enemy_nodes: Array[Node2D] = [
    $EnemyLeft,
    $EnemyCenter,
    $EnemyRight,
]
```

敵が3体固定なら動くが、追加・削除・順番変更に弱い。

### Codexへの指示

`game.tscn` の既存構造を尊重しつつ、敵ノードをグループまたは親ノード配下にまとめることを検討する。

推奨構成:

```text
Game
├── Enemies
│   ├── EnemyLeft
│   ├── EnemyCenter
│   └── EnemyRight
```

または、現状維持の場合でも `@export var enemies: Array[Enemy]` として Inspector から割り当てる。

### 完了条件

- 敵数変更時に複数の並列配列を直す必要がない。
- 敵定義と敵インスタンスの対応が明確になる。

---

## B-4. プレビュー表示を `StomachBoard` または専用 `PlacementPreview` に分離する

### 現状の問題

`game.gd` が `stomach_preview_sprite` を生成し、表示・非表示・色変更・サイズ変更を直接行っている。

### Codexへの指示

配置プレビューは以下のどちらかへ移す。

- `StomachBoard.gd` に内包する
- `PlacementPreview.gd` として `Stomach` の子に置く

`Game.gd` からは以下だけ呼ぶ。

```gdscript
stomach.show_preview(enemy, mouse_position)
stomach.hide_preview()
```

### 完了条件

- `Game.gd` がプレビュー用 `Sprite2D` を生成しない。
- プレビューの色・透明度・位置計算は胃袋側に閉じる。

---

# 優先度C: 仕上げ・保守性向上

## C-1. ノードパス直参照を減らす

### 現状の問題

`Game.gd` は多数のUI内部ノード・胃袋内部ノードを直接参照している。

例:

```gdscript
$UI/TimeBar/TimeText
$UI/HpFrame/HpGauge
$Stomach/frame
$Stomach/grid_frame
```

これはシーン構造変更に弱い。

### Codexへの指示

内部ノードへの参照は各シーン内スクリプトへ閉じる。

- UI内部ノードは `BattleUI.gd` のみが知る。
- Stomach内部ノードは `StomachBoard.gd` のみが知る。
- Enemy内部ノードは `Enemy.gd` のみが知る。

### 完了条件

- `Game.gd` の `@onready` 参照は主要シーンのルートに限定される。

例:

```gdscript
@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var enemies_root: Node = $Enemies
```

---

## C-2. `_get_global_rect()` を `Control.get_global_rect()` に置き換える

### 現状の問題

現在の実装は `Control` の scale や一部のレイアウト状況でズレる可能性がある。

```gdscript
func _get_global_rect(control: Control) -> Rect2:
    return Rect2(control.global_position, control.size)
```

### Codexへの指示

`Control` の矩形取得は原則として以下を使う。

```gdscript
control.get_global_rect()
```

### 完了条件

- 手書きの `Rect2(control.global_position, control.size)` を削除する。

---

## C-3. デバッグメッセージ処理を整理する

### 現状の問題

`_update_ui(message)` は `message` を受け取るが、実際には `MessageText` に常に `START_MESSAGE` を入れている。  
関数名と実装の意図がずれている。

### Codexへの指示

以下のどちらかに整理する。

1. `message` を通常メッセージとして画面に表示する。
2. `message` はデバッグ専用として保存し、関数名を `_set_debug_message()` に変更する。

### 完了条件

- `_update_ui(message)` の引数が死んでいない。
- 通常表示とデバッグ表示の責務が分かれている。

---

## C-4. Tween演出を対象オブジェクト側に寄せる

### 現状の問題

`Game.gd` が敵・UI・時間テキスト・HPゲージなど複数対象のTweenをまとめて持っている。

### Codexへの指示

Tweenは原則として、演出対象を持つスクリプトに移す。

- 敵hover演出 → `Enemy.gd`
- 敵コスト演出 → `Enemy.gd`
- 時間テキスト演出 → `BattleUI.gd`
- HPゲージ演出 → `BattleUI.gd`
- 消化ボタンhover演出 → `BattleUI.gd`

### 完了条件

- `Game.gd` が個別UI・個別敵のTween変数を持たない。

---

## C-5. 描画順を `move_child()` ではなく明示的に管理する

### 現状の問題

`game.gd` は `stomach.move_child(stomach_frame, stomach.get_child_count() - 1)` のように子順序を直接変更している。  
意図が読み取りづらく、将来のノード追加に弱い。

### Codexへの指示

描画順は以下のいずれかで明示する。

- `z_index`
- シーンツリー上の固定順
- 背景/グリッド/プレビュー/枠を `Stomach.tscn` 内で整理

### 完了条件

- `Game.gd` が `Stomach` 内部の child order を変更しない。

---

# 最終的な目標構成

理想的な構成例:

```text
res://scene/main/game/
├── game.tscn
└── game.gd

res://scene/object/enemy/
├── enemy.tscn
├── enemy.gd
└── enemy_definition.gd

res://scene/object/stomach/
├── stomach.tscn
└── stomach_board.gd

res://scene/ui/battle_ui/
├── battle_ui.tscn   # 後続で分離してよい
└── battle_ui.gd

res://scene/main/game/
└── drag_controller.gd   # 必要なら
```

`game.tscn` 側の構成例:

```text
Game
├── Background
├── PassiveFlower
├── Enemies
│   ├── EnemyLeft
│   ├── EnemyCenter
│   └── EnemyRight
├── Stomach
├── Character
└── UI
```

---

# Game.gd に残してよい責務

`Game.gd` に残してよいもの:

- バトル開始
- バトル終了
- 勝敗判定
- 時間進行
- プレイヤーHP増減
- 消化ターンの進行
- `Enemy` / `StomachBoard` / `BattleUI` の接続
- signal の購読

`Game.gd` に残さないもの:

- UI内部ノードの直接操作
- Enemy内部ノードの直接操作
- Stomach内部ノードの直接操作
- 敵のHPラベル更新
- 胃袋グリッドの座標計算
- 胃袋配置プレビューのSprite生成
- 敵のhover Tween
- UIのTween詳細
- Dictionary形式の敵状態管理

---

# Codex作業時の注意

## 一度にすべて書き換えない

優先度Aを最初に行う。  
BとCはA完了後に行う。

## 既存の見た目を壊さない

`game.tscn` にはすでに以下のインスタンスが存在する。

- `EnemyLeft`
- `EnemyCenter`
- `EnemyRight`
- `Stomach`
- `UI`

まずはこれらの既存シーンを活かして、責務だけを移す。

## signal と関数呼び出しを使い分ける

signal を使うべきもの:

- 敵が死亡した
- 敵HPが変化した
- UIの消化ボタンが押された
- ドラッグが完了した

通常関数でよいもの:

- `stomach.can_place(enemy, cell)`
- `enemy.get_occupied_cells(cell)`
- `ui.set_hp(hp, max_hp)`
- `ui.set_time(minutes)`

## 目標

最終的に `Game.gd` は「ゲーム全体の進行を読むファイル」になっていること。  
`Game.gd` を読んだだけで、敵の内部UIや胃袋のセル計算やTween詳細まで読まされる状態は避ける。
