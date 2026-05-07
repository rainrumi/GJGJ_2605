# Godot シーン責務分離・疎結合化リファクタリング指示書 for Codex

## 目的

このドキュメントは、既存の Godot プロジェクトに対して、Godot らしいシーン設計・スクリプト設計へ寄せるためのリファクタリング指示である。

対象コードには、1つのルートスクリプトにゲーム進行、UI更新、入力処理、データ定義、演出、状態管理が集中している箇所がある。これを避け、各シーンを「自己完結した責務単位」として扱える構成へ改善する。

この指示書は、特定シーン専用ではなく、今後追加されるシーンにも適用できる共通ルールとして使用する。

---

## 最重要方針

Godotでは、Unityのように1つのGameObjectへ多数のComponentを積み重ねる設計よりも、**Sceneを再利用可能な自己完結オブジェクトとして設計する**方針を優先する。

ただし、「自己完結」とは、1つのルートスクリプトに全処理を書くことではない。

正しい方針は次の通り。

```text
Scene = そのオブジェクト・画面・UI部品が責任を持つ範囲をまとめた単位
Root Script = そのSceneの公開API、内部ノード制御、状態遷移を統括する窓口
Child Script = UI部品、入力部品、演出部品、データ表示部品などの局所責務を持つ部品
Signal = 上位シーンや他責務へ状態変化を通知する手段
Direct Call = 親から子へ明示的に命令する手段
Resource = 外部化すべき定義データ・設定データ
```

---

# A. 必ず解決する問題

## A-1. ルートスクリプトへの責務集中を解消する

### 問題

現在のコードには、1つのルートスクリプトが以下のような複数責務を同時に持つ傾向がある。

- 画面全体の進行管理
- 入力処理
- UI表示更新
- ボタンやパネルの演出
- キャラクター・敵・アイテムなどの状態管理
- グリッド・配置・判定処理
- 時間・HP・スコアなどの数値管理
- データ定義の生成
- 効果音再生
- デバッグメッセージ管理
- 遷移完了通知

これは Godot の `Scene = 自己完結単位` という考え方とは一致しない。

### 修正方針

ルートスクリプトは、画面または機能全体の**調停役**に限定する。

ルートスクリプトに残してよい処理は次の範囲とする。

- 子シーン・子ノードの初期化順制御
- 子シーン間の signal 接続
- 画面全体の大きな状態遷移
- 外部シーンへ公開する最小限の API
- 外部へ通知する signal の emit
- 複数の子シーンをまたぐ処理の調停

ルートスクリプトから分離すべき処理は次の通り。

| 分離対象 | 移動先の例 |
|---|---|
| UIテキスト・ゲージ・ボタン状態の更新 | UI専用シーン / UI Presenter |
| ボタンのhover/pressed演出 | 汎用ボタン部品 / Button View |
| 選択肢表示 | 選択肢アイテムシーン |
| 配置判定・座標変換・グリッド管理 | Board / Grid / Placement 専用シーン |
| キャラクター・敵・アイテムの状態 | 個別 Entity シーン |
| データ定義 | Resource |
| 入力ドラッグ処理 | Input Controller / Drag Controller |
| 効果音再生 | Audio Controller |
| Tween演出 | 対象ViewまたはAnimation専用コンポーネント |
| シーン遷移要求 | 親シーンへの signal |

### Codex作業指示

- ルートスクリプトから、UI更新、入力処理、演出、データ定義、判定処理を抽出する。
- ルートスクリプトは「子へ命令する」「子から通知を受ける」「全体状態を進める」だけに近づける。
- 1つのスクリプトが 200 行を超える場合は、責務分割候補として扱う。
- 1つの関数が UI更新とゲーム状態変更を同時に行っている場合は分割する。

---

## A-2. Dictionaryベースのデータ定義を Resource へ置き換える

### 問題

現在のコードには、複数の値を `Dictionary` に詰めて、文字列キーで参照するパターンがある。

```gdscript
var data := {
    "id": "...",
    "name": "...",
    "value": 10,
    "texture": preload("..."),
}
```

これは次の問題を持つ。

- キー名の typo をコンパイル時に検出できない
- データ構造がコード上で明確にならない
- Inspector で編集しにくい
- アセット参照と数値定義がルートスクリプトに混ざる
- データが増えたときに保守しにくい

### 修正方針

定義データは `Resource` として外部化する。

例：

```gdscript
class_name EntityDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var numeric_value: int
@export var category: StringName
```

複数種類の効果や能力を持つ場合は、効果も Resource 化する。

```gdscript
class_name EffectData
extends Resource

func apply(context: EffectContext) -> void:
    pass
```

```gdscript
class_name NumericEffectData
extends EffectData

@export var amount: int

func apply(context: EffectContext) -> void:
    # 実処理はプロジェクト側の対象APIに合わせて実装する
    pass
```

### Codex作業指示

- `Array[Dictionary]` や `const SOME_OPTIONS: Array[Dictionary]` は Resource 化候補として扱う。
- `name`, `rarity`, `effect`, `texture`, `frame`, `size`, `damage`, `shape`, `start_position` のような定義値はコード内ハードコードから外す。
- まず `Resource` クラスを定義し、`.tres` で管理できる形にする。
- 既存のコード内定義は、一時的な移行関数ではなく、最終的に `@export var definitions: Array[...Definition]` で注入できるようにする。
- データ定義と実行時状態を混ぜない。

---

## A-3. UI表示ロジックを Presenter / View に分離する

### 問題

現在のコードには、ゲーム進行スクリプトが直接 UI ノードへアクセスしている箇所がある。

例：

```gdscript
label.text = "..."
gauge.size = ...
button.disabled = true
texture_rect.texture = ...
```

この状態では、UI構造が少し変わるだけで、ゲーム進行コードも壊れる。

### 修正方針

UIの内部ノードは、UIシーン自身が隠蔽する。

ルートスクリプトや上位シーンは、UIの内部ノード名を知らないようにする。

良い例：

```gdscript
ui_view.set_status_text(message)
ui_view.set_value(current, max_value, animated)
ui_view.set_options(option_list)
ui_view.set_interactable(enabled)
```

悪い例：

```gdscript
$UI/Panel/Label.text = message
$UI/Panel/Gauge.size.x = value
$UI/Menu/Button.disabled = true
```

### Codex作業指示

- UI内部ノードへの直接アクセスを、UIシーンの公開メソッドへ移す。
- UIシーン側に `set_xxx()`, `show_xxx()`, `hide_xxx()`, `reset_xxx()` を定義する。
- 上位シーンは UI の内部構造を参照しない。
- UI更新関数内でゲーム進行状態を変更しない。
- UIの signal は「ユーザーが何を要求したか」を通知する命名にする。

例：

```gdscript
signal action_requested
signal option_selected(index: int)
signal cancel_requested
```

---

## A-4. 入力処理をゲームロジックから分離する

### 問題

現在のコードには、`_input()` や `_process()` の中で、入力判定、ドラッグ処理、配置判定、状態更新、UI更新が連続して行われる構造がある。

これは入力方式を変更した時に破綻しやすい。

### 修正方針

入力処理は「ユーザー操作を抽象イベントへ変換する責務」に限定する。

入力担当は、ゲーム状態を直接大きく変更しない。

良い例：

```gdscript
signal drag_started(target: Node, pointer_position: Vector2)
signal drag_moved(target: Node, pointer_position: Vector2)
signal drag_released(target: Node, pointer_position: Vector2)
signal action_pressed(action_id: StringName)
```

上位側または専用Controllerが、これらの signal を受けてゲーム状態を変更する。

### Codex作業指示

- `_input()` から直接ゲーム状態を変更している箇所を抽出する。
- 入力担当スクリプトを作成し、入力を signal 化する。
- 配置可能かどうか、HPを減らすかどうか、ターンを進めるかどうかは入力担当では判断しない。
- マウス、タッチ、ゲームパッドに置き換えやすいAPIへ寄せる。

---

## A-5. 子から親への直接参照を減らし、signalで通知する

### 問題

Godotでは親から子への参照は自然だが、子が親や兄弟ノードを直接参照し始めると依存が強くなる。

### 修正方針

原則：

```text
親 → 子：直接参照・メソッド呼び出し可
子 → 親：signalで通知
兄弟 → 兄弟：親またはControllerが仲介
```

良い例：

```gdscript
# child.gd
signal requested(payload)

func _on_pressed() -> void:
    requested.emit(payload)
```

```gdscript
# parent.gd
child.requested.connect(_on_child_requested)
```

悪い例：

```gdscript
get_parent().get_node("OtherChild").do_something()
```

### Codex作業指示

- 子シーンが親のノードパスを直接参照している場合、signalへ置き換える。
- 兄弟ノード間の直接参照は避ける。
- 親シーンまたは専用Controllerが接続係になる。
- signal名は「結果」または「要求」を表す名前にする。

---

# B. 優先して改善する問題

## B-1. 共通UI部品を再利用可能シーンにする

### 問題

複数箇所で同じような hover / pressed / disabled / scale tween の処理が重複しやすい。

### 修正方針

同じ見た目・同じ振る舞いのUIは、共通シーン化する。

例：

```text
ReusableButton.tscn
SelectableItemView.tscn
ValueGaugeView.tscn
MessageView.tscn
```

それぞれのルートスクリプトが内部演出を持つ。

上位シーンは、次のような公開APIだけを呼ぶ。

```gdscript
button_view.set_text(text)
button_view.set_disabled(disabled)
item_view.setup(data)
gauge_view.set_value(current, max_value, animated)
```

### Codex作業指示

- hover / pressed / disabled / Tween の共通処理をUI部品側へ移す。
- 上位シーンに個別ボタンのscale処理を書かない。
- 複数箇所に同じ演出コードがある場合、共通コンポーネント化する。

---

## B-2. 画面状態を明示的な State として扱う

### 問題

複数の bool によって画面状態が表現されている箇所がある。

例：

```gdscript
var active := false
var paused := false
var in_progress := false
var selected := false
```

bool が増えると、存在しない状態の組み合わせが発生しやすい。

### 修正方針

状態が3つ以上ある場合は `enum` を使う。

```gdscript
enum ScreenState {
    HIDDEN,
    INTRO,
    ACTIVE,
    WAITING,
    FINISHED,
}

var state := ScreenState.HIDDEN
```

状態変更は1つの関数に集約する。

```gdscript
func _change_state(next_state: ScreenState) -> void:
    if state == next_state:
        return
    _exit_state(state)
    state = next_state
    _enter_state(state)
```

### Codex作業指示

- 3個以上の bool で画面進行を管理している場合、enum State へ置き換える。
- 状態変更時にUI更新、入力可否、Timer開始停止をまとめる。
- 各関数が勝手に複数boolを書き換えないようにする。

---

## B-3. TimerとTweenの所有者を明確にする

### 問題

TimerやTweenが、どの責務のために存在しているか曖昧になっている箇所がある。

### 修正方針

TimerとTweenは、それを必要とするシーン・Viewが所有する。

| 用途 | 所有者 |
|---|---|
| UIフェード | UIシーン |
| ボタンhover演出 | ボタン部品シーン |
| 自動進行 | 進行Controller |
| ダメージ演出 | 対象EntityまたはView |
| 値ゲージ更新 | ゲージView |

### Codex作業指示

- Tween処理を上位シーンに集めない。
- 見た目だけのTweenは View 側へ移す。
- ロジック進行のTimerは Controller 側へ置く。
- Tweenを作成する前に既存Tweenをkillするパターンは共通化できる場合は共通化する。

---

## B-4. ノードパス依存を減らす

### 問題

深いノードパスへのアクセスが増えると、シーン構造変更に弱くなる。

悪い例：

```gdscript
@onready var label := $Root/Panel/Container/Label
```

### 修正方針

上位シーンが参照してよいのは、基本的に直下の責務単位シーンだけにする。

良い例：

```gdscript
@onready var ui_view: UIView = $UIView
@onready var controller: FlowController = $FlowController
@onready var board: BoardView = $BoardView
```

各責務シーンの内部ノードは、その責務シーンのスクリプト内でのみ参照する。

### Codex作業指示

- `$A/B/C/D` のような深い参照は、可能な限り `$A` への参照に置き換える。
- 中間ノードにスクリプトを追加し、公開APIを作る。
- `get_node("child_name")` を多用する箇所は、専用Viewへ分離する。

---

## B-5. 実行時状態と定義データを分離する

### 問題

定義データとプレイ中に変化する状態が同じデータ構造に混ざると、リセット・保存・再利用が難しくなる。

### 修正方針

次の2種類を分ける。

```text
Definition: 変化しない設定値
State: 実行中に変化する値
```

例：

```gdscript
class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var base_value: int
```

```gdscript
class_name ItemState
extends RefCounted

var definition: ItemDefinition
var current_value: int
var is_active := false
```

### Codex作業指示

- `Resource` に実行中に変わるHP、選択状態、配置座標などを直接保存しない。
- 実行時状態は `RefCounted` または Scene インスタンスが持つ。
- 初期化時に `Definition` から `State` を生成する。

---

# C. 余裕があれば改善する問題

## C-1. 命名規則を統一する

### 方針

- シーンルートのスクリプト名は、シーンの責務名に合わせる。
- View系は `XxxView`、Controller系は `XxxController`、定義データは `XxxDefinition`、実行時状態は `XxxState` を推奨する。
- signal名は過去形または要求形にする。

例：

```gdscript
signal selected(data)
signal confirmed(result)
signal cancelled
signal action_requested(action_id: StringName)
```

避ける名前：

```gdscript
signal button
signal start
signal update
```

---

## C-2. 公開APIと内部関数を区別する

### 方針

- 外部から呼んでよい関数は `setup`, `reset`, `show`, `hide`, `set_value`, `get_value` など明確な名前にする。
- 内部処理は `_` で始める。
- 外部から `_private_method()` を呼ばない。

例：

```gdscript
func setup(data: SomeDefinition) -> void:
    _apply_data(data)

func _apply_data(data: SomeDefinition) -> void:
    pass
```

---

## C-3. マジックナンバーを設定データへ移す

### 方針

調整対象の値は、ルートスクリプトの `const` に集めすぎない。

次のような値は Resource または Project Settings へ移す候補にする。

- HP、攻撃力、回復量
- 表示時間
- Tween時間
- スケール倍率
- 配置サイズ
- 制限数
- 表示文言
- 画像参照

---

## C-4. 表示文言をコードから分離する

### 方針

頻繁に変わる文言、翻訳対象になる文言、UI上に表示される文言は、将来的にCSV/JSON/Resourceへ移す。

Codexはただちに全文言管理システムを作る必要はないが、コード内に表示文言が増え続ける構造は避ける。

---

# 推奨ディレクトリ構成

特定シーンに依存しない推奨構成は次の通り。

```text
res://scene/
  feature_name/
    feature_root.tscn
    feature_root.gd
    parts/
      reusable_part.tscn
      reusable_part.gd
    views/
      feature_view.tscn
      feature_view.gd
    controllers/
      feature_controller.gd

res://data/
  definitions/
    entity_definition.gd
    option_definition.gd
    effect_data.gd
  resources/
    *.tres

res://autoload/
  app_state.gd
  scene_router.gd
  audio_service.gd
```

ただし、Autoloadは濫用しない。共有状態や横断サービスに限定する。

---

# 推奨シーン構成ルール

## 1. 画面シーン

画面全体を表すシーンは、次の構成を基本とする。

```text
ScreenRoot
├── ViewRoot
├── LogicController
├── InputController
├── AudioController
└── ChildFeatureScenes
```

ScreenRoot のスクリプトは、以下を担当する。

- 子の初期化
- signal接続
- 外部API
- 状態遷移
- 子同士の橋渡し

ScreenRoot のスクリプトは、以下を直接担当しない。

- UI部品の細かい見た目変更
- 個別ボタンのhover演出
- 個別データの定義
- 子シーン内部ノードの操作
- 入力イベントの詳細処理

---

## 2. UI部品シーン

UI部品シーンは、次の構成を基本とする。

```text
UIPartRoot
├── VisualNodes
└── OptionalChildParts
```

UI部品のルートスクリプトは、以下を担当する。

- 表示内容の反映
- disabled / selected / hovered などの見た目管理
- 自分自身のTween演出
- ユーザー操作の signal emit

UI部品は、親シーンの状態を直接変更しない。

---

## 3. Entityシーン

ゲーム内オブジェクトは、次の構成を基本とする。

```text
EntityRoot
├── Visual
├── Collision
├── Animation
└── OptionalUI
```

Entity のルートスクリプトは、以下を担当する。

- 自分の状態管理
- 自分の表示更新
- 自分のアニメーション
- 自分への命令API
- 状態変化の signal emit

Entity は、全体進行や他Entityの状態を直接管理しない。

---

## 4. Board / Grid / Placement系シーン

グリッドや配置を扱うシーンは、次の責務を持つ。

- 座標変換
- 配置可能判定
- 占有情報管理
- プレビュー表示
- 配置確定処理
- 必要なら重力・整列・再配置処理

UIやHP管理など、配置と無関係な処理は持たない。

---

# signal と direct call の使い分け

## signal を使うべき場面

- 子が親へ「押された」「選ばれた」「完了した」「キャンセルされた」を通知する
- Entityが「死亡した」「値が変わった」「処理が終わった」を通知する
- UIが「ユーザーが操作を要求した」を通知する
- 処理結果を上位へ返す

## direct call を使うべき場面

- 親が子へ表示更新を命令する
- 親が子へ初期化データを渡す
- Controller が Board に `can_place()` を問い合わせる
- Controller が View に `set_value()` を命令する

## 避けるべき場面

- 子が親のメソッドを直接呼ぶ
- 兄弟ノードを直接参照する
- UIがゲームロジックを直接変更する
- Entityが画面遷移を直接行う

---

# リファクタリング時の作業順

Codexは以下の順番で作業する。

## Step 1: 責務分類

各スクリプト内の関数を次の分類に分ける。

```text
Flow: 画面進行・ゲーム進行
View: UI表示更新
Input: 入力処理
Entity: 個別オブジェクト状態
Board: 配置・座標・判定
Data: 定義データ
Audio: 音
Animation: Tween・演出
Utility: 汎用処理
```

## Step 2: Data を Resource 化

- Dictionary定義を Resource へ移す。
- `@export var definitions: Array[DefinitionType]` にする。
- 実行時状態は `State` として分ける。

## Step 3: View を分離

- UI内部ノード操作を View スクリプトへ移す。
- 上位は View の公開APIのみ呼ぶ。

## Step 4: Input を分離

- `_input()` 内の詳細処理を InputController へ移す。
- signalで操作イベントを通知する。

## Step 5: Entity / Board を分離

- 個別オブジェクトの状態・表示・操作を Entity へ移す。
- 配置や座標判定を Board へ移す。

## Step 6: Root を薄くする

- ルートスクリプトは signal 接続と状態遷移に集中させる。
- 直接のノードパス参照を減らす。

## Step 7: 動作確認

最低限、以下を確認する。

- シーンが起動する
- UI操作が signal 経由で上位に届く
- 上位が子Viewを公開API経由で更新できる
- Resourceが未設定でもエラーを出して落ちにくい
- 既存の主要フローが維持されている

---

# Codexへの禁止事項

以下を行わないこと。

1. ルートスクリプトへさらに処理を追加しない。
2. 子シーンから親シーンのノードパスを直接参照しない。
3. UI内部ノードを上位シーンから直接操作しない。
4. 新しい `Dictionary` ベースの定義データを増やさない。
5. 効果・選択肢・Entity定義をコード内の巨大配列として追加しない。
6. Signalを使うべき通知を、親メソッドの直接呼び出しで実装しない。
7. すべてをAutoloadに逃がさない。
8. 1つの巨大Managerを新設して責務集中を移動するだけの修正をしない。
9. 既存の見た目を大きく変えるリファクタリングを同時に行わない。
10. 動作と責務分割を同時に大幅変更して原因追跡不能にしない。

---

# Codexへの推奨実装パターン

## ルートシーンの例

```gdscript
extends Node

@onready var view: ScreenView = $ScreenView
@onready var input_controller: InputController = $InputController
@onready var flow_controller: FlowController = $FlowController

func _ready() -> void:
    input_controller.action_requested.connect(_on_action_requested)
    flow_controller.state_changed.connect(_on_state_changed)

func setup(context: ScreenContext) -> void:
    flow_controller.setup(context)
    view.setup(context)

func _on_action_requested(action_id: StringName) -> void:
    flow_controller.handle_action(action_id)

func _on_state_changed(state: ScreenState) -> void:
    view.apply_state(state)
```

## UI View の例

```gdscript
class_name ScreenView
extends Control

@onready var message_label: Label = $MessageLabel

func setup(context: ScreenContext) -> void:
    apply_state(context.initial_state)

func set_message(text: String) -> void:
    message_label.text = text

func apply_state(state: ScreenState) -> void:
    pass
```

## UI部品の例

```gdscript
class_name SelectableItemView
extends Button

signal selected(data)

var _data

func setup(data) -> void:
    _data = data
    _refresh_view()

func _ready() -> void:
    pressed.connect(_on_pressed)

func _on_pressed() -> void:
    selected.emit(_data)

func _refresh_view() -> void:
    pass
```

## Resource 定義の例

```gdscript
class_name OptionDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var effects: Array[EffectData]
```

## 効果 Resource の例

```gdscript
class_name EffectData
extends Resource

func apply(context: EffectContext) -> void:
    push_warning("EffectData.apply() is not implemented.")
```

---

# 完了条件

Codexは、リファクタリング後に以下を満たすこと。

- ルートスクリプトが各責務の詳細を持たない。
- UI内部ノードはUIシーンのスクリプト内に隠蔽されている。
- 子から親への通知は signal で行われている。
- 定義データは Resource 化されている。
- 実行時状態と定義データが分離されている。
- 入力処理とゲームロジックが分離されている。
- TweenやTimerの所有者が明確である。
- 既存の見た目・操作感を可能な限り維持している。
- 特定シーン名や特定ノード名に依存しない共通設計として再利用できる。

---

# 最終判断基準

リファクタリング後、以下の質問に「はい」と答えられる状態を目指す。

1. このシーンは、何を担当するシーンか一文で説明できるか。
2. ルートスクリプトは調停役に近いか。
3. UIの細部はUIシーン自身が管理しているか。
4. 子シーンは親を知らず、signalで通知しているか。
5. 定義データはコードから切り離されているか。
6. 実行時状態はDefinitionとは別に管理されているか。
7. 入力方法を変更してもゲームロジックを大きく変えずに済むか。
8. 新しい選択肢、効果、Entityを追加するとき、巨大なルートスクリプトを編集せずに済むか。
9. UI構造を変更しても、ゲーム進行コードを壊しにくいか。
10. 1つのManagerに責務が再集中していないか。
