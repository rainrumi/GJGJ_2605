# ノベルスクリプト仕様

シナリオ本文は `resource/novel/` 配下の UTF-8 `.txt` に置く。既存の Main Scene と Stage Resource は `NovelTextInfo` の `.tres` を参照し、その `script_path` から txt を読み込む。

スクリプトは上から1行ずつ実行される。行頭が `@` の行はコマンド、それ以外の空でない行はメッセージ本文としてタイプ表示される。本文は `@cm` が実行されるまで現在のメッセージへ追記される。

## コマンド

| コマンド | 動作 |
|---|---|
| `@name "主人公"` | 名前ラベルへ `主人公` を表示する。空文字列なら名前ラベルを隠す。 |
| `@bg "res://resource/image/...png"` | 指定した `Texture2D` を背景へ表示する。空文字列なら背景を隠す。 |
| `@img 0, 100, 200, "res://resource/image/...png"` | index `0` 専用の画像を座標 `(100, 200)` に表示する。同じindexを再指定すると画像と座標を上書きする。 |
| `@img_remove 0` | `@img` で作成したindex `0` の画像を削除する。存在しないindexなら何もしない。 |
| `@l` | 左クリックを待つ。タイプ表示中のクリックは全文表示だけを行い、次のクリックが待機を解除する。 |
| `@r` | 現在のメッセージ末尾へ改行を追加する。 |
| `@cm` | メッセージウィンドウ内の本文を消去する。 |
| `@lcm` | `@l`、`@cm` の順に実行する。 |

## 記述例

```text
@name "主人公"
@bg "res://resource/image/texture/still/tex_still_1000.png"
@img 0, 100, 80, "res://resource/image/texture/still/tex_still_1000.png"
最初のメッセージです。
@r
改行後のメッセージです。
@lcm
@img_remove 0
次のメッセージです。
@lcm
```

コマンド名は1行につき1つ記述する。不明なコマンド、存在しない txt、`Texture2D` として読み込めない背景パスは、対象を含む error log を出す。
