# pulse_theme リリース手順

`pulse_theme` を pub.dev に公開するための手順書。
**pub.dev への公開は実質的に不可逆**（→ [6. 取り消しについて](#6-取り消しについて)）なので、
手順を飛ばさずに上から順に実行すること。

本書の pub.dev 仕様に関する記述は [dart.dev/tools/pub/publishing](https://dart.dev/tools/pub/publishing) /
[automated-publishing](https://dart.dev/tools/pub/automated-publishing) / [pub.dev/policy](https://pub.dev/policy)
を一次ソースとしている。

---

## 0. 全体像

pub.dev には「新規パッケージの初回公開だけは人間が手で行う」という仕様上の制約がある。

```
  ┌── 初回だけ（0.5.0）──────────────────────────────────┐
  │  1. 手動 `dart pub publish`（ローカル macOS から）      │
  │  2. publisher `i-willink.com` へ transfer（不可逆）    │
  │  3. Automated publishing を有効化                      │
  └──────────────────────────────────────────────────────┘
                          ↓
  ┌── 2 回目以降（0.5.1 〜）─────────────────────────────┐
  │  version 更新 → CHANGELOG → PR → main → タグ push     │
  │  → publish.yml が OIDC で自動公開                      │
  └──────────────────────────────────────────────────────┘
```

なぜ初回だけ手動なのか — dart.dev の原文:

> Today, you can only automate publishing of existing packages.
> To create a new package, you must publish the first version using `dart pub publish`.

つまり「まだ pub.dev に存在しないパッケージ」に対して Automated publishing は設定できない。
GitHub Actions から初回公開することは**仕様上不可能**。

---

## 1. 初回公開（0.5.0）— 一度きり

### 1-1. 事前ゲート（公開前に必ず全部通す）

公開したバージョンは**差し替えられない**。README の誤字も description の誤りも、
直すには新しいバージョンを出すしかない。以下を全部確認してから進むこと。

```bash
cd ~/GitHub/pulse_theme
git switch main && git pull

# 作業ツリーを完全にクリーンにする（重要 — 下の注意を読むこと）
git status --porcelain          # 何も出ないこと

flutter pub get
flutter analyze                 # No issues found!
flutter test                    # 下の「golden について」を参照
dart pub publish --dry-run      # Package has 0 warnings.
```

`main` の HEAD で CI が green であることも実測で確認する（自己申告で済ませない）:

```bash
gh run list --branch main --limit 5
```

> **⚠️ 作業ツリーの汚れがそのまま tarball に入る**
>
> `dart pub publish` は「パッケージルート配下の**全ファイル**」を固めて送る。
> 除外されるのは隠しファイルと `.gitignore` / `.pubignore` に載っているものだけで、
> **git に未追跡なだけのファイルは除外されない**。
>
> 実例: ローカルで `flutter test` を走らせると alchemist が失敗差分 PNG を
> `test/golden/failures/` に吐く。これは未追跡だが `.gitignore` に無ければ
> **配布物に永久に焼き込まれる**（`--dry-run` は警告を出さない）。
> 現在は `.gitignore` に登録済みだが、同種の事故を防ぐため公開前に必ず:
>
> ```bash
> git clean -xdn      # 消える対象を確認（-n = dry run）
> git clean -xdf      # 実行
> ```
>
> 不安なら **fresh clone から公開する**のが最も安全:
> ```bash
> git clone https://github.com/willink-oss/pulse_theme /tmp/pulse-release
> cd /tmp/pulse-release && dart pub publish --dry-run
> ```

`--dry-run` が出力するファイルツリーを**目視で読む**。想定外のファイルが 1 つも無いこと。

### 1-2. 手動公開

```bash
cd ~/GitHub/pulse_theme
dart pub publish
```

- ファイルツリーが表示され、最後に `Publish pulse_theme 0.5.0 to pub.dev? (y/N)` と聞かれる。
- 内容を確認して `y` + Enter。
- 認証情報が切れていればブラウザが開くので `yutaro_shirai@i-willink.com` でログインして許可する。
  （資格情報は `~/Library/Application Support/dart/pub-credentials.json`。refresh token を持つので通常は再ログイン不要。
  403 が出る場合はこのファイルを削除して再実行すれば OAuth をやり直せる。）

この時点で `pulse_theme 0.5.0` は**個人の Google アカウント名義**で公開される。
publisher への紐付けは次のステップ。

### 1-3. publisher `i-willink.com` へ transfer

> pub.dev の publisher ID は**検証済みドメイン**。`willink-oss` は GitHub の org 名であって
> publisher ID ではない（pub.dev API は `InvalidInput` を返す）。正しい publisher は **`i-willink.com`**。

dart.dev の原文どおり、新規パッケージを直接 publisher 名義で公開する手段は無い:

> The pub command doesn't support direct publishing a new package to a verified publisher.
> As a temporary workaround, publish new packages to a Google Account,
> and then transfer the package to a publisher.

手順:

1. https://pub.dev/packages/pulse_theme/admin を開く（アップロードした Google アカウントでログイン済みの状態で）
2. publisher 入力欄に `i-willink.com` と入力
3. **Transfer to Publisher** をクリック → 確認ダイアログで OK

実行には「そのパッケージの uploader」かつ「その publisher の admin」の両方の権限が必要。

> **⚠️ この操作は不可逆**。dart.dev 原文: *"You can't reverse this process. Once you transfer a
> package to a publisher, you can't transfer it back to an individual account."*

### 1-4. Automated publishing（Trusted Publisher）を有効化

1. 同じ https://pub.dev/packages/pulse_theme/admin をリロード
2. **Automated publishing** セクション →**Enable publishing from GitHub Actions**
3. 入力する項目は 2 つだけ:

   | 欄 | 値 |
   |---|---|
   | Repository | `willink-oss/pulse_theme` |
   | Tag pattern | `v{{version}}` |

   （npm の trusted publishing と違い **workflow ファイル名の欄は無い**ので探さなくてよい。）

4. 保存

これ以降、`v0.5.1` のようなタグを push するだけで `publish.yml` が自動公開する。

#### 任意のハードニング: Environment 承認を挟む

意図しないタグ push で公開されるのを防ぎたい場合:

1. pub.dev の同セクションで **Require GitHub Actions environment** → 名前 `pub.dev` を入力して保存
2. GitHub の https://github.com/willink-oss/pulse_theme/settings/environments で
   **New environment** → `pub.dev` → Required reviewers に自分を追加
3. **必ずセットで** `.github/workflows/publish.yml` の `publish:` job に `environment: pub.dev` を追加する

> 3 を忘れると以後の自動公開が全部通らなくなる。有効化するなら同じ PR で workflow も直すこと。

### 1-5. `v0.5.0` タグについて

0.5.0 は手動公開なので、タグを打っても pub.dev には何も起きない。
`publish.yml` には**冪等ガード**が入っており、pub.dev に同じバージョンが既に存在する場合は
publish ステップを skip して job は green のままになる。したがって記録目的で

```bash
git tag -a v0.5.0 -m "pulse_theme 0.5.0 — first pub.dev release" <merged-main-sha>
git push origin v0.5.0
```

を打っても安全（`Publish skipped` の notice が出る）。

---

## 2. 通常のリリース（0.5.1 以降）

```bash
# 1. リリースブランチ
git switch main && git pull
git switch -c release/v0.5.1

# 2. pubspec.yaml の version を更新
#    3. CHANGELOG.md に新セクションを追加（append-only。既存セクションは書き換えない）

# 4. ローカルゲート
flutter pub get && flutter analyze && flutter test
dart pub publish --dry-run       # 0 warnings

# 5. PR → CI green → main へマージ
gh pr create --fill
```

マージ後、**main の HEAD** にタグを打つ:

```bash
git switch main && git pull
git tag -a v0.5.1 -m "pulse_theme 0.5.1"
git push origin v0.5.1
```

`publish.yml` が発火し、以下の順で走る:

1. tag と `pubspec.yaml` の version 一致検証（不一致なら公開せず fail）
2. pub.dev に同バージョンが既にあるか照会（あれば skip して green）
3. `flutter pub get` → example の解決 → `flutter analyze` → `flutter test` → `dart pub publish --dry-run`
4. `dart pub publish --force`（OIDC Trusted Publisher）

### タグ運用の注意

- **pub.dev はタグ push 起点の run からしか自動公開を受け付けない。**
  dart.dev 原文: *"Pub.dev rejects publishing from GitHub Actions triggered without a tag."*
  `publish.yml` の `workflow_dispatch` は**ゲート専用**（analyze / test / dry-run のみ）で、公開はしない。
- pre-release（`v0.5.1-beta.1` など）は pub.dev に dist-tag が無いため、
  `^` 制約の解決からは除外される。既存の利用者が勝手に上がることはない。
- タグは必ず **CI green な main のコミット**に打つ。publish 経路に token-codegen-gate は無いので、
  タグ元コミットの CI が通っていることが実質の最終ゲートになる。

---

## 3. golden テストの扱い

**macOS では golden を再生成しないこと。**

golden のラスタは OS / アーキテクチャ間で bit-identical にならない。
committed goldens は **Linux（CI）で生成したもの**でなければ CI が落ちる。

したがって:

- ローカル macOS で `flutter test` を走らせると
  `test/golden/pulse_golden_test.dart` の `PulseButton — variants × sizes` が**必ず 1 件失敗する**。
  これは想定内。**直そうとしない。`--update-goldens` を打たない。**
- 判定は CI（ubuntu, Flutter 3.44.2 ピン）で行う。

golden を意図的に更新する必要があるとき（コンポーネントの見た目を変えた等）:

```bash
gh workflow run golden-update.yml --ref <branch>
gh run watch                                   # 完了を待つ
gh run download <run-id> -n ci-goldens -D /tmp/ci-goldens
cp /tmp/ci-goldens/*.png test/golden/goldens/ci/
git add test/golden/goldens/ci && git commit -m "test(golden): refresh CI goldens"
```

Flutter のピン（`ci.yml` / `publish.yml` の `flutter-version`）を上げるときは、
goldens の再生成と**同じ PR**で行うこと。

---

## 4. トークン codegen との関係

`lib/src/tokens/pulse_tokens.dart` は `@willink-labs/tokens`（DTCG JSON, npm）からの**生成物**。
手で編集しない。CI の `token-codegen-gate` が公開済みトークン契約から再生成して差分ゼロを要求する。

トークン側が更新されたときは:

```bash
npm --prefix tool ci            # package-lock.json のピンを更新するなら npm --prefix tool install
node tool/generate_tokens.mjs
git diff -- lib/src/tokens/pulse_tokens.dart
```

---

## 5. リリース前チェックリスト

- [ ] `git status --porcelain` が空（`git clean -xdf` 済み、または fresh clone）
- [ ] `pubspec.yaml` の `version` と CHANGELOG の最新見出しが一致
- [ ] `description` が 60〜180 文字（pana の配点対象）
- [ ] README に「未公開」「coming soon」等の古い記述が残っていない
- [ ] README / doc 内のバージョン表記（`^0.x.y`）が新バージョンと一致
- [ ] CHANGELOG が「実際に存在するファイル」だけを列挙している
- [ ] `flutter analyze` → No issues（root と `example/` の両方）
- [ ] `flutter test` → golden 1 件のみ失敗（macOS）／CI では全 green
- [ ] `dart pub publish --dry-run` → **0 warnings**、ファイルツリーに想定外のものが無い
- [ ] main の HEAD で CI が green（`gh run list --branch main`）

---

## 6. 取り消しについて

**公開は実質不可逆。** 出す前に上のチェックリストを通すこと。

| 操作 | 条件 | 効果 |
|---|---|---|
| **retract** | 公開から **7 日以内** | 削除ではない。「Retracted versions」欄に残り RETRACTED バッジが付く。新規の依存解決からは外れる。retract から 7 日以内なら復元可 |
| **unpublish** | 誤公開かつ **48 時間以内**に申請、かつ広く使われていないこと | pub.dev モデレータの判断による例外措置。権利として行使できるものではない |
| **discontinued** | いつでも | 検索から外れ非推奨表示になるが、**既存の依存者からは消えない** |

dart.dev 原文: *"a published package lasts forever"* / *"Retraction isn't deletion."*

---

## 7. 消費者への展開

公開後、依存側を更新する:

- **clubhouse** — PR #34（`chore/migrate-to-pulse-theme`）の git 依存ブロックを
  `pulse_theme: ^0.5.0` に差し替え、`flutter pub get` で `pubspec.lock` を再生成してから ready for review。
- **その他の社内アプリ**（tsuu / nami / willink-chess 等）— theme 系依存が無く SDK 互換なので
  `pulse_theme: ^0.5.0` を追加するだけで採用できる。
- 導入手順そのものは [`doc/adoption.md`](adoption.md) を参照。

`willink_theme`（pub.dev, 1.5.0）は PULSE に置き換わったので、
clubhouse の移行完了後に discontinued にする。**順序を守ること**（先に discontinued にしない）。
