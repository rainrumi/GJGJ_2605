---
name: godot-implementation-planner
description: Godot 4.x プロジェクトの実装前に、日本語の実装計画Markdownを作成する。Scene、Node、Resource、Script、signal、Autoload、ProjectSettings、InputMap、asset、テスト、runtime検証を調査し、実装TODOと検証TODOを対応づける必要がある場合に使用する。
---

# Godot 実装計画作成

曖昧または複数ファイルにまたがるGodot実装依頼を、後続エージェントが推測を減らして実装・検証できる計画書へ変換する。

## 成果物の契約

計画書は単なるタスク一覧ではなく、次を含む実装契約とする。

- 目的と受入条件
- 調査できた現状
- 確定事項と仮定の区別
- Scene / Node / Resourceの所有関係
- data flowとsignal/API契約
- authoring変更とruntime変更の分離
- 互換性・移行・ProjectSettingsへの影響
- 実装TODOと対応する検証TODO
- 未確定事項と失敗時の切り分け方法

## ワークフロー

1. 対象scopeの`AGENTS.md`を読む。
2. `project.godot`からengine feature、Main Scene、Autoload、InputMap、rendering設定を確認する。
3. 対象Sceneと継承Scene、関連Script、Resource、test、CI、既存docsを読む。
4. 現在の責務分割、参照取得、signal接続、runtime生成、data所有者を図または文章で整理する。
5. 要求を受入条件へ変換する。見た目、入力、保存、failure時挙動も必要に応じて含める。
6. 最小変更案を作り、別方式を導入しないと成立しないか判断する。
7. TODOを依存順に並べ、各実装TODOへ検証方法を対応づける。
8. 計画を`docs/`、`planning/`など既存の自然な場所へ保存する。

ユーザーが実装まで依頼していない場合、計画作成中にScript、Scene、Resource、ProjectSettingsを変更しない。

## 調査項目

### Project

- Godot versionと`.NET`利用有無
- Main Scene
- Autoloadと起動順
- InputMap
- addon / EditorPlugin
- renderer、physics、display、stretch
- CIと標準command

### Scene

- root typeと責務
- inherited scene / instantiated subscene
- owner、unique name、NodePath
- signal connection
- animation trackが参照するNode/property
- Runtime生成対象と固定authoring対象

### Script

- GDScript / C#
- Node lifecycle
- public API、signal、export property
- state所有者
- async、Timer、Tween、process callback
- error handling

### Data

- Resourceとshared/localの扱い
- save data、ConfigFile、JSON、外部data
- migrationとdefault
- localization

### Verification

- formatter/linter
- import
- changed GDScript parse
- C# build
- test runner
- target Scene / Main Scene smoke
- visual、input、physics確認

## 判断ルール

- 既存パターンが要件を満たすなら、それを使う。
- 新しいAutoload、event bus、base class、framework、addonは最終候補とする。
- 固定Nodeの追加はScene authoring TODO、動的instanceはruntime TODOとして分ける。
- Resourceの定義変更とruntime状態変更を分ける。
- `.tscn` / `.tres` / `project.godot`変更は、serializationと参照互換性の確認TODOを持たせる。
- UI、rendering、physics変更にはheadless以外の確認TODOを含める。
- 「実装する」「確認する」だけのTODOを作らず、対象、操作、期待結果を書く。

## テンプレート

`templates/implementation-plan.md`をコピーして使う。既存計画フォーマットがある場合は既存形式を優先し、内容上の契約を維持する。

## TODO品質基準

良いTODO:

```markdown
- [ ] `res://ui/inventory/inventory_panel.tscn` に詳細Paneを追加し、既存Container階層でresizeされるようanchorとsize flagsを設定する。
- [ ] `InventoryPanel` の `item_selected` signalを親Sceneで接続し、選択した`ItemData`だけを詳細Paneへ渡す。
- [ ] UI test Sceneを起動し、1280x720と1920x1080でoverflowとfocus navigationを確認する。
```

悪いTODO:

```markdown
- [ ] UIをいい感じにする。
- [ ] managerを作る。
- [ ] 動作確認する。
```

## 最終応答

- 作成・更新した計画書path
- 計画対象と主要な設計判断
- 最初に着手すべきTODO
- 重要な仮定と未確定事項
- 実装時に必須となる検証導線
