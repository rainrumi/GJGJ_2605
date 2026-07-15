# Godot 検証・報告ガイド

## 1. 検証の目的

検証は「コマンドが終了したこと」ではなく、変更が要求を満たし、Godotが対象ResourceとScriptを読み込み、関連する実行経路で新しいfailureを起こさないことを確認する作業である。

一つの検証手段だけで全てを証明しない。

| 手段 | 主に検出できるもの | 検出できない代表例 |
|---|---|---|
| formatter/linter | style、静的ルール | runtime挙動、Scene参照 |
| `--import` | import/load周辺のfailure | 全Scriptの全経路 |
| `--script ... --check-only` | 指定GDScriptのparse error | 全Scene、runtime、視覚 |
| `--build-solutions` / `dotnet build` | C# compile error | Scene wiring、runtime状態 |
| automated test | 記述済みの期待動作 | 未記述シナリオ、visual |
| headless smoke | 初期化、短いruntime error | renderingの見た目、入力全体 |
| editor/manual確認 | visual、interaction、authoring | 自動回帰性 |

## 2. 標準検証順序

1. `git diff --check` と変更ファイル一覧を確認する。
2. プロジェクト標準のformat/lintを実行する。
3. Godotのversionを記録する。
4. headless importを実行する。
5. 変更GDScriptを`--check-only`でparseする。
6. C#プロジェクトならsolution buildを実行する。
7. 関連testを実行する。
8. 対象SceneまたはMain Sceneをsmoke実行する。
9. UI、physics、animation、renderingに関係する場合はeditor上の確認を追加する。
10. 全ログをfailure patternで確認する。

標準スクリプト:

```bash
./scripts/validate-godot.sh .
```

```powershell
./scripts/Validate-Godot.ps1 -ProjectPath .
```

## 3. プロジェクト固有コマンド

`.agent/godot-agent.env` または環境変数で次を設定できる。

- `GODOT_BIN`: Godot editor binary
- `GODOT_FORMAT_CHECK_COMMAND`: format差分がないことを確認するcommand
- `GODOT_LINT_COMMAND`: lint command
- `GODOT_TEST_COMMAND`: projectのtest command
- `GODOT_SMOKE_SCENE`: `res://...`形式のsmoke対象Scene
- `GODOT_SMOKE_FRAMES`: headlessで動かすiteration数
- `GODOT_ALLOWED_LOG_REGEX`: 既知で許容するlogの正規表現

コマンドはリポジトリで信頼された設定だけを使用する。

## 4. Scene別の追加確認

### UI

- anchor、offset、Container、size flags
- stretch modeと代表解像度
- focus、keyboard/controller navigation
- mouse filter、input propagation
- localizationと長い文字列
- animation開始・終了状態

### 2D/3D physics

- collision layer/mask
- physics tick依存
- spawn transform
- floor/wall判定
- queue_freeのタイミング
- fixed timestep差による挙動

### Resource / Save Data

- load path、UID、default値
- 旧データ欠損時のmigrationまたはfallback
- shared Resourceの意図しない変更
- serialization可能な型

### InputMap / ProjectSettings

- action名の重複
- deadzoneとdevice
- 既存key bindingの破壊
- platform差
- project.godotの無関係な再保存差分

### EditorPlugin / `@tool`

- editor起動時error
- plugin enable/disable
- filesystem scan/importとの競合
- Sceneを開いただけで発生する副作用
- undo/redo対応が必要なeditor変更

## 5. ログ判定

終了コード0だけで成功と判断しない。少なくとも次を確認する。

- `SCRIPT ERROR:`
- `Parse Error:`
- `ERROR:`
- resourceをloadできない旨
- invalid call / invalid access
- C# exception / build failure
- test failure / timeout

ただし、文字列として「0 errors」などを含む成功行を誤検出しない。既知の許容logは理由とscopeを記録し、無差別に除外しない。

## 6. Failureの切り分け

1. 再現commandと対象Sceneを固定する。
2. 変更ファイルとの関連を確認する。
3. import後にも再現するか確認する。
4. parse/build failureかruntime failureか分類する。
5. Scene wiring、Resource path、UID、ProjectSettings、language compileを順に確認する。
6. 修正後は、failureを検出した検証と、その前後の依存検証を再実行する。

## 7. 最終報告

`templates/verification-report.md` を基準に、次を明確にする。

- 何を変えたか
- なぜその設計にしたか
- 何を実行して確認したか
- failureが出た場合、何を直したか
- 何を確認できていないか

未実行事項を成功に含めない。目視していないUIを「表示問題なし」と報告せず、「headless初期化のみ確認」のように検出範囲を限定して書く。

## 8. 公式CLIの前提

このパックはGodot 4.xの標準CLIを基礎にする。

- `--path`: `project.godot`を含むproject directoryを指定
- `--headless`: display/audioをheadless向けにする
- `--import`: editorを起動し、resource import完了後に終了
- `--script ... --check-only`: 指定Scriptをparseして終了
- `--build-solutions`: C#などのscripting solutionをbuild
- `--quit-after`: 指定iteration後に終了
- `--log-file`: log出力先を指定

Godotのversionにより利用可能optionが異なる可能性があるため、CIまたはローカルbinaryの`--help`と`--version`を最終的な事実として扱う。
