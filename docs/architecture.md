# Godot アーキテクチャ判断ガイド

この文書は、`AGENTS.md` の原則を、GodotのScene / Node / Resource / signalへ適用するための判断基準である。特定パターンを一律に強制するものではなく、既存プロジェクトとの整合を最優先する。

## 1. 責務を置く場所

| 責務 | 第一候補 | 判断理由 |
|---|---|---|
| 描画、入力、physics、SceneTree lifecycle | Node / Control | engine callbackとtree接続が必要 |
| 再利用可能な構成物 | PackedScene | Node構成と設定を一単位でinstance化できる |
| 共有定義、調整値、データasset | Resource | Inspector編集、serialization、再利用に適する |
| 純粋な計算、ルール、変換 | RefCounted / Object / C# class | SceneTree依存を避けてテストしやすくする |
| Scene間で一意かつ長寿命な状態 | Autoload候補 | Scene寿命を越える必要が本当にある場合のみ |
| 一時的な非同期・時間制御 | Timer / Tween / AnimationPlayer / await | engineの寿命・時間系と整合する |

## 2. Sceneを分ける基準

Sceneとして分離する候補は次のいずれかを満たすもの。

- 独立して実行・検証できる。
- 複数箇所でinstance化される。
- Node構造とexport設定が一つの意味ある部品を表す。
- 独自のlifecycle、animation、input、signal契約を持つ。
- 親Sceneの内部実装から切り離すことで依存が減る。

単にScriptを短くするためだけにSceneを細分化しない。逆に、画面全体を一つのScriptへ集約して、UI、進行、保存、network、animationを混ぜない。

## 3. Scene間の通信

### 子から親

signalを第一候補とする。子は「何をしてほしいか」ではなく、「何が起きたか」を通知する。

```gdscript
signal item_selected(item_id: StringName)
```

### 親から子

親が所有する子へ、型付き公開メソッドまたは明示的プロパティで命令する。

```gdscript
func show_item(item: ItemData) -> void:
    # 表示更新
    pass
```

### 離れたScene同士

最初からglobal event busへ送らない。次の順に検討する。

1. 共通の親が接続・仲介できるか。
2. 依存するobjectを明示的に渡せるか。
3. groupが明確な分類契約として適切か。
4. Sceneを越える一意の責務としてAutoloadが必要か。

## 4. Node参照の選択

| 方法 | 適する状況 | 注意 |
|---|---|---|
| `@onready var x: Type = %Name` | Scene内の安定したunique node | unique nameの契約を変更時に確認 |
| `@onready var x: Type = $Path` | 小さく固定された内部構造 | 深いpathは内部再構成に弱い |
| `@export var x: Type` | authorが明示的に接続すべき外部参照 | 必須/任意を明示する |
| constructor/initialize引数 | pure objectやinstance直後の初期化 | Nodeのready順序と混同しない |
| group検索 | 複数対象の分類・broadcast | 一意参照取得の代替にしない |
| `get_node_or_null()` | 本当に任意の参照 | 必須契約の欠損を隠さない |

`find_child()` やrootからの広域探索は、Sceneの所有関係を曖昧にするため常用しない。

## 5. Resourceの共有と状態

Resourceは参照共有される場合がある。定義Assetをruntime状態として直接書き換えると、別instanceにも影響する可能性がある。

- immutableな定義として使うのか。
- Sceneごとのlocal resourceとして使うのか。
- runtime開始時にduplicateするのか。
- save対象の状態objectへ変換するのか。

を決める。無条件に `duplicate(true)` するのも、無条件に共有するのも避ける。

## 6. Autoloadの採用条件

次の質問がすべて説明できる場合に採用する。

- なぜScene所有では不足するのか。
- なぜ一意である必要があるのか。
- いつ初期化され、いつ破棄されるのか。
- テスト時にどう差し替え・初期化するのか。
- 他Autoloadとの起動順依存はあるか。
- global state化による結合増加を許容する理由は何か。

Audioの継続再生、platform service、Scene遷移を越えるsession stateなどは候補になり得る。単なる関数置き場はstatic helperや通常objectを検討する。

## 7. Runtime生成とAuthoring

### Sceneへ保存するもの

- 固定HUD、固定menu、常設camera
- 手作業でanchor、layout、animation trackを調整するもの
- authorがResourceやNodeを割り当てるもの
- Scene固有の接続と順序を持つもの

### Runtime生成するもの

- 数がデータやプレイ状況で変化するもの
- pooling対象
- procedural content
- dynamic list item
- projectile、enemy、effect

生成コードでは、PackedSceneの型、生成失敗、初期化順、親、global/local transform、signal接続、`queue_free()`条件を確認する。

## 8. Process callbackを増やす前の確認

- 値の変化はsignalで通知できないか。
- 一定時間後ならTimerでよいか。
- 補間ならTweenまたはAnimationPlayerでよいか。
- input callbackで十分ではないか。
- physics tickでなければならない理由があるか。

processを使う場合は、不要時に停止できる設計とし、毎フレームallocation、tree探索、load、文字列組立を避ける。

## 9. 設計変更時に残す情報

新しい共通方式を導入した場合は、少なくとも次を `docs/` またはADRへ残す。

- 解決する問題
- 採用した方式
- 採用しなかった代替案
- 依存方向
- Scene / Resource / Autoloadの所有者
- 検証方法
- 移行または削除条件
