# <機能名> Godot 実装計画

## 目的

- <達成するユーザー価値または不具合修正>

## 受入条件

- [ ] <観測可能な期待結果>
- [ ] <error時・境界条件の期待結果>

## 現状調査

### Project

- Godot version:
- Script language:
- Main Scene:
- Autoload:
- Test / CI:

### 関連ファイル

- Scene:
- Script:
- Resource / Data:
- ProjectSettings / InputMap:

### 現在の責務とデータフロー

- <所有者、signal、公開API、runtime生成、保存先>

## 確定事項

- <調査またはユーザー要求から確定した事実>

## 仮定・未確定事項

- <安全な仮定と、外れた場合の影響>

## 設計判断

- 採用案:
- 既存方式へ合わせる点:
- 採用しなかった案と理由:
- Scene / Node / Resource / Autoloadの所有関係:

## 影響範囲

- Authoring変更:
- Runtime変更:
- Data / Serialization:
- ProjectSettings / InputMap:
- 互換性 / Migration:

## 実装 TODO

- [ ] <対象pathと具体的変更>
- [ ] <Scene/Resourceのauthoring変更>
- [ ] <Script/API/signal変更>
- [ ] <必要なtest追加・更新>

## 検証 TODO

- [ ] `git diff --check` と差分scopeを確認する。
- [ ] project標準のformat/lintを実行する。
- [ ] Godot headless importを実行する。
- [ ] 変更GDScriptのparse、またはC# solution buildを実行する。
- [ ] <関連test command / test case>を実行する。
- [ ] `<res://対象Scene>`を起動し、<導線>を確認する。
- [ ] <UI / input / physics / animation / renderingの追加確認>を行う。
- [ ] log全文から新規errorがないことを確認する。

## リスクと切り分け

- Risk:
  - Detection:
  - Mitigation:

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク
