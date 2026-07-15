# Godot AGENTS / Skills Pack

Godot 4.x プロジェクトで AI エージェントに実装を任せるための、意思決定・検証・報告の契約一式です。

## 含まれるもの

- `AGENTS.md`: リポジトリ全体で常時適用する実装規約と完了条件
- `skills/godot-implementation-planner/SKILL.md`: 実装計画を作る手順
- `skills/godot-implementation-check/SKILL.md`: 実装後に検証し、根拠付きで報告する手順
- `docs/architecture.md`: Scene / Node / Resource / Autoload の判断基準
- `docs/verification.md`: Godot CLI、テスト、ログ判定の運用基準
- `templates/implementation-plan.md`: 計画書テンプレート
- `templates/verification-report.md`: 最終報告テンプレート
- `scripts/validate-godot.sh`: macOS / Linux / Git Bash 向け検証スクリプト
- `scripts/Validate-Godot.ps1`: Windows PowerShell 向け検証スクリプト
- `.agent/godot-agent.env.example`: プロジェクト固有コマンドの設定例

## 導入

1. このディレクトリの内容を Godot プロジェクトのルートへコピーする。
2. `AGENTS.md` 冒頭の「プロジェクト固有情報」を埋める。
3. `.agent/godot-agent.env.example` を参考に、必要なら `.agent/godot-agent.env` を作成する。
4. 検証スクリプトを一度実行し、Godot バイナリと既存テストコマンドを確認する。

```bash
./scripts/validate-godot.sh .
```

```powershell
./scripts/Validate-Godot.ps1 -ProjectPath .
```

## 設計方針

このパックは特定のアーキテクチャ、テストアドオン、フォーマッタを強制しません。既存プロジェクトの方式を優先しながら、次の契約だけを固定します。

1. 変更前に既存構造と契約を調査する。
2. 最小の整合的な変更を選ぶ。
3. Scene authoring と runtime behavior を混同しない。
4. import、parse/build、test、smoke run の証拠を確認する。
5. 未検証事項と blocker を隠さず報告する。

## 対象

Godot 4.x を前提にしています。GDScript と Godot .NET/C# の両方を扱えますが、実際のプロジェクトで使っていない言語の規約は適用しません。
