# TXT ノベルスクリプト Godot 実装計画

## 目的

- シナリオ本文を `resource/novel/` 配下の `.txt` で編集できるようにし、本文と `@` コマンドを上から順に実行するノベル再生方式へ移行する。

## 受入条件

- [x] 既存の全シナリオ本文が `resource/novel/**/*.txt` に格納され、既存の Scene / Stage Resource 参照を壊さず再生される。
- [x] `@name "主人公"` が名前ラベルを更新する。
- [x] `@bg "res://..."` が背景 Texture を更新する。
- [x] `@l` がクリックを待ち、`@cm` がメッセージ本文を消去する。
- [x] `@lcm` が内部で `@l`、`@cm` の順に呼び出す。
- [x] 移行前の本文は各表示行の後に `@lcm` を置き、従来どおりクリック単位で読み進められる。
- [x] 不明なコマンド、欠損した txt、無効な背景パスは原因と対象を含む error を出し、安全にシナリオを終了または次へ進む。

## 現状調査

### Project

- Godot version: `project.godot` の feature は Godot 4.6。
- Script language: GDScript。
- Main Scene: `res://scene/main/main.tscn`。
- Autoload: `GameSettings`、`DebugState`、`MouseDragState`。
- Test / CI: 独自の `SceneTree` テスト。標準検証スクリプトは文書上指定されているが `scripts/` は存在しない。

### 関連ファイル

- Scene: `scene/main/opening_novel/opening_novel.tscn`、`scene/main/main.tscn`。
- Script: `scene/main/opening_novel/opening_novel.gd`、`data/info/novel/novel_text_info.gd`、`scene/main/main.gd`。
- Resource / Data: `data/resources/novel/**/*.tres`（37件）、`data/resources/area/**/*.tres`。
- Test: `tests/opening_novel_character_se_test.gd`、`tests/all_gdscript_parse_test.gd`。
- ProjectSettings / InputMap: 変更なし。

### 現在の責務とデータフロー

- `NovelTextInfo` は Inspector 内の複数行 `text` を空行を除く行配列へ変換する。
- `OpeningNovel` は行配列を1行ずつタイプ表示し、クリックでタイプ完了または次行へ進む。
- `Main` と `StageInfo` は `NovelTextInfo` を型付きで所有し、Stage Resource は既存 `.tres` を参照している。

## 確定事項

- `.tres` を削除すると Main Scene と多数の Stage Resource の参照変更が必要になる。
- 現行画面には本文 Label と背景 TextureRect はあるが、名前 Label はない。
- 依頼末尾の定義を正とし、`@l` はクリック待機、`@cm` は本文消去とする。

## 仮定・未確定事項

- `.tres` はシナリオ本文そのものではなく、既存の型付き参照を維持するための薄い参照 Resource として残す。
- `@bg ""` は背景を消す指定として扱い、通常の `res://` パスは `Texture2D` だけを受理する。
- 既存の動的シナリオ生成用 `text` は互換 API として残すが、静的本文はすべて `.txt` へ移す。

## 設計判断

- 採用案: `NovelTextInfo` に txt パスと読込 API を持たせ、`OpeningNovel` が行を逐次解釈する小さなインタープリタになる。各コマンドを1つの専用関数へ対応させる。
- 既存方式へ合わせる点: `NovelTextInfo`、`OpeningNovel`、`finished` / `advanced` signal、Main / Stage の Resource 所有関係は維持する。
- 採用しなかった案と理由: txt を直接 Stage Resource の型付き配列へ入れる案は `Array[NovelTextInfo]` と既存参照を大きく変更する。Autoload のコマンド基盤は Scene 固有 UI への依存を global 化するため追加しない。
- Scene / Node / Resource / Autoloadの所有関係: txt パスは `NovelTextInfo`、実行状態と UI は `OpeningNovel`、画面遷移は引き続き `Main` が所有する。

## 影響範囲

- Authoring変更: `OpeningNovel` Scene に名前 Label を追加する。
- Runtime変更: 行ページャを逐次コマンド実行へ置換する。
- Data / Serialization: 37件の `.tres` の埋込本文を txt パスへ変更し、`resource/novel/` に txt を追加する。
- ProjectSettings / InputMap: 変更なし。
- 互換性 / Migration: runtime 生成済み `NovelTextInfo.text` は継続対応する。静的 `.tres` の型と参照 path は維持する。

## 実装 TODO

- [x] `NovelTextInfo` に `script_path` と安全な UTF-8 txt 読込を追加する。
- [x] `OpeningNovel` を逐次実行方式へ変更し、`@name`、`@bg`、`@l`、`@cm`、`@lcm` を各専用関数で実装する。
- [x] `OpeningNovel` Scene に `NameLabel` を authoring する。
- [x] Main の動的テキスト生成を txt 読込 API と新コマンド形式へ合わせる。
- [x] 既存37シナリオを `resource/novel/**/*.txt` へ移し、各表示行後へ `@lcm` を挿入する。
- [x] txt 読込とコマンド順序を検証する回帰テストを追加する。

## 検証 TODO

- [x] `git diff --check` と差分 scope を確認する。
- [x] formatter / linter の設定有無を確認する（`gdformat` / `gdlint` は未設定）。
- [x] Godot 4.6.2 で headless import を実行する。
- [x] 変更 GDScript の parse と `tests/all_gdscript_parse_test.gd` を実行する。
- [x] `tests/opening_novel_character_se_test.gd` と `tests/novel_script_commands_test.gd` を実行する。
- [x] `res://scene/main/main.tscn` を headless smoke 実行し、初期化 error がないことを確認する。
- [x] 通常描画で名前 Label、背景変更、本文、クリック待機マーカーを目視確認する。
- [x] log 全文を確認し、既知の終了時 Resource leak 以外に新規 error がないことを確認する。

## リスクと切り分け

- Risk: coroutine とクリック入力の順序により、タイプ完了クリックが次の `@l` まで同時に解除する。
  - Detection: タイプ中クリックと待機中クリックを分けたテストを実行する。
  - Mitigation: タイプ中は request id でタイプだけを完了し、待機解除 signal は待機中にだけ発行する。
- Risk: txt や背景 Resource の path 不備で空画面になる。
  - Detection: 読込テストと error log を確認する。
  - Mitigation: 必須 txt は明示 error、背景は現状を保持して次命令へ進む。

## 完了時の報告事項

- 変更内容
- 実行した検証 command と対象
- failure と解消内容
- 未検証事項と残リスク
