---
name: godot-implementation-check
description: Godot 4.x プロジェクトでScript、Scene、Resource、ProjectSettings、InputMap、addon等を実装・変更した後、AGENTS.mdに従って差分、format/lint、import、GDScript parse、C# build、automated test、対象Sceneのruntime smoke、必要なvisual確認を行い、証拠と未検証事項を報告するときに使用する。
---

# Godot 実装・検証

ファイル編集だけで終わらせず、変更の種類に対応した検証を実行し、検出範囲を明示して報告する。

## 基本ワークフロー

1. scope内の`AGENTS.md`、計画書、関連docsを読む。
2. 作業開始前の`git status`を確認し、既存の未commit変更と自分の変更を混同しない。
3. 対象Scene、Script、Resource、ProjectSettingsと、関連testを読む。
4. 最小変更で実装する。Scene authoring不足をruntime fallbackで隠さない。
5. 差分を確認し、意図しないUID、import、整形、Scene再保存差分を除く。
6. 標準検証scriptを実行する。
7. 変更内容に応じた追加test、Scene実行、visual/interaction確認を行う。
8. failureを修正し、failureを検出した検証から再実行する。
9. `templates/verification-report.md`の項目に沿って報告する。

## 標準コマンド

macOS / Linux / Git Bash:

```bash
./scripts/validate-godot.sh .
```

Windows PowerShell:

```powershell
./scripts/Validate-Godot.ps1 -ProjectPath .
```

Godot binaryやテストcommandは`.agent/godot-agent.env`または環境変数で設定する。

## 検証マトリクス

| 変更 | 必須確認 | 条件付き追加確認 |
|---|---|---|
| `.gd` | import、changed script parse、test、smoke | lint、typed warning、visual |
| `.cs` / `.csproj` | import、solution build、test、smoke | dotnet format、nullable/analyzer |
| `.tscn` | import、load/smoke、参照確認 | visual、input、animation、physics |
| `.tres` / `.res` | import、load、利用Scene/test | shared/local状態、migration |
| `project.godot` | import、diff精査、Main Scene smoke | platform、InputMap、Autoload順序 |
| addon / `@tool` | editor import/startup、plugin動作 | enable/disable、undo/redo |
| shader/rendering | import、対象Scene実行 | visual、GPU/renderer差 |

## GDScript parse

`--script <path> --check-only`は指定したScriptのparse確認に使う。変更した`.gd`を対象にするが、次を理解する。

- 全Projectの全Scriptを保証しない。
- SceneのNodePath、Resource wiring、runtime状態を保証しない。
- parse成功後もtestとScene実行が必要。

## C# build

C#が存在する場合は、Godot .NET editor binaryで`--build-solutions`を実行するか、リポジトリ標準の`dotnet build/test`を使う。標準Godot binaryしかない場合はblockerとして報告し、build済み扱いにしない。

## Automated test

- 変更に最も近いtestを先に実行する。
- failure修正後は関連testを再実行する。
- 共有component、Autoload、save schema、base Resource変更では、影響範囲に応じてsuiteを広げる。
- test runnerがない場合、勝手に大規模frameworkを導入しない。小さなpure logicには既存方式でtest追加を検討し、Scene挙動は再現可能なtest Sceneまたは手順を残す。

## Runtime / Visual確認

headless smokeは初期化error検出に使う。次の変更は追加確認が必要。

- UI layout、Theme、font、localization
- animation、Tween、particle
- rendering、shader、camera
- input、focus、controller
- physics、navigation
- audio timing

利用可能なGodot editor automation/MCPがある場合は、対象Sceneの起動、remote tree、debugger、screenshotを使う。利用できない場合は、未実行のvisual/interaction確認を明示する。

## ログ全文確認

標準scriptのsummaryだけでなく、`.godot/agent-logs/`の各logを確認する。少なくとも次を検索する。

```text
SCRIPT ERROR:
Parse Error:
ERROR:
Failed loading resource
Invalid call
Exception
FAILED
```

許容する既知logがある場合は、理由と範囲を報告する。広い正規表現でerror全体を除外しない。

## Failure対応

- compile/parse error: 最初の原因errorから直す。
- resource load error: path、UID、type、import状態を確認する。
- Node not found: Sceneの所有関係とNodePath変更を確認する。fallback検索で隠さない。
- invalid instance: `queue_free()`、Scene切替、await後の寿命を確認する。
- duplicate signal: Editor接続とcode接続、再enter時の接続を確認する。
- C# build failure: Godot .NET版、SDK、generated project、package restoreを分けて確認する。
- test failure: 要求変更による期待値更新か、実装regressionかを判定する。

## 完了判定

次のいずれかで終了する。

### 完了

- 要求を満たした。
- 必要な検証が成功した。
- 変更に起因するfailureがない。
- 未検証事項がない、または要求上許容され明示済み。

### Blocked

- 必要なbinary、SDK、asset、credential、service、manual authoringがなく、現在の環境では検証または実装を完了できない。
- blocker、実行済み確認、次に必要な具体的操作を報告する。

### Partial

- 一部受入条件のみ実装・検証できた。
- 完了済み範囲と未完範囲を明確に分ける。「完了」と表現しない。

## 最終報告

- 変更した主要fileと挙動
- 設計上の判断
- 実行した全検証command
- test名またはScene path
- 最終的なerror/failure状態
- 修正途中で発生したfailureと解消内容
- 未実行確認、blocker、残リスク
