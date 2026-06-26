# Codex実装指示: BattleUIのツールチップ排他管理リファクタ

## 目的

Godotプロジェクト内の戦闘UIツールチップを、複数同時表示されない排他管理に変更する。

現在の `BattleUI` は `_hide_all_tooltips()` で `Enemy` / `AcidDamageView` / `AcidIntervalView` / `TimeView` / `HpView` の全候補を直接非表示にしている。これをやめて、`BattleUI` が「現在表示中のツールチップ所有者」と「その非表示処理」だけを保持する形に変更する。

設計概念は **Single Source of Truth**。ツールチップ表示状態を各Viewや各Enemyに分散させず、戦闘画面内では `BattleUI` が一元管理する。

## 対象

主対象:

- `battle_ui.gd`

必要に応じて確認・修正する対象:

- `AcidDamageView`
- `AcidIntervalView`
- `TimeView`
- `HpView`
- `Enemy`
- 上記Viewの `tooltip_requested` をemitしている箇所

## 実装方針

### 1. AutoloadのTooltipManagerは作らない

今回は戦闘UI専用の要件なので、グローバルなAutoload Managerは作らない。

`BattleUI` を戦闘画面内のTooltipManagerとして扱う。

### 2. `_tooltip_enemy` を汎用的な現在ツールチップ管理に置き換える

現在の変数:

```gdscript
var _tooltip_enemy: Enemy
```

を削除し、以下を追加する。

```gdscript
var _current_tooltip_owner: Object = null
var _current_tooltip_hide: Callable = Callable()
```

### 3. 共通の排他表示メソッドを追加する

`BattleUI` に以下のメソッドを追加する。

```gdscript
func _show_exclusive_tooltip(
	owner: Object,
	show_callable: Callable,
	hide_callable: Callable
) -> void:
	if owner == null:
		return

	if _current_tooltip_owner != owner:
		_hide_current_tooltip()

	_current_tooltip_owner = owner
	_current_tooltip_hide = hide_callable

	if show_callable.is_valid():
		show_callable.call()
```

### 4. 現在表示中のツールチップだけを消すメソッドを追加する

`BattleUI` に以下のメソッドを追加する。

```gdscript
func _hide_current_tooltip(owner: Object = null) -> void:
	if owner != null and owner != _current_tooltip_owner:
		return

	if _current_tooltip_hide.is_valid():
		_current_tooltip_hide.call()

	_current_tooltip_owner = null
	_current_tooltip_hide = Callable()
```

重要:

- `owner` が指定されていて、現在表示中のownerと違う場合は何もしない。
- これにより、古いUI要素や古いEnemyの `mouse_exited` 相当の処理が後から来ても、新しく表示されたツールチップを誤って消さない。

### 5. `_hide_all_tooltips()` の中身を変更する

現在のように全候補へ直接 `hide_tooltip()` を呼ばない。

変更後:

```gdscript
func _hide_all_tooltips() -> void:
	_hide_current_tooltip()
```

名前は既存呼び出しとの互換性のため `_hide_all_tooltips()` のままでよい。

### 6. View系ツールチップの表示処理を共通化する

`BattleUI` に以下を追加する。

```gdscript
func _show_view_tooltip(view: Object) -> void:
	var show_func := func() -> void:
		if is_instance_valid(view):
			view.show_tooltip()

	var hide_func := func() -> void:
		if is_instance_valid(view):
			view.hide_tooltip()

	_show_exclusive_tooltip(view, show_func, hide_func)
```

既存のハンドラを以下の形に変更する。

```gdscript
func _on_acid_damage_tooltip_requested(view: AcidDamageView) -> void:
	_show_view_tooltip(view)


func _on_acid_interval_tooltip_requested(view: AcidIntervalView) -> void:
	_show_view_tooltip(view)


func _on_time_tooltip_requested(view: TimeView) -> void:
	_show_view_tooltip(view)


func _on_hp_tooltip_requested(view: HpView) -> void:
	_show_view_tooltip(view)
```

### 7. Enemyツールチップ表示処理を排他管理へ変更する

現在の `show_enemy_tooltip()` / `hide_enemy_tooltip()` を以下の方針に変更する。

```gdscript
func show_enemy_tooltip(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	var show_func := func() -> void:
		if is_instance_valid(enemy):
			enemy.show_tooltip(debug_number_text, debug_numbers_visible)

	var hide_func := func() -> void:
		if is_instance_valid(enemy):
			enemy.hide_tooltip()

	_show_exclusive_tooltip(enemy, show_func, hide_func)


func hide_enemy_tooltip(enemy: Enemy = null) -> void:
	_hide_current_tooltip(enemy)
```

既存コードが `hide_enemy_tooltip()` を引数なしで呼んでいる場合は、現在表示中のツールチップを消す挙動になる。

Enemy側から「自分のツールチップだけ消してほしい」場合は、可能なら `hide_enemy_tooltip(enemy)` として呼ぶ。

### 8. 既存の公開メソッドは直接Viewをhideしない

現在のような実装は避ける。

```gdscript
func hide_time_tooltip() -> void:
	time_view.hide_tooltip()
```

代わりに、現在表示中のownerチェックを通す。

```gdscript
func hide_time_tooltip() -> void:
	_hide_current_tooltip(time_view)
```

同様に以下も変更する。

```gdscript
func hide_acid_damage_view_tooltip() -> void:
	_hide_current_tooltip(acid_damage_view)


func hide_acid_acid_interval_view_tooltip() -> void:
	_hide_current_tooltip(acid_interval_view)


func hide_time_tooltip() -> void:
	_hide_current_tooltip(time_view)


func hide_hp_tooltip() -> void:
	_hide_current_tooltip(hp_view)
```

### 9. `show_acid_acid_interval_view_tooltip` の命名について

現在のメソッド名:

```gdscript
func show_acid_acid_interval_view_tooltip() -> void:
```

は `acid_acid` が重複している。

ただし、外部参照がある可能性があるため、単純削除はしない。

推奨対応:

```gdscript
func show_acid_interval_view_tooltip() -> void:
	_on_acid_interval_tooltip_requested(acid_interval_view)


# Backward compatibility for the old typo name.
func show_acid_acid_interval_view_tooltip() -> void:
	show_acid_interval_view_tooltip()
```

非表示側も同様に、可能なら正しい名前を追加し、旧名はaliasとして残す。

```gdscript
func hide_acid_interval_view_tooltip() -> void:
	_hide_current_tooltip(acid_interval_view)


# Backward compatibility for the old typo name.
func hide_acid_acid_interval_view_tooltip() -> void:
	hide_acid_interval_view_tooltip()
```

既存参照を全て安全に更新できる場合のみ、旧名削除を検討する。

### 10. mouse enter / exit の扱い

`_on_mouse_entered()` / `_on_mouse_exited()` は、Unityの `OnMouseEnter` のようにメソッド名だけで自動実行されるものとして扱わない。

Godotでは `mouse_entered` / `mouse_exited` signal を接続して使う。

Control系Viewでは、各View側で以下のようなsignal構成にするのが望ましい。

```gdscript
signal tooltip_requested(view)
signal tooltip_hide_requested(view)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)

func _on_mouse_exited() -> void:
	tooltip_hide_requested.emit(self)
```

ただし、すでにEditor上でsignal接続済みなら、重複接続しないこと。

### 11. hide要求signalが存在するならBattleUIに接続する

View側に `tooltip_hide_requested` が存在する、または追加した場合、`BattleUI._connect_child_signals()` で接続する。

例:

```gdscript
acid_damage_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
acid_interval_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
time_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
hp_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
```

共通ハンドラ:

```gdscript
func _on_tooltip_hide_requested(view: Object) -> void:
	_hide_current_tooltip(view)
```

ただし、既存Viewに `tooltip_hide_requested` がなく、今回の変更範囲を `battle_ui.gd` に限定する必要がある場合は、この追加は必須ではない。

### 12. mouse signalを使うViewの注意点

Control系ノードで `mouse_entered` / `mouse_exited` を使う場合、以下を確認する。

- `mouse_filter` が `Control.MOUSE_FILTER_IGNORE` ではないこと
- Controlの `size` が0ではないこと
- 上に別のControlが被っている場合、上のControlが入力を奪っていないこと
- ツールチップ本体はマウス判定を邪魔しないように、可能なら `mouse_filter = Control.MOUSE_FILTER_IGNORE` にすること

Enemyが `Area2D` / `CollisionObject2D` 系の場合は以下を確認する。

- `input_pickable == true`
- collision layer が1つ以上有効
- 当たり判定Shapeが有効

## 避ける実装

以下は避ける。

```gdscript
func _hide_all_tooltips() -> void:
	hide_enemy_tooltip()
	acid_damage_view.hide_tooltip()
	acid_interval_view.hide_tooltip()
	time_view.hide_tooltip()
	hp_view.hide_tooltip()
```

理由:

- 新しいtooltip対象が増えるたびに `_hide_all_tooltips()` を修正する必要がある
- View一覧を `BattleUI` が過剰に知ることになる
- 古いownerからのhide要求で新しいtooltipが消える事故を防ぎにくい

また、以下も避ける。

```gdscript
get_tree().get_nodes_in_group("tooltip")
```

理由:

- 現在表示中のownerが不明確になる
- 排他管理の責務が曖昧になる
- 将来の追加・削除で壊れやすい

## 期待する最終状態

`BattleUI` は以下の状態を満たすこと。

- ツールチップ表示状態を `_current_tooltip_owner` と `_current_tooltip_hide` で一元管理している
- 新しいツールチップ表示要求が来たら、現在表示中の1個だけを非表示にしてから新しいものを表示する
- `_hide_all_tooltips()` は現在表示中の1個だけを消す
- `acid_damage_view` / `acid_interval_view` / `time_view` / `hp_view` の表示処理は `_show_view_tooltip()` に集約されている
- `Enemy` tooltipも同じ排他管理に参加している
- 古いownerからのhide要求では、新しいownerのtooltipを消さない
- 既存のpublic method名は原則維持する
- `show_acid_acid_interval_view_tooltip` のような既存タイポ名は、外部参照を壊さないようにaliasとして残す

## 受け入れ条件

次の条件を満たすこと。

1. `AcidDamageView` tooltipを表示中に `TimeView` tooltipを表示すると、`AcidDamageView` tooltipは消え、`TimeView` tooltipだけが表示される。
2. `Enemy` tooltipを表示中に `HpView` tooltipを表示すると、`Enemy` tooltipは消え、`HpView` tooltipだけが表示される。
3. `HpView` tooltipを表示後、古い `Enemy` のhide処理が遅れて呼ばれても、`HpView` tooltipは消えない。
4. `reset_for_battle()` 実行時、表示中のtooltipは消える。
5. `_ready()` 実行後、tooltipは表示されていない。
6. GDScriptの構文エラーがない。
7. 既存のsignal中継処理、seed drag処理、debug処理、HP/time/acid表示更新処理の挙動を変えない。

## 動作確認手順

可能なら以下を手動確認する。

1. 戦闘画面を開く。
2. HP、時間、消化ダメージ、消化間隔の各UIにマウスを乗せる。
3. どの順番で乗せてもtooltipが常に1つだけ表示されることを確認する。
4. UI要素間を素早く移動してもtooltipが残留しないことを確認する。
5. Enemyにマウスを乗せた後、UI tooltipを表示し、Enemy tooltipが残らないことを確認する。
6. UI tooltip表示中にEnemy側のhide処理が呼ばれても、現在のUI tooltipが誤って消えないことを確認する。
7. 戦闘リセット時にtooltipが消えることを確認する。

## 補足

今回の変更は、ツールチップの見た目や内容を変えるためのものではない。

目的はあくまで「表示状態の所有者を `BattleUI` に集約し、同時表示・残留・古いhide要求による誤消去を防ぐこと」。
