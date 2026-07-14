# EnemyEffect・EnemyController・Enemy周辺のSOLID／MVP再設計依頼

添付プロジェクトの実装を確認し、現在肥大化している以下のクラスを再設計してください。

* `EnemyEffect`
* `EnemyEffectSystem`
* `EnemyEffectStack`
* `EnemyEffectInstaller`
* `EnemyController`
* `Enemy`
* `EnemyData`
* `EnemyView`
* その他、上記クラスと密接に関連するクラス

本改修では、既存動作を維持したまま、SOLID原則およびMVPデザインパターンに基づいて責務を分離してください。

単純なクラス名の変更や、既存の巨大クラスを別名の巨大クラスへ置き換える対応は禁止します。

---

# 1. 改修目的

本改修の目的は以下です。

1. `EnemyEffectContext`に集中していた責務を、状態の所有者ごとに分離する
2. `EnemyEffectResolver`または`EnemyEffectSystem`へ集中している処理を分離する
3. `EnemyEffect`基底クラスの肥大化を解消する
4. `EnemyController`を戦闘処理の調整役に限定する
5. 敵の状態、効果処理、表示処理を分離する
6. 各Effectが自身に必要な依存関係のみを保持する
7. Effect発動順と連鎖処理を一か所で管理する
8. Model、View、Presenterの役割を明確にする
9. 既存のゲーム挙動を変更しない
10. 既存テストを維持し、必要な回帰テストを追加する

---

# 2. パラメータークラスの責務

現在、`EnemyEffect`、`EnemyEffectSystem`、`EnemyController`などに分散している状態を、状態の所有者ごとに分離してください。

想定するクラスの例：

* `PlayerHealth`
* `StomachBoard`
* `BattleClock`
* `DigestionInterval`
* `EnemyHp`
* `EnemyAttack`
* `EnemyDefenseStatus`
* `EnemyStomachStatus`
* `EnemyDigestionState`
* `EnemySpawnQueue`

クラス名は、そのクラスが管理する対象を表す名詞形式にしてください。

すべてのクラスへ機械的に`Status`を付ける必要はありません。

各クラスの責務は以下に限定してください。

* 自身が所有する値の保持
* 値を変更する操作
* 不変条件の保証
* 普遍的な出来事の検出
* Signalによる出来事の通知

例：

```gdscript
class_name EnemyHp
extends RefCounted

signal changed(current_hp: int, maximum_hp: int)
signal damaged(amount: int)
signal healed(amount: int)
signal depleted

func take_damage(amount: int) -> int:
    # HP変更と普遍的なSignal通知のみ行う
    return 0
```

パラメータークラスへ、特定スキル固有の反応を実装してはいけません。

禁止例：

```gdscript
func take_damage(amount: int) -> void:
    current_hp -= amount

    if owner.has_recovery_skill:
        heal(10)
```

パラメータークラスへ入れるのは、出来事の検出と通知までです。

---

# 3. 普遍的な出来事と特殊な効果の分離

以下のような出来事は、対応する状態クラスが検出してSignalを発行してください。

* HPが減った
* HPが回復した
* HPが0になった
* 攻撃力が変化した
* 時刻が進んだ
* 消化間隔が変化した
* 敵が消化された
* 敵が吐き戻された
* 胃袋内の配置が変化した
* 隣接関係が変化した

以下のような特殊な反応は、`EnemyEffect`継承クラスへ実装してください。

* ダメージを受けたときHPを10回復する
* ダメージを受けるたび攻撃力を増加する
* 時刻が進んだとき50ダメージを受ける
* 隣接する敵が消化されたとき復活する
* 一定値以下のダメージを無効化する
* 条件達成時に別の敵を生成する

状態クラスは、どのスキルが存在するかを認識してはいけません。

---

# 4. EnemyData

戦闘中に変化する敵のデータは、`EnemyData`で管理してください。

`EnemyData`は`RefCounted`とします。

```gdscript
class_name EnemyData
extends RefCounted

var definition: EnemyInfo

var hp: EnemyHp
var attack: EnemyAttack
var defense: EnemyDefenseStatus
var stomach_status: EnemyStomachStatus
var digestion_state: EnemyDigestionState

var main_skill: EnemySkill
var sub_skill: EnemySkill
```

`EnemyInfo`は初期設定用のResourceとして扱ってください。

`EnemyInfo`から以下を参照して、敵ごとの`EnemyData`を生成してください。

* 初期HP
* 初期攻撃力
* 防御設定
* 表示情報
* メインスキル定義
* サブスキル定義

メインスキルとサブスキルは、それぞれ別の実行インスタンスとして生成してください。

スキル内の`EnemyEffect`も敵ごとに個別化してください。

元の`.tres` Resourceへ以下を保存してはいけません。

* 所有者
* Signal接続
* 発動回数
* 経過時間
* 前回対象
* ActivationData
* 戦闘中の可変値

---

# 5. EnemyEffect基底クラスの縮小

現在の`EnemyEffect`基底クラスへ集約されている以下の責務を外へ移してください。

* HP操作
* 攻撃力操作
* プレイヤーへの攻撃
* 胃袋検索
* 隣接対象検索
* 敵生成
* 時刻変更
* 消化間隔変更
* 防御処理
* ダメージ計算
* 対象選択
* 全敵一覧の管理
* Event enumによる発動判定

`EnemyEffect`基底クラスへ残す責務は、原則として以下だけです。

* Effectの設定値
* priority
* 有効・無効状態
* 所有する敵への参照
* `EnemyEffectStack`への参照
* Effect固有の実行状態
* 発動時データの一時参照
* Signal接続解除
* `apply()`

例：

```gdscript
class_name EnemyEffect
extends Resource

@export var priority := 0

var owner: EnemyData
var effect_stack: EnemyEffectStack

func apply() -> void:
    pass

func unbind() -> void:
    pass
```

`EnemyEffect`基底へ、すべてのEffectが使用できる万能操作メソッド群を追加してはいけません。

禁止例：

```gdscript
func change_hp(...)
func add_attack_delta(...)
func spawn_enemy(...)
func get_targets(...)
func get_adjacent_objects(...)
func attack_player(...)
func add_time_delta(...)
```

Effectが必要とする操作対象は、必要なEffectへだけ注入してください。

---

# 6. Effectの依存性注入

各Effectは、自身が実際に使用する依存関係だけを保持してください。

例えば、被ダメージ時に攻撃力を増やすEffectであれば、必要なのは主に以下です。

* 監視対象の`EnemyHp`
* 変更対象の`EnemyAttack`
* `EnemyEffectStack`

このEffectへ、以下を渡してはいけません。

* `StomachBoard`
* `BattleClock`
* `PlayerHealth`
* `EnemySpawnQueue`
* 全敵一覧
* 万能Context
* 万能Runtime

依存関係は生成・初期化時に外部から注入してください。

`apply()`内で以下の方法により依存関係を探索してはいけません。

* Autoload
* Global
* SceneTree全体の検索
* Group検索
* Resolverへの問い合わせ
* 万能Service Locator

Effectの組み立ては、専用のInstallerまたはFactoryで行ってください。

ただしInstallerがイベント種別ごとの巨大な`if`、`match`、型判定を持たないようにしてください。

---

# 7. Signal接続方式

各`enemy_effect_on_*`は、自身の発動条件となるSignalへ接続してください。

例：

```text
被ダメージ時に発動
→ EnemyHp.damaged

HPが0になったときに発動
→ EnemyHp.depleted

時刻進行時に発動
→ BattleClock.progressed

消化時に発動
→ EnemyDigestionState.digested

吐き戻し時に発動
→ EnemyDigestionState.vomited
```

以下の方式は禁止します。

```text
全Effectへ共通Eventを送信
↓
各Effectがevent enumを確認
↓
該当しなければreturn
```

禁止コード例：

```gdscript
if runtime.is_event(Event.AFTER_ACID_DAMAGE):
```

```gdscript
if activation_data.event != Event.PROGRESS_TIME:
    return
```

Signalを受信した時点で、何が起きたかは確定している設計にしてください。

---

# 8. Request前の発動条件判定

Signalを受信したEffectは、`EnemyEffectStack`へRequestを送る前に発動条件を判定してください。

例：

```gdscript
func _on_damaged(amount: int) -> void:
    if amount > maximum_trigger_damage:
        return

    var data := DamageActivationData.new()
    data.amount = amount

    effect_stack.request(self, data)
```

以下の条件はRequest前に判定してください。

* 対象が所有者自身か
* ダメージ量が条件内か
* 確率条件を満たすか
* 対象が特定の種か
* 隣接条件を満たすか
* 発動回数上限内か
* Effectが有効か

`apply()`実行後に、イベント種別や基本的な対象条件を確認して何もせず終了する構造は禁止します。

---

# 9. apply()の仕様

すべての`EnemyEffect`継承クラスは、共通して以下を実装してください。

```gdscript
func apply() -> void:
    pass
```

`apply()`へ以下を渡してはいけません。

* `EnemyEffectContext`
* `EnemyEffectRuntime`
* Event enum
* 全依存関係をまとめたオブジェクト
* Resolver
* EnemyEffectSystem

長期間使用する依存関係は初期化時に注入し、発動ごとに異なる値はActivationDataとしてRequestへ保持してください。

---

# 10. ActivationData

発動ごとに値が変わる情報は、用途ごとの小さなActivationDataで管理してください。

例：

```gdscript
class_name DamageActivationData
extends EnemyEffectActivationData

var amount: int
var overkill_amount: int
var target: EnemyData
```

```gdscript
class_name TimeActivationData
extends EnemyEffectActivationData

var elapsed_seconds: int
var current_seconds: int
```

ActivationDataへEvent enumを持たせてはいけません。

禁止例：

```gdscript
var event: EnemyEffect.Event
```

Effectの種類と接続先Signalによって、イベント種類は確定しています。

---

# 11. EnemyEffectRequest

`EnemyEffectStack`へ`EnemyEffect`を直接格納しないでください。

発動1回ごとに`EnemyEffectRequest`を生成してください。

```gdscript
class_name EnemyEffectRequest
extends RefCounted

var effect: EnemyEffect
var activation_data: EnemyEffectActivationData
var priority: int
var sequence: int
```

同じEffectが2回発動した場合は、2件のRequestとして保持してください。

Effect参照が同一であることを理由に重複排除してはいけません。

Request実行時は、以下の流れとしてください。

```gdscript
func execute() -> void:
    effect.begin_activation(activation_data)
    effect.apply()
    effect.end_activation()
```

発動時データはRequest作成時に固定し、実行直前までEffect本体へ書き込まないでください。

---

# 12. EnemyEffectStack

`EnemyEffectStack`の責務は以下に限定してください。

* Requestを受け付ける
* Requestを検証する
* priority順へ並べる
* 同priority時の順番を保証する
* Requestを順番に実行する
* 実行中に追加されたRequestを次バッチへ送る
* 無限連鎖を検出する

Stackは以下を担当してはいけません。

* HP変更
* 攻撃力変更
* 時刻変更
* 敵生成
* 盤面検索
* 対象選択
* Effect固有条件の判定
* Effectの依存関係解決

内部配列を外部へ公開せず、必ず`request()`経由で追加してください。

```gdscript
var _pending: Array[EnemyEffectRequest] = []
var _next_batch: Array[EnemyEffectRequest] = []

var _is_processing := false
var _is_scheduled := false
var _next_sequence := 0
```

最初のRequestが届いた瞬間には実行せず、`call_deferred()`で一度だけ処理開始を予約してください。

同じSignal通知中のRequestをすべて収集した後、priorityが小さい順に実行してください。

同priorityの場合はsequenceが小さい順に実行してください。

現在バッチ実行中に届いたRequestは、必ず次バッチへ入れてください。

現在バッチへの途中挿入は禁止します。

無限連鎖対策として、1連鎖あたりの最大実行数を設定してください。

---

# 13. Effectの発動契機別基底クラス

巨大なActivationMask方式を避けるため、必要に応じて発動契機別の中間基底クラスを使用してください。

例：

* `EnemyEffectOnDamaged`
* `EnemyEffectOnDepleted`
* `EnemyEffectOnTimeProgressed`
* `EnemyEffectOnDigested`
* `EnemyEffectOnVomited`
* `EnemyEffectOnTurnStarted`
* `EnemyEffectOnAdjacentChanged`

中間基底クラスは以下を担当して構いません。

* 対応するSignalへの接続
* 共通のRequest前条件
* 共通ActivationDataの作成
* Signal解除

ただし、各中間基底クラスへ無関係な依存関係を追加してはいけません。

---

# 14. EnemyEffectSystem

`EnemyEffectSystem`を残す場合は、Facadeまたは組み立て役に限定してください。

担当してよいもの：

* Effectの初期化開始
* EffectStackの所有
* Installer／Factoryの呼び出し
* Effect群のbind／unbind
* 移行期間中の互換API

担当してはいけないもの：

* HP計算
* 攻撃力計算
* 消化ダメージ計算
* プレイヤーダメージ計算
* 時刻計算
* 盤面検索
* 敵生成処理
* 全イベントの中央振り分け
* Effect固有条件の判定
* 巨大な状態Dictionaryの所有

`EnemyEffectSystem`が旧`EnemyEffectResolver`の名前を変えたクラスにならないようにしてください。

---

# 15. EnemyControllerの分割

現在の`EnemyController`は、少なくとも以下の責務を持っています。

* 消化ダメージ処理
* 敵からプレイヤーへの攻撃処理
* ターン開始処理
* 時刻進行処理
* SeedEffectへの転送
* EnemyEffectSystemの制御
* 敵の表示更新
* ターン結果の構築
* 遅延敵処理
* 吐き戻しや重力制御

これらを責務ごとに分離してください。

推奨する分割先：

```text
EnemyController
├─ EnemyDigestionResolver
├─ EnemyAttackResolver
├─ EnemyTurnProcessor
├─ EnemyEffectSystem
├─ EnemyPresenter
└─ 必要に応じてSeedEffectService
```

---

# 16. EnemyDigestionResolver

以下の責務を`EnemyController`から移してください。

* 消化対象の並び替え
* 酸ダメージの算出
* 消化ダメージの適用
* 超過ダメージの算出
* 消化された敵の判定
* 消化前後の結果データ作成
* 夢種ブロック等による消化補正

候補となる既存メソッド：

* `acid_nightmares`
* `_acid_enemy`
* `_resolve_Acided_enemy_effects`
* `_apply_enemy_damage_values`
* `_get_final_acid_damage`
* `_sort_Acided_enemies`
* `get_acid_damage_breakdown`

`EnemyDigestionResolver`は敵のViewを操作してはいけません。

ダメージ適用前HPを保存し、超過ダメージを正しく計算してください。

```gdscript
var hp_before := enemy.data.hp.current
var applied_damage := enemy.data.hp.take_damage(total_damage)
var overkill := maxi(0, total_damage - hp_before)
```

ダメージ適用後HPを使って超過ダメージを算出してはいけません。

---

# 17. EnemyAttackResolver

以下の責務を`EnemyController`から移してください。

* 敵ごとの攻撃力取得
* 攻撃倍率適用
* プレイヤーへの最終ダメージ算出
* ダメージ値の分割
* 攻撃結果データの生成

候補となる既存メソッド：

* `apply_acid_damage_values`
* `_get_enemy_attack_damage`
* `_get_enemy_attack_damage_values`
* `_sum_damage_values`
* `_split_damage_values`

`apply_acid_damage_values`が敵からプレイヤーへの攻撃を意味している場合、処理内容に合う名前へ変更してください。

例：

```gdscript
resolve_enemy_attacks()
```

---

# 18. EnemyTurnProcessor

以下の責務を`EnemyController`から移してください。

* ターン開始処理
* 時刻進行処理
* ターン終了処理
* 遅延敵の有効化
* 遅延重力の解除
* ターン結果の構築

候補となる既存メソッド：

* `apply_turn_start_effects`
* `apply_progress_time`
* `build_turn_result`
* `activate_deferred_nuisance_enemies`
* `unlock_deferred_nuisance_gravity`

`EnemyTurnProcessor`は処理順を管理してよいですが、個別のHP計算や攻撃計算を直接実装してはいけません。

それらは対応するResolverへ委譲してください。

---

# 19. EnemyControllerの最終責務

分割後の`EnemyController`は、ユースケースの調整役に限定してください。

担当してよいもの：

* 戦闘処理の実行順を指示する
* 各Resolver／Processorを呼び出す
* 処理結果をまとめて返す
* 上位のGameクラスへ結果を返す

担当してはいけないもの：

* 個別のダメージ計算
* HP変更
* 攻撃倍率計算
* Effect発動条件判定
* View更新
* Signal接続
* SeedEffectの大量な単純転送
* 具体サービスの内部生成

例：

```gdscript
class_name EnemyController
extends RefCounted

var digestion_resolver: EnemyDigestionResolver
var attack_resolver: EnemyAttackResolver
var turn_processor: EnemyTurnProcessor

func process_turn(input: EnemyTurnInput) -> BattleTurnResultData:
    var result := BattleTurnResultData.new()

    turn_processor.begin_turn(input, result)
    digestion_resolver.resolve(input, result)
    attack_resolver.resolve(input, result)
    turn_processor.end_turn(input, result)

    return result
```

---

# 20. 依存関係の生成

`EnemyController`自身が、具体的な依存クラスを直接`new()`しないようにしてください。

禁止例：

```gdscript
var enemy_effects := EnemyEffectSystem.new()
var seed_effects := SeedEffectResolver.new()
var digestion_resolver := EnemyDigestionResolver.new()
```

依存関係は上位のComposition Root、Factory、またはsetupメソッドから注入してください。

```gdscript
func setup(
    digestion_resolver_value: EnemyDigestionResolver,
    attack_resolver_value: EnemyAttackResolver,
    turn_processor_value: EnemyTurnProcessor
) -> void:
    digestion_resolver = digestion_resolver_value
    attack_resolver = attack_resolver_value
    turn_processor = turn_processor_value
```

---

# 21. SeedEffectの転送メソッド

`EnemyController`に存在する、SeedEffect関連の単純な転送メソッドを整理してください。

例：

```gdscript
func get_rest_hp():
    return seed_effects.get_rest_hp()
```

このような単純転送は、呼び出し側が適切なServiceを直接使用できる構造へ変更してください。

互換性維持のため一時的に残す場合は、非推奨Adapterとして明示し、新しい処理を追加しないでください。

---

# 22. MVP構造

敵周辺は以下の役割へ分離してください。

```text
Model
→ EnemyData
→ EnemyHp
→ EnemyAttack
→ その他の状態クラス

View
→ EnemyView

Presenter
→ EnemyPresenterまたは整理後のEnemy Node

戦闘ユースケース
→ EnemyController
```

## Model

Modelは以下を参照してはいけません。

* Node
* Sprite
* Label
* Tween
* Tooltip
* SceneTree
* View

## View

Viewは以下を担当してください。

* Sprite表示
* HP表示
* 攻撃力表示
* 表示・非表示
* 色変更
* Tween
* ダメージ演出
* 消化演出
* 復活演出
* Tooltip

Viewはゲーム状態を変更してはいけません。

## Presenter

Presenterは以下を担当してください。

* ModelのSignalをViewへ反映する
* View操作をまとめる
* Controllerからの命令をModelへ伝える
* EnemyDataとEnemyViewを接続する

既存の`Enemy`がNodeである場合、`Enemy`を純粋なModelとして扱ってはいけません。

---

# 23. Enemyクラスの縮小

現在の`Enemy`へ残っている以下の責務を整理してください。

* HP変更
* 攻撃力変更
* 表示処理
* Tooltip
* Tween
* 盤面形状
* Effect管理
* 消化処理
* 互換API

最終的に、`Enemy`がNodeとして残る場合は、PresenterまたはScene上のFacadeとして扱ってください。

以下のようなラッパーは段階移行中のみ許可します。

```gdscript
func take_acid_damage(amount: int) -> int:
    return data.hp.take_damage(amount)
```

新しいゲームルールや計算処理を`Enemy`へ追加してはいけません。

---

# 24. 禁止する代替巨大クラス

以下の名前に限らず、旧Context、Resolver、Controllerと同等の万能クラスを新設してはいけません。

* `EnemyEffectRuntime`
* `EnemyEffectExecution`
* `EnemyEffectEnvironment`
* `EnemyEffectServices`
* `EnemyEffectManager`
* `EnemyBattleContext`
* `EnemyRuntimeData`

以下を同時に保持するクラスは禁止します。

```text
全敵一覧
プレイヤーHP
胃袋
時刻
消化間隔
HP操作
攻撃操作
敵生成
盤面検索
イベント振り分け
Effect状態管理
View更新
ターン進行
```

巨大クラスを複数の小さなファイルへ分割しただけで、相互依存が変わっていない実装も不可とします。

---

# 25. Signal解除とライフサイクル

Effectの破棄、敵の削除、スキル切り替え、メイン・サブスキル更新時には、接続済みSignalを解除してください。

Effectは`unbind()`に相当する処理を持ってください。

二重接続を防止してください。

Signal接続先が解放済みの場合にも安全に処理できるようにしてください。

---

# 26. テスト要件

以下のテストを追加または更新してください。

## EnemyEffectStack

* 同じSignalで複数Requestが追加される
* priorityが小さい順に実行される
* 同priorityではsequence順に実行される
* 同じEffectが2回Requestされた場合、2回実行される
* 実行中に追加されたRequestが次バッチで実行される
* ActivationDataが後続Requestで上書きされない
* 無限連鎖が上限で停止する

## EnemyEffect

* Event enumなしで正しいSignalから発動する
* Request前に発動条件を判定する
* 不要な依存関係を保持しない
* スキルResourceが敵同士で状態共有されない
* unbind後にSignalを受信しない

## EnemyData

* EnemyInfoから正しく初期化される
* メインスキルとサブスキルが別インスタンスになる
* HP、攻撃、防御の状態が敵同士で共有されない

## EnemyController

* 消化Resolver、攻撃Resolver、TurnProcessorの順序を正しく調整する
* 個別の計算をController自身が行わない
* Resolverを差し替えてテストできる

## MVP

* ModelがViewを参照しない
* ViewがModelを変更しない
* PresenterがModelのSignalをViewへ反映する
* EnemyControllerがViewを直接操作しない

---

# 27. 実装完了条件

以下をすべて満たした時点で完了としてください。

## EnemyEffect

* `EnemyEffectContext`が存在しない
* `EnemyEffectRuntime`が存在しない
* `runtime.is_event()`が存在しない
* Event enumによるEffect内分岐が存在しない
* `EnemyEffect`基底が万能操作APIを持っていない
* Effectは必要なSignalへ接続している
* Request前に発動条件を判定している
* `apply()`は引数なしで統一されている
* StackへRequest単位で格納される
* 同じEffectの複数発動が失われない

## EnemyEffectSystem

* 全イベントを中央振り分けしていない
* HP・攻撃・盤面・時刻の計算を持っていない
* 万能Contextの代替になっていない

## EnemyController

* 消化計算が分離されている
* 敵攻撃計算が分離されている
* ターン進行が分離されている
* Viewを直接操作していない
* SeedEffectの大量な単純転送が整理されている
* 具体依存を内部で生成していない
* 主責務がユースケースの調整だけになっている

## MVP

* `EnemyData`にNode参照がない
* `EnemyView`にゲームルールがない
* `Enemy`または`EnemyPresenter`がModelとViewを仲介している
* ControllerがModelとViewの両方を直接更新していない

## 品質

* 既存ゲーム挙動を維持している
* 既存テストが通る
* 新規テストが通る
* 新しい巨大クラスが作られていない
* 循環依存が作られていない
* 各クラスの責務をコメントまたはクラス説明で明示している

---

# 28. 推奨実装順序

以下の順序で段階的に実装してください。

1. 現在の責務と依存関係を一覧化する
2. `EnemyEffect`基底から万能操作APIを切り出す
3. Effectを発動契機別の中間基底へ整理する
4. EffectのRequest前条件判定を実装する
5. 状態クラスからEffect専用Signalを削除する
6. `EnemyEffectSystem`をFacadeへ縮小する
7. `EnemyDigestionResolver`を切り出す
8. `EnemyAttackResolver`を切り出す
9. `EnemyTurnProcessor`を切り出す
10. `EnemyController`を調整役へ縮小する
11. `Enemy`から表示処理を`EnemyView`へ移す
12. ModelとViewをPresenterで接続する
13. SeedEffectの転送APIを整理する
14. 互換Adapterを段階的に削除する
15. テストを追加して回帰確認する

各段階でプロジェクトが実行可能な状態を維持してください。

---

# 29. 作業報告

実装完了時は、以下を報告してください。

1. 作成したクラス
2. 削除したクラス
3. 責務を移動したメソッド一覧
4. `EnemyEffect`から削除した依存関係
5. `EnemyController`から切り出した責務
6. 残している互換Adapter
7. 未完了箇所
8. 実行したテスト
9. テスト結果
10. 既存動作へ影響する可能性がある箇所

コード量を減らしたことではなく、責務と依存関係が正しく分離されたことを成果として扱ってください。
