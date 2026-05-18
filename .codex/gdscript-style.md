# GDScript の書き方

## 言語レベル

- Godot 4.x の GDScript 構文を使う。
- 現在のスクリプトに合わせて、型付き変数と戻り値型を優先する。
- シーン上で編集する値には `@export` を使う。
- ノード参照には `@onready var name: Type = $NodePath` を使う。
- スクリプトが所有するイベントには `signal name` を使う。
- 共有される型には `class_name` を付ける。

## フォーマット

- GDScript のブロックインデントはタブを使う。
- 関数は短く、処理が追いやすい形にする。
- 主要な関数の間には空行を入れる。
- コメントは日本語でよい。ただし短く、目的が分かる内容にする。
- 装飾的な区切りコメントや、説明過多なコメントを追加しない。
- 1つの関数でゲーム状態変更、UI更新、演出、音再生をまとめすぎない。

## 命名規則

既存の書き方に合わせること。

```gdscript
@onready var hp_status: HpView = $HpFrame
@onready var digestion_timer: Timer = $AutoDigestionTimer

func start_battle(context: BattleStartContext) -> void:
	...

func _on_digestion_requested() -> void:
	...
```

- ファイル名: `snake_case`。
- 関数名・変数名: `snake_case`。
- 入力アクション名: `snake_case`。
- シーン名・ノード名: Godot 標準寄りの PascalCase。
- シーンから接続された信号ハンドラ: `_on_<node>_<signal>()` 形式を優先する。
- signal 名は「何が起きたか」「何が要求されたか」が分かる名前にする。

## 型と公開 API

- 親が子を操作する場合、子シーンのルートスクリプトに公開メソッドを置く。
- 上位シーンから UI 内部ノードを直接触らない。
- `has_method()` に頼りすぎない。主要シーンは `class_name` と型指定で契約を明確にする。
- 一時的な互換対応として `has_method()` を使う場合は、移行完了後に削除する。

## 定数

`skill_id` のような数値は直書きしない。

```gdscript
const NIGHTMARE_SKILL_TIME_DELAY := 6
const NIGHTMARE_SKILL_EVEN_ORDER_REVIVE := 11
```

```gdscript
if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_TIME_DELAY):
	...
```

## 避けること

- 既存の Input Map があるのに、スクリプト内でキーを直接ハードコードする。
- 小さな修正のためにスクリプト全体を書き換える。
- NodePath を推測で変更する。
- UI とロジックを同じ関数に詰め込む。
- Dictionary の文字列キーに依存した定義データを増やす。
