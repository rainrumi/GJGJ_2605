# プロジェクト概要

## エンジンとプロジェクト形状

- Godot 4.x 系の 2D ゲームプロジェクトである。
- 基本解像度は 1280 x 720 を前提にしている。
- ゲームは複数のメイン画面を切り替えながら進行する。
- `.godot/` はエディタ生成物であり編集しない。
- `.tscn`、`.tres`、`.uid`、`.import`、`project.godot` は Godot 管理ファイルとして扱い、差分を最小限にする。

## ゲーム概要

プレイヤーは悪夢を胃袋に配置し、時間内に消化する。  
戦闘後は夢の種を選び、長期的な恩恵を得ながら日数を進める。

## 基本ゲームループ

```text
タイトル
→ オープニング
→ 日付表示
→ ステージ選択
→ 戦闘
→ ステージクリアまたはゲームオーバー
→ 次の日へ進行
```

## 勝利条件

- 朝までにすべての悪夢を消化する。

## 敗北条件

- 朝までにすべての悪夢を消化できない。

## 主な画面

```text
Title
OpeningNovel
DayIntro
StageSelect
Game
StageClear
```

## 主な設計単位

| 種類 | 役割 |
|---|---|
| `Main` | 画面遷移の調停 |
| `StageSelect` | ステージ候補の表示と選択通知 |
| `Game` | 戦闘進行の司令塔 |
| `StageClear` | 報酬選択と HP / 花状態の更新 |
| `BattleUI` | 戦闘 UI の表示窓口 |
| `NightmareDigestController` | 悪夢の消化処理 |
| `GameEnemySetupController` | 敵の初期セットアップ |
| `DreamSeedEffectCalculator` | 夢の種効果の計算 |
| `NightmarePlacementQuery` | 配置・隣接・空きセル判定 |
| `BeatConductor` | 音楽同期・拍管理 |

## 主な Resource

| Resource | 役割 |
|---|---|
| `StageDefinition` | ステージ定義 |
| `StageCatalog` | ステージ定義一覧 |
| `EnemyDefinition` | 敵定義 |
| `NightmareSkillDefinition` | 悪夢スキル定義 |
| `NightmareSkillCatalog` | 悪夢スキル一覧 |
| `DreamSeedSkillDefinition` | 夢の種スキル定義 |
| `FlowerDefinition` | 花定義 |
| `SeedOptionDefinition` | 報酬選択肢定義 |
| `NovelTextResource` | ノベル本文定義 |

## 現在の重要な設計課題

- ゲーム進行状態を `Main`、`Game`、`StageClear` に分散させない。
- `StageSelect` の選択結果を戦闘に接続する。
- `skill_id` の数値直書きを避ける。
- 戦闘ロジックから UI・敵生成・音楽同期への依存を増やしすぎない。
- UI 表示状態が増えたら ViewState や TooltipManager を検討する。
