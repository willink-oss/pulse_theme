# pulse_theme example

`pulse_theme` が提供する全 9 コンポーネントを 1 画面で確認できるギャラリーアプリ。
**このディレクトリは「動く導入サンプル」**で、`lib/main.dart` の `PulseExampleApp` を
そのまま自分のアプリにコピーすれば PULSE の配線は完了する。

導入手順の解説は [`../doc/adoption.md`](../doc/adoption.md) を参照。

---

## 実行

このリポジトリにはプラットフォーム別の runner（`android/` `ios/` `web/` …）を
コミットしていない（配布物を小さく保つため）。初回だけ生成する。

```bash
cd example
flutter create .        # 初回のみ — runner を生成
flutter pub get
flutter run
```

`flutter create .` は既存の `lib/` `test/` `pubspec.yaml` を上書きしない。

---

## 何を示しているか

| タブ | 内容 |
|---|---|
| **コンポーネント** | `PulseButton`（variant × size の全組み合わせ）、`PulseProgressIndicator`（determinate / indeterminate）、`PulseLoadingState`（default / compact / inline）、`PulseBottomSheet` と `PulseSnackBar` の起動 — いずれも `PulseSectionCard` に載せている |
| **空状態** | `PulseEmptyState`（アイコン + タイトル + 説明 + CTA） |
| **エラー** | `PulseErrorState`（リトライ / コピーボタン付き） |

`PulseTabBar` は上部のタブ自体。

### 押さえておきたい点

- **視覚確認はライトモード固定** — `MaterialApp` は
  `themeMode: ThemeMode.light` で起動し、OS の外観設定には左右されない。
- **fit-ai の青が既定** — ブランドは fit-ai のトークン由来。fit-ai の
  `brand.primary` (`#2E7BFF`) を `brand-500` に厳密保持し、操作色には
  fit-ai 自身が持つ `brand.primaryDeep` (`#1D5FD0`) を `brand-600` として使う。
  白文字は前者だと 3.89:1 で AA を割るが、後者なら 5.83:1 で満たす。
- **再ブランドはファクトリの `colorScheme` 引数** — 別ブランドにする場合は
  `PulseTheme.light(colorScheme: ...)` にカスタム scheme を渡す。
  `PulseTheme.light().copyWith(colorScheme: ...)` では**効かない**（component theme が構築時の
  scheme から焼き込み済みで、素の Material ウィジェットはそちらを読むため）。
  このギャラリ自体は既定色だけを表示し、契約差は `theme_contract_test.dart` で固定している。
- **`PulseTabBar` は `TabController` を自前で持たない**（Material の `TabBar` と同じ契約）。
  この例では `DefaultTabController` を祖先に置いている。
- **`PulseBottomSheet.show<T>()`** は `Navigator.pop(context, value)` に渡した値で解決する
  （バリアタップやドラッグで閉じた場合は `null`）。

---

## テスト

```bash
cd example
flutter test
```

ギャラリーが実際に描画され、BottomSheet → SnackBar の往復が動くことを検証する
smoke test が入っている。CI（`flutter-gate`）でも実行されるので、
公開されている example が壊れたまま放置されることはない。

> テストが `shaders/ink_sparkle.frag` のエラーで落ちる場合はビルド成果物が古い。
> `flutter clean && flutter pub get` で解消する。

---

## このパッケージについて

`publish_to: 'none'` を指定しているので、この example 自体が pub.dev に公開されることはない。
`pulse_theme` を `path: ../` で参照しているため、常にこのリポジトリの作業ツリーの
コードに対して動く。
