# EnemyEffect・EnemyData・Enemy表示処理 再設計仕様書

## 0. 目的

本改修では、現在`EnemyEffectContext`および`EnemyEffectResolver`へ集中している以下の責務を分離する。

* プレイヤーおよび敵の状態管理
* 胃袋・時刻・消化間隔の管理
* 普遍的な出来事の検出と通知
* 敵スキル固有の発動条件判定
* 敵スキル固有の効果処理
* 効果発動順の制御
* Enemyの表示制御

主目的は以下とする。

1. `EnemyEffectContext`の巨大化を解消する
2. `EnemyEffectResolver`による状態・イベント・効果実行の一元管理を廃止する
3. 各`enemy_effect_on_*`が、必要なデータにだけ依存する構造にする
4. 効果発動の優先順位と連鎖処理を一か所で管理する
5. Model・View・Presenterを分離する
6. 既存のゲーム挙動を変更しない

---

# 1. パラメータークラスの分離

## 1.1 分離対象

現在`EnemyEffectContext`および`EnemyEffectResolver`が管理している状態を、状態の所有者ごとに分離する。

想定するクラスは以下とする。

* `PlayerHealth`
* `StomachBoard`
* `BattleClock`
* `DigestionInterval`
* `EnemyHp`
* `EnemyAttack`
* `EnemyStomachStatus`
* `EnemyDefenseStatus`
* `EnemyEffectState`
* `EnemySpawnQueue`

クラス名は、そのクラスが管理する対象を表す名詞を使用する。

すべてのクラスへ機械的に`Status`を付ける必要はない。

例：

```text
HPなどの状態値
→ EnemyHp、PlayerHealth

時間
→ BattleClock

盤面
→ StomachBoard

生成要求
→ EnemySpawnQueue
```

## 1.2 パラメータークラスの責務

各パラメータークラスは以下だけを担当する。

* 自身が所有する値の保持
* 値の変更
* 値に関する不変条件の保証
* 普遍的な出来事の検出
* Signalによる出来事の通知

例：

```gdscript
class_name EnemyHp
extends RefCounted

signal changed(current: int, maximum: int)
signal damaged(amount: int)
signal depleted

func take_damage(amount: int) -> void:
    # HPの変更
    # damagedの通知
    # HPが0ならdepletedの通知
```

## 1.3 禁止事項

パラメータークラスには、特定スキルの反応を実装してはならない。

禁止例：

```gdscript
func take_damage(amount: int) -> void:
    current -= amount

    # 禁止：特定スキルの処理
    if owner.has_recovery_skill:
        heal(10)
```

`EnemyHp`が担当するのは「HPが減った」「HPが0になった」という検出と通知までとする。

---

# 2. 普遍的な出来事と特殊効果の分離

## 2.1 パラメータークラスへ配置する処理

以下のような普遍的な出来事は、対応するパラメータークラスが検出してSignalを発行する。

* HPが減った
* HPが回復した
* HPが0になった
* 攻撃力が変化した
* 時刻が進んだ
* 消化間隔が変化した
* 胃袋内の配置が変化した
* 敵が消化された
* 敵が吐き戻された
* 隣接関係が変化した

## 2.2 EnemyEffectへ配置する処理

以下のような特定スキル固有の反応は、`enemy_effect_on_*`へ実装する。

* ダメージを受けたときHPを10回復する
* ダメージを受けるたび攻撃力を増加する
* 時刻が進んだとき50ダメージを受ける
* 隣接する敵が消化されたとき復活させる
* 一定以下のダメージを無効化する
* 一定確率で敵を生成する

パラメータークラスは、このような反応の存在を認識してはならない。

---

# 3. EnemyData

## 3.1 EnemyDataの役割

戦闘中に変化する敵のデータは、`EnemyData`で管理する。

```gdscript
class_name EnemyData
extends RefCounted

var definition: EnemyInfo
var hp: EnemyHp
var attack: EnemyAttack
var stomach_status: EnemyStomachStatus
var defense_status: EnemyDefenseStatus

var main_skill: EnemySkill
var sub_skill: EnemySkill
```

## 3.2 EnemyInfoとの関係

`EnemyInfo`は編集用・初期設定用のResourceとして維持する。

```text
EnemyInfo
→ 初期HP
→ 初期攻撃力
→ 見た目
→ メインスキル定義
→ サブスキル定義
```

敵の生成時に`EnemyInfo`を参照して、敵ごとの`EnemyData`を作成する。

## 3.3 スキルの個体化

メインスキルとサブスキルは、それぞれ対応するResourceから個別に複製する。

同じスキルResourceをメインとサブの両方へ誤って複製してはならない。

```gdscript
main_skill = duplicate_skill(info.main_skill)
sub_skill = duplicate_skill(info.sub_skill)
```

スキル内の各`EnemyEffect`も敵ごとに深く複製する。

プロジェクトファイルとして保存されている元のResourceは、設定定義として扱い、Signal接続や戦闘中の可変値を持たせてはならない。

敵ごとに複製された`EnemyEffect`のみ、実行個体として使用してよい。

---

# 4. EnemyEffectの発動構造

## 4.1 applyの共通仕様

すべての`enemy_effect_on_*`は、共通して以下のメソッドを持つ。

```gdscript
func apply() -> void:
    pass
```

`apply()`へ`EnemyEffectContext`、`EnemyEffectRuntime`、イベントenumなどを渡してはならない。

## 4.2 Signal接続

敵ごとに複製された`enemy_effect_on_*`は、初期化時に自身の発動条件となるSignalへ接続する。

例：

```text
被ダメージ時に発動
→ EnemyHp.damagedへ接続

HPが0になったとき発動
→ EnemyHp.depletedへ接続

時刻進行時に発動
→ BattleClock.progressedへ接続

隣接物の消化時に発動
→ StomachBoardまたは配置管理クラスのSignalへ接続
```

全Effectへ共通イベントを通知し、各Effectが`is_event()`で判定する方式は禁止する。

禁止対象：

```gdscript
if runtime.is_event(Event.AFTER_ACID_DAMAGE):
```

```gdscript
if context.event == Event.PROGRESS_TIME:
```

`enemy_effect_on_*`へSignalが届いた時点で、出来事の種類は確定しているものとする。

## 4.3 Effect内での追加条件

Signalの発生だけでは発動条件が確定しない場合、各Effect内のSignal受信メソッドで追加判定する。

```gdscript
func _on_damaged(amount: int) -> void:
    if amount > maximum_trigger_damage:
        return

    effect_stack.request(self, DamageActivationData.new(amount))
```

以下のような条件はEffect側で判定する。

* ダメージ量が一定以下
* 確率判定
* 対象が自分自身か
* 隣接対象が特定種別か
* 一定回数ごとか
* 一定時間ごとか

---

# 5. Effectが使用するデータ

## 5.1 長期間使用する参照

Effectが継続して使用する参照は、Effectの初期化時に注入する。

例：

* 自分の`EnemyData`
* 自分の`EnemyHp`
* 自分の`EnemyAttack`
* `BattleClock`
* `StomachBoard`
* `PlayerHealth`
* `EnemySpawnQueue`
* `EnemyEffectStack`

各Effectは、自身が必要とする参照だけを保持する。

すべてのデータをまとめた`Context`、`Runtime`、`Services`などをEffectへ渡してはならない。

## 5.2 依存関係の取得方法

依存関係はEffectの生成・初期化時に外部から注入する。

`apply()`内で以下の方法により依存関係を探索してはならない。

* AutoloadやGlobalから取得する
* SceneTree全体を検索する
* Groupから検索する
* Resolverへ問い合わせて全データを取得する
* 巨大なService Locatorを使用する

Effectの接続と依存性注入は、専用の組み立て処理で行う。

例：

```text
EnemyEffectInstaller
または
EnemySkillInstaller
```

この組み立てクラスは全サービスを知ってよいが、各Effectへは必要な参照だけを設定する。

---

# 6. 発動時データ

## 6.1 発動時データの必要性

以下の値は、Signalが発生するたびに内容が異なる。

* 今回受けたダメージ量
* 今回の超過ダメージ量
* 今回進んだ秒数
* 今回消化された敵
* 今回吐き戻された敵
* 今回対象になった隣接物

これらをEffect本体の単一フィールドへ、リクエスト時点で直接保存してはならない。

複数回発動した場合に、後の値で上書きされるためである。

## 6.2 ActivationData

発動時の値は、用途ごとの小さなデータクラスへ格納する。

```gdscript
class_name EnemyEffectActivationData
extends RefCounted
```

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

ActivationDataはイベント種別を判定するためのものではない。

以下は持たせない。

```gdscript
var event: EnemyEffect.Event
```

Effectは自身のクラスと接続先Signalによって、どの出来事に反応しているか既に確定している。

---

# 7. EnemyEffectRequest

## 7.1 Stackへ格納する単位

`EnemyEffectStack`へ`EnemyEffect`本体を直接格納してはならない。

発動1回ごとに`EnemyEffectRequest`を生成する。

```gdscript
class_name EnemyEffectRequest
extends RefCounted

var effect: EnemyEffect
var activation_data: EnemyEffectActivationData
var priority: int
var sequence: int
```

同じEffectが同時に2回発動した場合も、2件のRequestとして保持する。

Effect参照の重複を理由にRequestを削除してはならない。

## 7.2 apply引数なしの実現方法

`EnemyEffectRequest`の実行直前にだけ、発動時データをEffectへ設定する。

```gdscript
func execute() -> void:
    effect.begin_activation(activation_data)
    effect.apply()
    effect.end_activation()
```

Effect側は`apply()`内で、自身に一時設定されたActivationDataを取得する。

```gdscript
func apply() -> void:
    var data := get_activation_data() as DamageActivationData
    if data == null:
        return

    attack.add_value(data.amount)
```

ActivationDataはRequest作成時に固定し、実行直前までEffect本体へ設定しない。

これにより、複数の発動要求による値の上書きを防止する。

---

# 8. EnemyEffectStack

## 8.1 責務

`EnemyEffectStack`の責務は以下に限定する。

* 発動要求を受け付ける
* Requestの真正性を検証する
* Requestを保持する
* priority順に並べ替える
* Effectを順番に実行する
* 実行中に追加されたRequestを次バッチへ送る
* 無限連鎖を検出する

以下は担当してはならない。

* HP変更
* 攻撃力変更
* 時刻変更
* 敵生成の実処理
* 盤面検索
* 対象選択
* Effect固有条件の判定
* Effect状態の管理

## 8.2 内部配列

Stackは少なくとも以下を持つ。

```gdscript
var _pending: Array[EnemyEffectRequest]
var _next_batch: Array[EnemyEffectRequest]

var _is_processing := false
var _is_scheduled := false
var _next_sequence := 0
```

配列を外部へ公開してはならない。

追加は必ず`request()`経由で行う。

## 8.3 Requestの検証

`request()`では最低限以下を検証する。

* Requestがnullではない
* Effectがnullではない
* Effectが有効である
* Effectの初期化が完了している
* Effectの所有者が有効である
* priorityとsequenceがStack側で確定されている

## 8.4 最初の実行タイミング

最初のRequestが追加された瞬間には実行しない。

初回Request追加時に、処理開始を1回だけ遅延予約する。

```gdscript
func request(
    effect: EnemyEffect,
    activation_data: EnemyEffectActivationData = null
) -> bool:
    var request := _create_request(effect, activation_data)

    if _is_processing:
        _next_batch.append(request)
    else:
        _pending.append(request)

    if not _is_processing and not _is_scheduled:
        _is_scheduled = true
        call_deferred("_process_requests")

    return true
```

`call_deferred()`は即時実行ではなく、アイドル時間に呼び出しを予約する。そのため、現在進行中のSignal通知で各EffectがRequestを追加し終えた後に、まとめて処理を開始できる。

## 8.5 ソート規則

各バッチを以下の順でソートする。

1. `priority`の昇順
2. 同じpriorityの場合は`sequence`の昇順

```text
priorityが小さいEffect
→ 先に実行

同じpriority
→ 先にRequestされたEffectを先に実行
```

順序は毎回決定的でなければならない。

## 8.6 実行中の追加Request

現在のバッチ実行中に発生したRequestは、現在の配列へ追加しない。

必ず`_next_batch`へ追加する。

```text
現在バッチをソート
↓
現在バッチを順次実行
↓
実行中に発生したRequestは次バッチへ追加
↓
現在バッチ完了
↓
次バッチを再ソート
↓
次バッチ実行
```

現在バッチへの途中挿入は禁止する。

## 8.7 重複排除

同じEffectから複数のRequestが届いても、重複排除してはならない。

禁止例：

```gdscript
if destination.has(effect):
    return false
```

発動1回につきRequestを1件保持する。

## 8.8 無限連鎖対策

1回の連鎖で実行可能なRequest数へ上限を設定する。

```gdscript
const MAX_REQUESTS_PER_CHAIN := 1000
```

上限を超えた場合は以下を行う。

* 残りのRequestを破棄する
* エラーを出力する
* Effect名、所有者、直前のRequestを記録する
* `_is_processing`を必ず解除する

---

# 9. EnemyEffectResolver

## 9.1 最終状態

`EnemyEffectResolver`は、現在保持している状態と効果処理を各所有クラスへ移した後、原則として削除する。

移動対象の例：

```text
プレイヤーHP
→ PlayerHealth

消化間隔
→ DigestionInterval

敵HP・攻撃力
→ EnemyData内の各クラス

敵生成要求
→ EnemySpawnQueue

時刻差分
→ BattleClock

防御・無効化状態
→ EnemyDefenseStatus

Effect固有の継続状態
→ 敵ごとのEnemyEffectまたはEnemyEffectState

効果発動順
→ EnemyEffectStack
```

## 9.2 移行中の制限

段階移行のため一時的に`EnemyEffectResolver`を残す場合でも、以下は禁止する。

* 全Effectをループしてイベントを振り分ける
* `EnemyEffectRuntime`を生成する
* `event`をEffectへ渡す
* `runtime.is_event()`を使用させる
* HP・攻撃・時間・盤面など全機能の窓口になる
* Effectの発動順を管理する
* 新しい永続状態Dictionaryを追加する

移行中のResolverは、旧APIを新クラスへ転送するだけのAdapterに限定する。

移行完了後に削除する。

---

# 10. 禁止する代替Context

以下のような、旧`EnemyEffectContext`と同等の万能クラスを新設してはならない。

* `EnemyEffectRuntime`
* `EnemyEffectExecution`
* `EnemyEffectEnvironment`
* `EnemyEffectServices`
* `EnemyEffectEventData`
* `EnemyEffectTargets`

名称にかかわらず、以下を同時に持つクラスは禁止する。

```text
source
target
enemies
stomach
clock
resolver
event
HP操作
攻撃操作
敵生成
盤面検索
時間変更
状態保存
```

`EnemyEffectContext`を別名へ変更しただけの実装は、本仕様を満たさない。

---

# 11. EnemyEffectの状態

## 11.1 設定値

以下はEffect Resourceの設定値として保持してよい。

* priority
* 効果量
* 発動確率
* 発動間隔
* 対象種別
* 最大発動回数
* 生成する敵の定義

## 11.2 敵ごとの状態

以下は敵ごとに複製されたEffectだけが保持してよい。

* 経過秒数
* 発動回数
* 前回対象
* 累積値
* Signal接続
* 所有するEnemyDataへの参照
* 必要なパラメータークラスへの参照

元のResourceへこれらを保存してはならない。

---

# 12. MVP構造

## 12.1 Model

Modelは以下とする。

* `EnemyData`
* `EnemyHp`
* `EnemyAttack`
* `EnemyStomachStatus`
* その他の敵状態クラス

ModelはNode、Sprite、Label、Tween、Tooltipを参照してはならない。

## 12.2 View

敵の表示処理は`EnemyView`および対応するViewクラスへ移す。

Viewが担当するもの：

* Sprite表示
* HP表示
* 攻撃力表示
* 表示・非表示
* 色変更
* Tween
* ダメージ表示
* 消化演出
* 復活演出
* Tooltip

Viewはゲームルールを変更してはならない。

## 12.3 Presenter

`EnemyPresenter`、またはPresenterとして整理した既存`Enemy`クラスが以下を担当する。

* `EnemyData`と`EnemyView`の接続
* ModelのSignalをViewへ反映
* Controllerからの命令をModelへ転送
* Enemy生成時の初期化
* SkillおよびEffectの組み立て開始

既存の`Enemy`がNodeである場合、Enemyそのものを純粋なModelとして扱ってはならない。

```text
EnemyData
→ Model

EnemyView
→ View

EnemyまたはEnemyPresenter
→ Presenter
```

---

# 13. Signalの解除

Effectの破棄、スキル切り替え、敵の消化、敵の削除時には、接続したSignalを解除する。

各Effectは以下に相当する処理を持つ。

```gdscript
func unbind() -> void:
    # 接続したSignalを解除
    # 所有者参照を解除
    # ActivationDataを破棄
```

同じEffectへ二重にSignal接続してはならない。

---

# 14. 実装完了条件

以下をすべて満たした時点で完了とする。

## 構造

* `EnemyEffectContext`が削除されている
* 万能な代替Contextが存在しない
* `EnemyEffectRuntime`が存在しない
* `EnemyEffectResolver`が削除されているか、一時Adapterだけになっている
* `EnemyEffectStack`が`EnemyEffectRequest`を保持している
* StackがEffect参照を重複排除していない
* `apply()`が引数なしで統一されている
* `runtime.is_event()`が残っていない
* `prepare(runtime)`が残っていない
* Effectが必要なSignalへ直接接続している

## 動作

* 同一Signalで発生したRequestがすべて収集される
* priorityが小さい順に実行される
* 同一priorityではRequest順に実行される
* 同じEffectが2回発動した場合、2回実行される
* 実行中に追加されたRequestが次バッチで実行される
* 発動時データが後続Requestで上書きされない
* 無限連鎖が上限で停止する
* 元のEffect Resourceが敵同士で状態共有されない
* スキル切り替え時に古いSignal接続が残らない

## MVP

* EnemyDataにNode参照がない
* Viewにゲーム状態の変更処理がない
* ModelのSignalからViewが更新される
* Enemy Node内に直接的なSprite・Label操作が残っていない

---

# 15. 推奨実装順序

1. 各パラメータークラスへ状態とSignalを移す
2. `EnemyData`へ各状態クラスを保持させる
3. メイン・サブスキルとEffectを敵ごとに複製する
4. `EnemyEffectRequest`とActivationDataを作成する
5. `EnemyEffectStack`をRequest方式へ変更する
6. 代表的なEffectを1種類だけSignal方式へ移行する
7. 優先順・複数発動・連鎖処理をテストする
8. 残りの`enemy_effect_on_*`を順次移行する
9. Resolverの各状態を対応クラスへ移す
10. ResolverとRuntime系クラスを削除する
11. EnemyData・EnemyView・Presenterを分離する
12. 全ゲーム動作の回帰テストを行う
