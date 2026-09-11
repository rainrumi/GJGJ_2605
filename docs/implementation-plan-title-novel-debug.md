# タイトル・ノベルデバッグ一覧 Godot 実装計画

## 目的

- タイトルからデバッグ機能を有効化し、任意のノベルをゲーム進行へ影響させず確認できるようにする。

## 受入条件

- [x] タイトルにある `Debug` ボタンが、戦闘・ステージ選択と共通の `DebugState` を切り替える。
- [x] Debug 有効時だけノベル一覧を表示し、無効化すると隠す。
- [x] 一覧の各ボタンから対応するシナリオを再生し、終了後はタイトルへ戻る。
- [x] `resource/novel` 配下へ追加された `.txt` も一覧へ反映する。
- [x] ノベル一覧ボタンの文字を既定サイズの50%で表示する。
- [x] デバッグ専用エリアのノベルを通常ノベルより後ろへ並べ、両グループの間に `Debug` と表示する。

## 現状調査

### Project

- Godot version: 4.6（`project.godot` feature）
- Script language: GDScript
- Main Scene: `res://scene/main/main.tscn`
- Autoload: `GameSettings`、`DebugState`、`MouseDragState`
- Test / CI: `tests/*.gd` の独自 runner。標準検証スクリプトは未配置。

### 関連ファイル

- Scene: `scene/main/title/title.tscn`、`scene/main/main.tscn`、`scene/main/opening_novel/opening_novel.tscn`
- Script: `scene/main/title/title.gd`、`scene/main/main.gd`、`scene/main/opening_novel/opening_novel.gd`
- Resource / Data: `resource/novel/**/*.txt`、`data/info/novel/novel_text_info.gd`
- ProjectSettings / InputMap: 変更なし

### 現在の責務とデータフロー

- `DebugState` が画面をまたぐデバッグ有効状態を所有する。
- `Title` は画面内操作を signal で `Main` へ通知する。
- `Main` が画面遷移と `OpeningNovel.start_with_text()` の呼出しを所有する。

## 設計判断

- 採用案: タイトルSceneに固定のデバッグボタンと一覧コンテナをauthoringし、可変個数のシナリオボタンだけruntime生成する。
- 既存方式へ合わせる点: 共通状態は既存 `DebugState`、子から親への通知は型付きsignal、再生は既存 `OpeningNovel` を使う。
- 採用しなかった案と理由: ノベルごとのボタンをSceneへ52個固定すると追加漏れが起こるため採用しない。新規Autoloadも不要。
- 所有関係: `Title` が一覧UIを所有し、`Main` がノベル再生フローを所有する。

## 影響範囲

- Authoring変更: タイトルのDebugボタン・スクロール一覧。
- Runtime変更: `.txt` の再帰列挙、ボタン生成、プレビュー再生終了時のタイトル復帰。
- Data / Serialization: 変更なし。
- ProjectSettings / InputMap: 変更なし。
- 互換性 / Migration: 既存ゲーム進行・Debug状態の形式変更なし。

## 実装 TODO

- [x] `title.tscn` / `title.gd` にデバッグUIとsignalを追加する。
- [x] `main.gd` / `main.tscn` にプレビュー再生フローを接続する。
- [x] タイトルの表示切替・一覧生成・選択通知を確認するtestを追加する。

## 検証 TODO

- [x] `git diff --check` と差分scopeを確認する。
- [x] Godot headless importを実行する。
- [x] `tests/all_gdscript_parse_test.gd` を実行する。
- [x] 新規タイトルデバッグtestを実行する。
- [x] Main Sceneをheadless smoke実行し、ログ全文を確認する。
- [ ] 640x360で一覧、スクロール、再生・復帰を目視確認する。
