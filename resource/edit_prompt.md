# EnemyEffect・Installer・MVP残課題 修正要件書

## 0. 対象

本改修では、既に達成済みの以下には原則として変更を加えないこと。

* Model層からActivationData依存を削除した構造
* `EnemyEffectRequest`と`EnemyEffectStack`
* 引数なしの`apply()`
* priority／sequenceによる実行順
* `EnemyData`の`RefCounted`化
* `EnemyDigestionResolver`からView操作とEffect実行を除去した構造
* `EnemyEffectRefreshProcessor`
* 縮小後の`EnemyController`

今回修正するのは、前回レビューで未達成または部分達成と判定された項目だけとする。

---

# 1. EnemyEffectの中央イベント振り分けを廃止する

## 1.1 現在の問題

現在の発動経路は、概ね以下となっている。

```text
EnemyDigestionProcessor等
↓
EnemyEffectSystem.notify_*
↓
EnemyEffectInstaller.queue_*
↓
Installerが登録済みEffectを走査
↓
EnemyEffectStackへRequest
```

この構造では、`EnemyEffectSystem`と`EnemyEffectInstaller`がイベントの種類を中央管理している。

新しいイベントを追加する際に、以下の複数クラスを変更する必要がある。

* `EnemyEffectSystem`
* `EnemyEffectInstaller`
* 呼び出し元Processor
* 対応Effect

これはOCPおよびSRPの観点で未達成である。

## 1.2 要求する構造

各Effect実行インスタンスは、自身の発動条件となる普遍的Signalへ直接接続すること。

例：

```text
EnemyHp.damaged
→ 被ダメージ系Effect

BattleClock.progressed
→ 時刻進行系Effect

EnemyStomachStatus.digested
→ 消化時Effect

EnemyStomachStatus.revived
→ 復活時Effect
```

Signal受信後は、Effectまたは発動契機別中間基底クラスが以下を行う。

1. Signal引数を受け取る
2. 発動条件を判定する
3. ActivationDataを生成する
4. `EnemyEffectStack`へRequestする

例：

```gdscript
func bind_trigger(hp: EnemyHp) -> void:
    _hp = hp

    if not _hp.damaged.is_connected(_on_damaged):
        _hp.damaged.connect(_on_damaged)


func _on_damaged(amount: int) -> void:
    var data := DamageActivationData.new()
    data.amount = amount
    data.target = owner

    if not accepts_activation(data):
        return

    request_activation(data)
```

## 1.3 削除対象

最終的に以下のような中央通知APIを削除すること。

```gdscript
EnemyEffectSystem.notify_progress_time(...)
EnemyEffectSystem.notify_digested(...)
EnemyEffectSystem.notify_adjacent_digested(...)
EnemyEffectSystem.notify_acid_damage_applied(...)
```

同様に、Installerが持つ以下のようなイベント別配列と通知処理も削除すること。

```gdscript
_progress_time_effects
_before_acid_effects
_after_acid_effects
_digested_effects
_adjacent_digested_effects
```

```gdscript
queue_progress_time(...)
queue_after_acid_damage(...)
queue_digested(...)
```

## 1.4 禁止事項

以下の形へ戻してはならない。

```text
全Effectへ共通イベントを通知
↓
Effect内部でイベント種別判定
```

Event enumやActivationData型による中央振り分けも禁止する。

---

# 2. EnemyEffectInstallerを組み立て専用に限定する

## 2.1 現在の問題

Installerが以下を担当している。

* Event別Effect配列の管理
* Effect発動の中央振り分け
* `setup_*`メソッドの動的探索
* 依存注入
* Signal登録の中継

また、以下のような動的呼び出しが使用されている。

```gdscript
if effect.has_method(method):
    effect.callv(method, arguments)
```

この方式では依存関係の不足やメソッド名の誤りを、実行時まで検出できない。

## 2.2 Installerの最終責務

Installerの責務は以下に限定すること。

* 敵ごとに複製されたEffectの初期化
* Effectへ必要な依存関係を渡す
* Effectの`bind()`を呼ぶ
* Effectの`unbind()`を呼ぶ
* Effectのライフサイクルを管理する

Installerは、戦闘中のイベント通知やRequest生成を担当してはならない。

## 2.3 明示的な初期化契約

可能な範囲で、`has_method()`と`callv()`による動的注入を減らすこと。

発動契機別の中間基底クラスへ明示的な初期化メソッドを持たせる。

例：

```gdscript
class_name EnemyEffectOnDamage
extends EnemyEffect

func setup_damage_trigger(
    hp: EnemyHp,
    stack: EnemyEffectStack
) -> void:
    _hp = hp
    effect_stack = stack
```

```gdscript
class_name EnemyEffectOnTimeProgressed
extends EnemyEffect

func setup_time_trigger(
    clock: BattleClock,
    stack: EnemyEffectStack
) -> void:
    _clock = clock
    effect_stack = stack
```

特殊な依存だけを具体Effectへ渡す。

例：

```gdscript
func setup_attack_target(
    attack: EnemyAttack
) -> void:
    _attack = attack
```

## 2.4 禁止事項

Installerを次のようなService Locatorにしてはならない。

```gdscript
effect.setup(installer)
effect.get_stomach_from(installer)
effect.get_clock_from(installer)
```

Installer内に大量の具体Effect型判定を追加してはならない。

```gdscript
if effect is EnemyEffectA:
    ...
elif effect is EnemyEffectB:
    ...
```

---

# 3. EnemyEffectOnDigestedの継承関係を修正する

## 3.1 現在の問題

現在、以下の継承関係になっている。

```gdscript
class_name EnemyEffectOnDigested
extends EnemyEffectOnTimeProgressed
```

消化時Effectは、時間進行時Effectの一種ではない。

ActivationDataが時間情報を持つという実装上の都合だけで継承しているため、意味的な`is-a`関係が成立していない。

## 3.2 要求する構造

共通する時間情報取得処理が必要な場合は、共通基底を新設する。

例：

```text
EnemyEffect
└─ EnemyEffectWithTimeData
   ├─ EnemyEffectOnTimeProgressed
   └─ EnemyEffectOnDigested
```

```gdscript
class_name EnemyEffectWithTimeData
extends EnemyEffect

func get_time_data() -> TimeActivationData:
    return get_activation_data() as TimeActivationData
```

または、継承を使用せず小さなヘルパーへ分離する。

消化時Effectと時間進行時Effectを、互いの派生クラスにしてはならない。

---

# 4. EnemyEffect基底からEnemy Node依存を除去する

## 4.1 現在の問題

`EnemyEffect`基底が以下を保持している。

```gdscript
var owner: EnemyData
var source: Enemy
```

また、基底クラスが`Enemy` Nodeのメソッドを呼び出している。

```gdscript
source.should_apply_nightmare_skill()
source.is_Acided()
source.get_current_hp()
source.get_max_hp()
```

これにより、すべてのEffectがScene上のEnemy Nodeへ依存している。

Model、View、Presenterの分離が不十分となり、Effect単体テストも難しくなる。

## 4.2 要求する構造

`EnemyEffect`基底の所有者は原則として`EnemyData`だけとする。

```gdscript
var owner: EnemyData
```

以下の状態は`EnemyData`内のModelから取得すること。

* 現在HP
* 最大HP
* 消化状態
* 攻撃力
* 防御状態
* スキル有効状態

例：

```gdscript
owner.hp.current_value
owner.hp.maximum_value
owner.stomach_status.is_digested
```

## 4.3 Scene上のEnemyが必要な場合

盤面位置、Node座標、隣接Nodeなどが必要な一部のEffectだけに、必要な依存を注入する。

可能であれば、Enemy Nodeそのものではなく専用の問い合わせインターフェースを使用する。

例：

```gdscript
class_name EnemyPlacementQuery
extends RefCounted

func get_adjacent_enemies(
    owner: EnemyData
) -> Array[EnemyData]:
    return []
```

基底Effectへ全Enemy Nodeを渡してはならない。

## 4.4 完了条件

* `EnemyEffect`基底に`source: Enemy`が存在しない
* 基底EffectからEnemy View／Nodeメソッドを呼ばない
* Enemy Nodeが必要なEffectだけが個別に依存を持つ
* HPや消化状態は`EnemyData`から取得する

---

# 5. EnemyEffect基底の責務をさらに縮小する

## 5.1 現在の問題

基底Effectが以下の判定を持っている可能性がある。

* 所有者が消化済みか
* ナイトメアスキルが適用可能か
* 所有者HP条件
* ActivationDataからの各種値取得
* 複数のライフサイクル条件

これらの一部は、すべてのEffectに共通ではない。

## 5.2 基底へ残してよい責務

```text
priority
enabled
owner
effect_stack
runtime state
begin_activation()
end_activation()
get_activation_data()
request_activation()
apply()
bind()
unbind()
```

## 5.3 移動対象

以下は、該当する中間基底または具体Effectへ移すこと。

* DamageActivationData固有処理
* TimeActivationData固有処理
* DigestionActivationData固有処理
* 隣接対象処理
* 消化済み所有者の特殊条件
* 特定スキルカテゴリだけに適用される条件

基底Effectに新しいActivationData型を追加するたび修正が必要な構造は禁止する。

---

# 6. EnemyEffectSystemを中央イベント窓口から外す

## 6.1 現在の問題

`EnemyEffectSystem`に以下のAPIが残っている。

```gdscript
notify_progress_time(...)
notify_digested(...)
notify_adjacent_digested(...)
notify_acid_damage_applied(...)
```

このため、EffectSystemがイベント種類とActivationData生成を中央管理している。

## 6.2 最終責務

`EnemyEffectSystem`は以下に限定する。

* EffectStackの所有
* Effectインスタンスのインストール
* Effectのbind／unbind
* スキル交換時の再構築
* Effect全体の有効／無効管理
* 必要に応じたFacade

EffectSystemは、個々のゲームイベントを受け取ってEffectを選別してはならない。

## 6.3 許可する入口

次のようなライフサイクル単位の入口は許可する。

```gdscript
install_enemy_effects(enemy_data)
remove_enemy_effects(enemy_data)
refresh_enemy_effects(enemy_data)
clear_all()
```

以下のイベント別入口は削除対象とする。

```gdscript
notify_damage(...)
notify_time_progressed(...)
notify_digested(...)
notify_vomited(...)
```

---

# 7. EnemyDigestionProcessorのイベント知識を減らす

## 7.1 現在の問題

Processorが以下のEffect通知を個別に知っている。

```gdscript
notify_acid_damage_applied()
notify_adjacent_acid_damage()
notify_digested()
notify_digestion_batch()
notify_adjacent_digested()
```

Processorが新しいEffectイベントの追加点になっている。

## 7.2 要求する構造

Processorは消化ユースケースの処理順だけを担当する。

```text
Resolverで消化処理
↓
Modelを変更
↓
Model／Boardが普遍的Signalを通知
↓
Effectが直接Signalを受信
↓
StackへRequest
```

ProcessorからEffect種別を指定した通知を削除すること。

Processorは以下だけを扱う。

* `EnemyDigestionResolver`の実行
* 結果の収集
* 必要なPresenterへの結果通知
* ユースケース全体の完了

---

# 8. EnemyPresenterから他EnemyのView直接参照を除去する

## 8.1 現在の問題

Presenterが以下のように、結果内のEnemy NodeからViewへ直接アクセスしている。

```gdscript
result.enemy.enemy_view.show_damage_values(
    result.damage_values
)
```

この構造では、1つのPresenterが自身にbindされたModel／View以外も操作できる。

## 8.2 要求する構造

各EnemyPresenterは、自身にbindされたModelとViewだけを操作すること。

```gdscript
var _model: EnemyData
var _view: EnemyView
```

消化結果をPresenterへ渡す場合、対象ごとのPresenterを取得する専用レジストリまたは上位調整役を使用する。

例：

```gdscript
class_name EnemyPresentationCoordinator
extends RefCounted

var _presenters: Dictionary = {}

func present_digestion_batch(
    batch: EnemyDigestionBatchResult
) -> void:
    for result in batch.results:
        var presenter: EnemyPresenter = _presenters.get(
            result.enemy
        )

        if presenter != null:
            presenter.present_digestion_result(result)
```

`EnemyPresenter.present_digestion_result()`内では、自身のViewだけを使用する。

```gdscript
func present_digestion_result(
    result: EnemyDigestionResult
) -> void:
    if result.enemy != _model:
        return

    _view.show_damage_values(result.damage_values)
```

## 8.3 禁止事項

Presenterから以下へ直接アクセスしてはならない。

```gdscript
enemy.enemy_view
enemy.get_node(...)
SceneTree検索
Group検索
```

---

# 9. Enemy Nodeの直接View操作を段階的に削減する

## 9.1 現在の問題

`Enemy` Nodeに以下のような直接View操作が多数残っている。

```gdscript
enemy_view.pulse_damage()
enemy_view.show_damage_values(...)
enemy_view.play_digested()
enemy_view.show_hp(...)
```

さらに、`Game`など外部クラスから以下が呼ばれている。

```gdscript
enemy.pulse_damage()
```

互換Facadeとして許容されているが、MVP移行完了には至っていない。

## 9.2 修正対象

以下の表示責務をPresenterへ移すこと。

* HP表示
* 攻撃力表示
* 被ダメージ演出
* 回復演出
* 消化演出
* 復活演出
* Tooltip表示
* 状態による表示／非表示
* 色変更
* Tween開始

## 9.3 Enemy Nodeへ残してよいもの

Enemy NodeをScene上のFacadeとして残す場合、公開メソッドはPresenterへの転送だけにする。

```gdscript
func pulse_damage() -> void:
    presenter.present_damage_pulse()
```

新しい表示ロジックをEnemy Nodeへ追加してはならない。

外部クラスからの新規呼び出しは、原則としてPresenterまたはPresentationCoordinatorへ向けること。

---

# 10. テスト要件

## 10.1 Signal直接接続

* 被ダメージEffectが`EnemyHp.damaged`へ直接接続される
* 時刻Effectが`BattleClock.progressed`へ直接接続される
* 消化Effectが消化状態の普遍的Signalへ直接接続される
* `EnemyEffectSystem.notify_*()`なしでEffectが発動する
* `unbind()`後にEffectがRequestを送らない
* 二重bindでSignalが二重接続されない

## 10.2 Installer

* Installerがイベント別Effect配列を保持していない
* InstallerがEffectイベントを通知しない
* Installerが具体Effect型のif／match分岐を持たない
* 必要な依存だけがEffectへ設定される
* 存在しない`setup_*`名を動的に呼ぶ実装が残っていない、または使用範囲が明確に限定されている

## 10.3 EnemyEffect

* 基底EffectがEnemy Nodeを参照しない
* HPや消化状態を`EnemyData`から取得する
* Digested EffectがTime Progressed Effectを継承していない
* 新しいActivationData型追加時に基底Effectの変更が不要
* Node依存が必要なEffectだけが個別依存を持つ

## 10.4 EnemyEffectSystem

* イベント別`notify_*()`が存在しない
* Effectの選別やActivationData生成を行わない
* install／unbind／refreshだけで動作する

## 10.5 Processor

* `EnemyDigestionProcessor`がEffectSystemへイベント別通知を行わない
* Model SignalのみでEffect Requestが生成される
* Processorは消化ユースケースの順序調整だけを行う

## 10.6 MVP

* Presenterが他EnemyのViewを直接参照しない
* 各Presenterは自身のModel／Viewだけを操作する
* DigestionBatchResultの表示はPresentationCoordinator等が対象Presenterへ振り分ける
* `Enemy` Node内の直接View操作が減っている
* Controller、Resolver、ProcessorからViewを直接操作しない

---

# 11. 実装完了条件

以下をすべて満たした時点で完了とする。

## Effect発動

* Effectが普遍的Signalへ直接接続している
* `EnemyEffectSystem.notify_*()`が削除されている
* Installerのイベント別Effect配列が削除されている
* ProcessorがEffectイベントを個別通知していない
* Signal受信後、Effect側でActivationDataを生成している

## 依存関係

* `EnemyEffect`基底がEnemy Nodeへ依存していない
* `EnemyEffectOnDigested`が`EnemyEffectOnTimeProgressed`を継承していない
* InstallerがService Locatorまたは中央Dispatcherになっていない
* Effectは必要な依存だけを保持している

## MVP

* Presenterが自身以外のEnemy Viewを直接操作していない
* Batch表示は専用CoordinatorからPresenterへ振り分けられる
* `Enemy` NodeのView操作が互換転送に限定されている
* Controller、Resolver、ProcessorがViewを参照していない

## 品質

* 全GDScriptが解析可能
* 既存テストが成功する
* 本要件で追加したテストが成功する
* 新しい巨大Manager、Context、Runtime、Dispatcherを作っていない
* 既存ゲーム挙動を維持している

---

# 12. 推奨実装順序

1. `EnemyEffectOnDigested`の継承関係を修正する
2. `EnemyEffect`基底からEnemy Node依存を除去する
3. 発動契機別中間基底へSignalのbind／unbindを実装する
4. Effect側でActivationDataを生成する
5. Installerのイベント別Effect配列を削除する
6. `EnemyEffectSystem.notify_*()`を削除する
7. `EnemyDigestionProcessor`のEffect通知を削除する
8. Installerを依存注入とライフサイクル管理だけへ縮小する
9. Presenterの他Enemy View直接参照を削除する
10. PresentationCoordinator等を導入する
11. Enemy Nodeの直接View操作をPresenterへ移す
12. テストとゲーム全体の回帰確認を行う

各段階でプロジェクトが起動可能な状態を維持すること。

---

# 13. 作業完了報告

実装完了時は以下を報告すること。

1. 削除した`EnemyEffectSystem.notify_*()`一覧
2. 削除したInstallerのイベント別配列一覧
3. Signalへ直接接続するよう変更したEffect基底一覧
4. `EnemyEffect`基底から削除したEnemy Node依存
5. 修正した継承関係
6. Processorから削除したEffect通知処理
7. Presenterから削除した他Enemy View参照
8. Enemy NodeからPresenterへ移した表示処理
9. 残している互換Facade
10. 未完了箇所
11. 実行したテストと結果
12. 既存動作へ影響する可能性がある箇所
