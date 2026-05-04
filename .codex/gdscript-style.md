# GDScriptの書き方

## 言語レベル

- Godot 4系のGDScript構文を使う。
- 現在のスクリプトに合わせて、型付き変数と戻り値型を優先する。
- シーン上で編集する値には `@export` を使う。
- ノード参照には `@onready var name: Type = $NodePath` を使う。
- スクリプトが所有するイベントには `signal name` を使う。

## フォーマット

- GDScriptのブロックインデントはタブを使う。
- 関数は短く、処理が追いやすい形にする。
- 主要な関数の間には空行を入れる。
- コメントは日本語でよい。ただし短く、目的が分かる内容にする。
- 装飾的な区切りコメントや、説明過多なコメントを追加しない。

## 命名規則

既存の書き方に合わせること。

```gdscript
@onready var score_timer: Timer = $ScoreTimer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func update_score(score: int) -> void:
	...

func _on_score_timer_timeout() -> void:
	...
```

- ファイル名: `player.gd`、`mob.gd`、`hud.gd` のような小文字名。
- 関数名・変数名: `snake_case`。
- 入力アクション名: `move_right`、`start_game` のような `snake_case`。
- シーン名・ノード名: `Player`、`MobTimer`、`HUD` のようなGodot標準寄りのPascalCaseまたは略語表記。
- シーンから接続された信号ハンドラ: `_on_<node>_<signal>()` 形式を優先する。

## プレイヤー移動の構造

`player.gd` は、移動処理を意図的に小さな関数へ分けている。

- `get_movement_input()` は入力アクションを読む。
- `apply_movement(velocity, delta)` は移動と画面内クランプを行う。
- `update_animation_move(is_moving)` はアニメーションの開始/停止を行う。
- `update_animation_direction(velocity)` はアニメーション種類とスプライト反転を更新する。

プレイヤー挙動を拡張するときは、この分離を維持すること。すべてを `_process()` に詰め込まない。

## ゲーム状態の分担

- ゲーム進行は `main.gd` に置く。
- その他の `.gd` は以下のように短い名称を使用する
	- プレイヤー固有の挙動は `player.gd` に置く。
	- 敵固有の挙動は `mob.gd` に置く。
	- UI固有の挙動は `hud.gd` に置く。
- シーン間連携は、可能な限り直接参照より信号を使う。

## 避けること

- Input Mapに既存アクションがある場合、スクリプト内でキーを直接ハードコードしない。
- 単純な信号とタイマーの流れを、グローバル状態管理へ置き換えない。
- ノード参照名を変更する場合は、所有する `.tscn` とすべての `$NodePath` 利用箇所も更新する。
- 小さな修正のためにスクリプト全体を書き換えない。
