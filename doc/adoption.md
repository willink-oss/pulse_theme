# PULSE 導入ガイド（社内 Flutter アプリ向け）

`pulse_theme` を自分のアプリに入れて使い始めるための実務ガイド。
このページ 1 枚で「導入 → テーマ配線 → トークン利用 → コンポーネント → 移行 → 運用」まで通せることを目標にしている。

本文中の API は、すべて本リポジトリの以下のソースを実際に読んで裏を取ったものだけを記載している。
記載が無い引数・メンバーは「存在しない」か「公開 API ではない」と考えてよい。

- `lib/pulse_theme.dart`（公開 export の唯一の入口）
- `lib/src/pulse_theme.dart`
- `lib/src/tokens/pulse_tokens.dart`
- `lib/src/theme_extensions/pulse_brand_tokens.dart`
- `lib/src/components/*.dart`（9 コンポーネント）

---

## 1. 前提

| 項目 | 要件 |
|---|---|
| Dart SDK | `^3.7.0`（= `>=3.7.0 <4.0.0`） |
| Flutter | `>=3.22.0` |
| パッケージ名 | `pulse_theme` |
| 配布先 | pub.dev |
| publisher | `i-willink.com` |
| ライセンス | MIT |
| リポジトリ | https://github.com/willink-oss/pulse_theme |

`pulse_theme` の実行時依存は **Flutter SDK のみ**（`pubspec.yaml` の `dependencies:` は `flutter: sdk: flutter` の 1 行だけ）。
サードパーティ依存をアプリに持ち込まないので、バージョン解決の衝突要因はほぼ SDK 制約だけになる。

Material 3 前提（`ThemeData(useMaterial3: true)`）。Material 2 のアプリにそのまま載せる想定はしていない。

> **未確認**: pub.dev 上での公開状態（初回公開が完了しているか）は、本ドキュメント作成時点では検証していない。
> `flutter pub add` が `Could not find package pulse_theme` で失敗する場合は、まだ初回公開前の可能性がある。

---

## 2. 導入

```bash
flutter pub add pulse_theme
```

または `pubspec.yaml` に直接書く。

```yaml
dependencies:
  # PULSE — i-Willink mobile-first Design System (Material 3 ThemeData factory)
  pulse_theme: ^0.5.0
```

```bash
flutter pub get
```

### caret（`^`）の意味論 — 0.x では特に注意

Dart / pub の caret は **メジャーが 0 のときだけ挙動が変わる**。

| 指定 | 実際の許容範囲 |
|---|---|
| `^1.2.3` | `>=1.2.3 <2.0.0`（メジャーが上がるまで許容） |
| `^0.5.0` | **`>=0.5.0 <0.6.0`**（**マイナー**が上がるまでしか許容しない） |

つまり `^0.5.0` を指定した場合、`0.5.1` / `0.5.9` は自動で上がるが、`0.6.0` は上がらない。
これは pub の仕様が「0.x はマイナーが破壊的変更を運ぶ」と扱っているためで、PULSE も **1.0.0 に到達するまで、マイナー昇格（0.5 → 0.6）で破壊的変更が入りうる**運用にしている（→ [9. アップグレード方針](#9-アップグレード方針)）。

`pulse_theme: ^0.5.0` と書いておけば、破壊的変更が勝手に入ってくることはない。
上げるときは明示的に `^0.6.0` に書き換える、という運用でよい。

### import

公開 API はすべて barrel 1 本から出ている。`src/` 以下を直接 import しないこと。

```dart
import 'package:pulse_theme/pulse_theme.dart';
```

barrel が export しているシンボルは以下の 20 個で全部（`lib/pulse_theme.dart` の実体）。

`PulseTheme` / `PulseBrandTokens` /
`PulsePrimitives` / `PulseSemantics` / `PulseSemanticsDark` / `PulseSpacing` / `PulseFontSize` / `PulseShadows` /
`PulseButton` / `PulseButtonVariant` / `PulseButtonSize` /
`PulseEmptyState` / `PulseErrorState` / `PulseLoadingState` /
`PulseSectionCard` / `PulseTabBar` / `PulseBottomSheet` /
`PulseSnackBar` / `PulseSnackBarVariant` / `PulseProgressIndicator`

---

## 3. テーマ配線

`PulseTheme` は `ThemeData` のファクトリ。実在するメンバーは **`light()` と `dark()` の 2 つの static メソッドだけ**（どちらも引数なし・戻り値 `ThemeData`）。
コンストラクタは private（`const PulseTheme._()`）なのでインスタンス化はできない。

```dart
import 'package:flutter/material.dart';
import 'package:pulse_theme/pulse_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyApp',
      theme: PulseTheme.light(),
      darkTheme: PulseTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

`PulseTheme.light()` / `dark()` が設定しているもの（`lib/src/pulse_theme.dart` の `_base()`）:

- `useMaterial3: true` / `brightness` / `colorScheme`
- `scaffoldBackgroundColor`（= `colorScheme.surface`）
- `textTheme`（後述）
- `extensions: [PulseBrandTokens.pulse]`（dark は `PulseBrandTokens.pulseDark`）
- `appBarTheme` / `cardTheme` / `filledButtonTheme` / `elevatedButtonTheme` / `outlinedButtonTheme` / `textButtonTheme` / `inputDecorationTheme` / `dividerTheme` / `chipTheme` / `progressIndicatorTheme`

### TextTheme について（既存アプリで見た目が動く箇所）

`PulseTheme` の `TextTheme` は **`fontSize` だけ**を 7 ロールに設定し、weight / letter-spacing は Material のデフォルトのままにしている。

| ロール | fontSize | 由来 |
|---|---|---|
| `headlineMedium` | 30 | `PulseFontSize.fontSize3xl` |
| `headlineSmall` | 24 | `PulseFontSize.fontSize2xl` |
| `titleLarge` | 20 | `PulseFontSize.fontSizeXl` |
| `titleMedium` | 18 | `PulseFontSize.fontSizeLg` |
| `bodyLarge` | 16 | `PulseFontSize.fontSizeBase` |
| `bodyMedium` | 14 | `PulseFontSize.fontSizeSm` |
| `bodySmall` | 12 | `PulseFontSize.fontSizeXs` |

`display*` と `label*` は **設定していない**（Material デフォルトのまま）。
テキスト色も設定していないので `colorScheme.onSurface` に追従する。

既存アプリが素の `ThemeData` から乗り換えると、この 7 ロールのサイズが数 px 動く。スクリーンショット差分が出るのは想定内。

---

## 4. トークンの使い方

### 4.1 まず `colorScheme` を使う

色は原則として `Theme.of(context).colorScheme` から取る。
`PulseSemantics` / `PulsePrimitives` を直接参照すると **ライト固定値をハードコードすることになり、ダークモードで破綻する**（どちらも `static const` の生値で、モードに追従しない）。

```dart
final colors = Theme.of(context).colorScheme;
Container(color: colors.surface, child: Text('...', style: TextStyle(color: colors.onSurface)));
```

直接参照してよいのは、`ColorScheme` に対応スロットが無いロール（`success` / `warning` など）に限る。その場合も自分でモード分岐すること。

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final success = isDark ? PulseSemanticsDark.success : PulseSemantics.success;
```

### 4.2 `PulseSpacing` — 余白（実在する 6 定数がすべて）

```dart
PulseSpacing.xs   // 4.0
PulseSpacing.sm   // 8.0
PulseSpacing.md   // 16.0
PulseSpacing.lg   // 24.0
PulseSpacing.xl   // 32.0
PulseSpacing.xxl  // 48.0
```

```dart
Padding(
  padding: const EdgeInsets.all(PulseSpacing.md),
  child: Column(
    children: [
      const Text('見出し'),
      const SizedBox(height: PulseSpacing.sm),
      const Text('本文'),
    ],
  ),
)
```

### 4.3 `PulseFontSize` — 文字サイズ（メンバー名に注意）

**プレフィックスが付く**。`PulseFontSize.xs` ではなく `PulseFontSize.fontSizeXs`。

```dart
PulseFontSize.fontSizeXs    // 12.0
PulseFontSize.fontSizeSm    // 14.0
PulseFontSize.fontSizeBase  // 16.0
PulseFontSize.fontSizeLg    // 18.0
PulseFontSize.fontSizeXl    // 20.0
PulseFontSize.fontSize2xl   // 24.0
PulseFontSize.fontSize3xl   // 30.0
```

とはいえ通常は `Theme.of(context).textTheme.*` を使う方がよい（`PulseTheme` が上表のとおり配線済み）。

### 4.4 `PulseSemantics` / `PulseSemanticsDark` — 意味づけされた色ロール

両クラスとも同じ 26 個のメンバーを持つ（`PulseSemanticsDark` は `$extensions["willink.dark"]` によるフリップ）。

```
bg / fg / muted
fgStrong / fgEmphasis / fgSecondary / fgSubtle / fgFaint
border / surfaceSubtle / surfaceMuted / track
surfaceInverted / surfaceInvertedFg / ring
brand / brandFg / brandGlow / brandHover / brandActive / brandSoft / brandSoftFg
accentCyan / accentPink
success / warning / danger
```

これらの大半は `PulseTheme` が `ColorScheme` にマップ済み（例: `brand` → `primary`、`bg` → `surface`、`fg` → `onSurface`、`muted` → `onSurfaceVariant`、`border` → `outline` / `outlineVariant`、`danger` → `error`、`track` → `surfaceContainerHighest`）。
`ColorScheme` に行き先が無いのは `success` / `warning` / `brandHover` / `brandActive` / `ring` / `surfaceInverted` / `fg*` の細分などで、これらが直接参照の主な用途になる。

### 4.5 `PulsePrimitives` — 生の値（色 / 半径 / 時間 / イージング）

色は原則使わない（意味を持たないため）。実務で使うのは半径・時間・カーブ。

```dart
// Radius（logical px）
PulsePrimitives.radiusSm    // 4.0
PulsePrimitives.radiusMd    // 8.0
PulsePrimitives.radiusLg    // 12.0
PulsePrimitives.radiusXl    // 16.0
PulsePrimitives.radiusFull  // 9999.0

// Duration
PulsePrimitives.durationFast  // 150ms
PulsePrimitives.durationBase  // 250ms
PulsePrimitives.durationSlow  // 400ms

// Easing（Cubic）
PulsePrimitives.easingStandard    // Cubic(0.2, 0, 0, 1)
PulsePrimitives.easingEmphasized  // Cubic(0.3, 0, 0, 1.1)
```

色プリミティブは `neutral50..950` / `brand50..950` / `blue50..950` / `green50,100,500,600,700` / `cyan500` / `pink500` / `sky50` / `sky500` / `red500` / `red600` / `amber500` / `amber600`。

```dart
AnimatedContainer(
  duration: PulsePrimitives.durationBase,
  curve: PulsePrimitives.easingStandard,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(PulsePrimitives.radiusLg),
  ),
  child: child,
)
```

### 4.6 `PulseShadows` — 影（`List<BoxShadow>` 5 種）

```dart
PulseShadows.soft      // 通常のソフト影（ライト）
PulseShadows.softDark  // 同・ダーク（黒アルファを上げたもの）
PulseShadows.md        // 2 段重ねの中間影（ライト）
PulseShadows.mdDark    // 同・ダーク
PulseShadows.glow      // ブランド着色のグロー（モード不変）
```

### 4.7 `PulseBrandTokens` — ThemeExtension（Material で表現できないもの）

`ColorScheme` では表現できないグラデーション / グロー / カスタム影を運ぶ `ThemeExtension`。
`PulseTheme.light()` / `dark()` が `extensions` に自動で載せているので、アプリ側での登録は不要。

**取り出し方**（型名は `PulseBrandTokens`）:

```dart
final brand = Theme.of(context).extension<PulseBrandTokens>()!;
```

> `!` を付けているのは、`PulseTheme.light()` / `dark()` 経由なら必ず存在するため。
> `PulseTheme` を使わない `ThemeData` の下でこのコードを踏むと null になるので、共通 Widget に書く場合は `?` + フォールバックにするのが安全。

実在するフィールドは 6 つ。

| フィールド | 型 | 内容 |
|---|---|---|
| `brandGlow` | `Color` | グロー影のベース色 |
| `brandGradient` | `LinearGradient` | ヒーロー用（brand600 → blue600 斜め）。**ライト / ダーク共通** |
| `subtleGradient` | `LinearGradient` | 控えめな背景。ライト = white→brand50→sky50 / ダーク = neutral950→brand950→neutral900 |
| `aiGradient` | `LinearGradient` | AI 系演出専用（cyan500 → brand500 → pink500）。**ライト / ダーク共通**。汎用には使わない |
| `shadowSoft` | `List<BoxShadow>` | ライト = `PulseShadows.soft` / ダーク = `PulseShadows.softDark` |
| `shadowGlow` | `List<BoxShadow>` | `PulseShadows.glow`。**ライト / ダーク共通** |

`copyWith(...)` と `lerp(...)` も実装済み（`ThemeExtension` の契約どおり）。
プリセットの static インスタンスは `PulseBrandTokens.pulse`（ライト）と `PulseBrandTokens.pulseDark`（ダーク）の 2 つ。

```dart
final brand = Theme.of(context).extension<PulseBrandTokens>()!;

Container(
  decoration: BoxDecoration(
    gradient: brand.brandGradient,
    borderRadius: BorderRadius.circular(PulsePrimitives.radiusXl),
    boxShadow: brand.shadowSoft,
  ),
  padding: const EdgeInsets.all(PulseSpacing.lg),
  child: const Text('ヒーロー'),
)
```

---

## 5. コンポーネント早見表

9 コンポーネント。**下表の引数がすべて**（各ソースのコンストラクタから起こしたもの）。
すべて色を `Theme.of(context).colorScheme` から実行時に読むので、テーマ切り替え・ブランド上書きに追従する。

| コンポーネント | 用途 |
|---|---|
| `PulseButton` | ブランド対応ボタン（filled / outline / ghost / danger）+ `isLoading` |
| `PulseEmptyState` | データが無い画面の空状態 + CTA |
| `PulseErrorState` | エラー表示（コピー / 再試行つき） |
| `PulseLoadingState` | ローディング（全画面 / セクション内 / インライン） |
| `PulseSectionCard` | タイトル付きのセクション面 |
| `PulseTabBar` | Material 3 タブバー（`AppBar.bottom` に挿せる） |
| `PulseBottomSheet` | モーダルボトムシート |
| `PulseSnackBar` | スナックバー（info / success / warning / error） |
| `PulseProgressIndicator` | 横棒の進捗バー |

### 5.1 `PulseButton`

| 引数 | 型 | 既定値 |
|---|---|---|
| `onPressed` | `VoidCallback?` | **必須**（`null` を渡すと disabled: 不透明度 0.5・リップル無し） |
| `child` | `Widget` | **必須** |
| `variant` | `PulseButtonVariant` | `filled` |
| `size` | `PulseButtonSize` | `medium` |
| `leadingIcon` | `Widget?` | `null`（ラベルの左に 8px ギャップで配置） |
| `trailingIcon` | `Widget?` | `null`（右に 8px ギャップ） |
| `fullWidth` | `bool` | `false` |
| `isLoading` | `bool` | `false`（`true` でスピナー表示＋タップ不可。**減光はしない**） |
| `loadingSemanticsLabel` | `String?` | `null`（`isLoading` 中のスクリーンリーダー読み上げ） |

- `PulseButtonVariant` = `filled` / `outline` / `ghost` / `danger`
- `PulseButtonSize` = `small`（padding 12×6・14px）/ `medium`（16×10・16px）/ `large`（24×14・18px）

```dart
PulseButton(
  onPressed: () => save(),
  variant: PulseButtonVariant.filled,
  size: PulseButtonSize.medium,
  leadingIcon: const Icon(Icons.check),
  child: const Text('保存'),
)
```

#### `danger` — 破壊的操作

削除 / 取り消し / 解約などに使う。実体は `filled` と同じ `FilledButton`（同じ shape・padding・角丸 8・同じグロー影）で、色だけが違う。

色は **`colorScheme.error` / `colorScheme.onError`** から取る。固定トークンの `PulseSemantics.danger` は使っていないので、[6 章](#6-ブランド色の上書き)の `copyWith(colorScheme: ...)` でブランドを差し替えると `filled` と同じように追従する。

> **ライト / ダークで文字色が違う**。ライトは赤 600 の上に白（4.83:1）。ダークの `error` は明るい赤 500（`#EF4444`）なので、白だと 3.76:1 で WCAG AA（4.5:1）を割る。そのためダークの `onError` だけは白ではなく背景インク `#020617` を使っている（5.36:1）。`copyWith` で `error` を差し替えるときは `onError` も一緒に見直すこと（[7.2](#72-アプリ側がやること) の 3）。

```dart
PulseButton(
  onPressed: () => deleteAccount(),
  variant: PulseButtonVariant.danger,
  leadingIcon: const Icon(Icons.delete_outline),
  child: const Text('削除する'),
)
```

> `danger` があるのは **solid の 1 種類だけ**。`outline` / `ghost` の danger 版（枠線だけ赤・文字だけ赤）は**無い**。
> 「破壊的だが弱い見せ方をしたい」場合は、`ghost` にアプリ側で `Text(style: TextStyle(color: colors.error))` を渡すなど、呼び出し側で作ること。

#### `isLoading` — 送信中

**disabled とは別の状態**。`onPressed: null`（disabled）が「今は押せない」を意味するのに対し、`isLoading` は「押した結果を待っている」を意味する。

| | 見た目 | タップ |
|---|---|---|
| `onPressed: null`（disabled） | 不透明度 0.5 に減光・グロー無し | 不可 |
| `isLoading: true` | **減光しない**（`filled` / `danger` はグローも出たまま）。ラベルの代わりに中央にスピナー | 不可 |

- スピナーは `CircularProgressIndicator(strokeWidth: 2)` で、サイズは size に対応するフォントサイズ（small 14 / medium 16 / large 18）、色は前景色。
- **ボタンの幅は変わらない**。ラベルは `Opacity(opacity: 0, alwaysIncludeSemantics: true)` でレイアウトだけ残しているため、フォーム送信の瞬間にレイアウトが跳ねない。
- **ボタン名（accessible name）は失われない**。上記の `alwaysIncludeSemantics: true` により、見えないラベルもセマンティクスツリーに残る。`loadingSemanticsLabel` を渡さなくてもボタン自身のテキスト（例: `保存`）は読み上げられ、渡した場合は「`保存` + `保存中`」の両方が読まれる。
- `isLoading: true` のあいだ Material ボタンには `onPressed: null` が渡る。つまり**支援技術には disabled として報告される**。`loadingSemanticsLabel` が伝えるのはこの**状態**の方で、渡さないと「処理中である」ことが無音になる（名前が無音になるのではない）。送信ボタンには必ず渡すこと（`PulseLoadingState.semanticsLabel` が `semanticsLabel ?? message` でフォールバックするのと同じ発想）。

```dart
PulseButton(
  onPressed: _submit,          // isLoading 中は無視される（null が渡る）
  isLoading: _isSubmitting,
  loadingSemanticsLabel: '保存中',
  fullWidth: true,
  child: const Text('保存'),
)
```

#### 無いもの（設計判断）

`PulseButton` に **任意色を渡す口は無い**。`backgroundColor` / `foregroundColor` / `style` といった引数は存在しない。

色は必ず `colorScheme`（`primary` / `onPrimary`、`danger` なら `error` / `onError`）から実行時に読む。DS として色を呼び出し側に開放しないのは意図的な設計で、再ブランドの正道は [6 章](#6-ブランド色の上書き)の `copyWith(colorScheme: ...)` 一本。
どうしても DS 外の色が要る 1 箇所は、`PulseButton` を使わず素の `FilledButton` を書く方が正直（DS のボタンに見えて DS に従わないものを増やさない）。

### 5.2 `PulseEmptyState`

| 引数 | 型 | 既定値 |
|---|---|---|
| `icon` | `IconData` | **必須**（80px で表示） |
| `title` | `String` | **必須** |
| `description` | `String?` | `null` |
| `actionLabel` | `String?` | `null` |
| `onAction` | `VoidCallback?` | `null` |
| `actionIcon` | `IconData?` | `null` → `Icons.add` にフォールバック |

CTA ボタンは **`actionLabel` と `onAction` の両方が非 null のときだけ**描画される。片方だけ渡しても出ない。

```dart
PulseEmptyState(
  icon: Icons.inbox,
  title: 'まだ記録がありません',
  description: '最初の記録を作成してみましょう',
  actionLabel: '記録を作成',
  onAction: () => context.push('/new'),
)
```

### 5.3 `PulseErrorState`

引数はすべて任意（`const PulseErrorState()` だけで成立する）。

| 引数 | 型 | 既定値 |
|---|---|---|
| `title` | `String` | `'エラーが発生しました'` |
| `message` | `String?` | `null`（null なら `error.toString()` を表示） |
| `error` | `Object?` | `null`（クリップボードコピー用。`message` があれば表示はされない） |
| `onRetry` | `VoidCallback?` | `null`（null なら再試行ボタン非表示） |
| `retryLabel` | `String` | `'再試行'` |
| `showCopyButton` | `bool` | `true` |
| `copySuccessMessage` | `String` | `'エラー内容をコピーしました'` |

> 既定文言は日本語ハードコード。コピーボタンのラベル `'エラーをコピー'` は**引数化されていない**ので、多言語対応が必要なアプリでは `showCopyButton: false` にして自前のボタンを置く。

```dart
asyncValue.when(
  data: (d) => Content(d),
  loading: () => const PulseLoadingState(message: '読み込み中...'),
  error: (err, _) => PulseErrorState(
    title: '読み込みに失敗しました',
    error: err,
    onRetry: () => ref.invalidate(myProvider),
  ),
)
```

### 5.4 `PulseLoadingState`

コンストラクタ 3 種。

| コンストラクタ | 引数 | spinner サイズ |
|---|---|---|
| `PulseLoadingState({message, size = 40, semanticsLabel})` | `String? message` / `double size` / `String? semanticsLabel` | 既定 40 |
| `PulseLoadingState.compact({message, semanticsLabel})` | 同上（`size` は 24 固定） | 24 |
| `PulseLoadingState.inline({semanticsLabel})` | `semanticsLabel` のみ（`message` は常に null） | 16 |

スクリーンリーダーのラベルは `semanticsLabel ?? message`。`inline` はメッセージを持てないので、**`semanticsLabel` を明示しないと無音になる**。

```dart
const PulseLoadingState(message: '読み込み中...');
const PulseLoadingState.compact(message: '同期中');
const PulseLoadingState.inline(semanticsLabel: '送信中');
```

### 5.5 `PulseSectionCard`

| 引数 | 型 | 既定値 |
|---|---|---|
| `child` | `Widget` | **必須** |
| `title` | `String?` | `null`（`Semantics(header: true)` 付きで描画） |
| `trailing` | `Widget?` | `null`（**`title` が null のときは無視される**） |
| `onTrailingTap` | `VoidCallback?` | `null` |
| `padding` | `EdgeInsetsGeometry?` | `null` → 内側 `PulseSpacing.lg`（`title` があれば上だけ 0） |
| `margin` | `EdgeInsetsGeometry?` | `null` → `EdgeInsets.all(PulseSpacing.lg)` |

```dart
PulseSectionCard(
  title: '今週の実績',
  trailing: const Icon(Icons.chevron_right),
  onTrailingTap: () => context.push('/weekly'),
  child: const Text('本文'),
)
```

### 5.6 `PulseTabBar`

`PreferredSizeWidget` を実装しているので `AppBar.bottom` にそのまま挿せる。

| 引数 | 型 | 既定値 |
|---|---|---|
| `tabs` | `List<Widget>` | **必須**（通常 `Tab`。長さは controller の `length` と一致必須） |
| `controller` | `TabController?` | `null` → 祖先の `DefaultTabController` を使う |
| `onTap` | `ValueChanged<int>?` | `null` |
| `isScrollable` | `bool` | `false` |

```dart
DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
      title: const Text('設定'),
      bottom: const PulseTabBar(
        tabs: [Tab(text: 'アカウント'), Tab(text: 'パスワード')],
      ),
    ),
    body: const TabBarView(children: [AccountForm(), PasswordForm()]),
  ),
)
```

### 5.7 `PulseBottomSheet`

Widget 本体（中身のスキャフォールド）と、開くための static ヘルパーの 2 つで構成される。

Widget:

| 引数 | 型 | 既定値 |
|---|---|---|
| `child` | `Widget` | **必須** |
| `title` | `String?` | `null`（18px / w600・`Semantics(header: true)`） |

`PulseBottomSheet.show<T>(...)`:

| 引数 | 型 | 既定値 |
|---|---|---|
| `context` | `BuildContext` | **必須**（位置引数） |
| `builder` | `WidgetBuilder` | **必須** |
| `isScrollControlled` | `bool` | `false` |
| `showDragHandle` | `bool` | `true`（32×4 の自前ハンドル） |
| `isDismissible` | `bool` | `true` |
| `enableDrag` | `bool` | `true` |
| `useSafeArea` | `bool` | `false` |

戻り値は `Future<T?>`（`Navigator.pop(context, value)` の値。バリアタップ等で閉じたら `null`）。

```dart
final applied = await PulseBottomSheet.show<bool>(
  context,
  builder: (context) => PulseBottomSheet(
    title: 'フィルター',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FilterForm(),
        PulseButton(
          fullWidth: true,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('適用'),
        ),
      ],
    ),
  ),
);
```

### 5.8 `PulseSnackBar`

インスタンス化しない。static の `show` のみ。

`PulseSnackBar.show(context, {...})`:

| 引数 | 型 | 既定値 |
|---|---|---|
| `context` | `BuildContext` | **必須**（位置引数） |
| `message` | `String` | **必須** |
| `description` | `String?` | `null` |
| `variant` | `PulseSnackBarVariant` | `info` |
| `actionLabel` | `String?` | `null` |
| `onAction` | `VoidCallback?` | `null` |
| `duration` | `Duration` | `Duration(milliseconds: 4000)` |

- `PulseSnackBarVariant` = `info`（`colorScheme.primary`）/ `success`（`PulseSemantics.success`）/ `warning`（`PulseSemantics.warning` = amber600 `#D97706`）/ `error`（`colorScheme.error`）
- `actionLabel` と `onAction` は **必ず両方セットで渡す**（片方だけだと `assert` で落ちる）
- 戻り値は `ScaffoldFeatureController<SnackBar, SnackBarClosedReason>`

**`warning` と `error` の使い分け**（ここを混ぜると通知の意味が死ぬ）:

| variant | 意味 | 例 |
|---|---|---|
| `warning` | **処理は通った**が要注意 | 一部だけ同期できた / 上限に近い / 表示中のデータが古い |
| `error` | **処理されなかった** | 保存失敗 / 通信エラー / バリデーション不合格 |

`success` と同じ流儀で、`warning` の色は固定トークン `PulseSemantics.warning` を使う（`colorScheme` に warning スロットが無いため）。したがってダークモードでも同じ amber600 が出る。アイコンは `Icons.warning_amber_rounded`。

```dart
PulseSnackBar.show(context, message: '保存しました', variant: PulseSnackBarVariant.success);

PulseSnackBar.show(
  context,
  message: '10 件中 8 件を同期しました',
  description: '2 件は後で再試行してください',
  variant: PulseSnackBarVariant.warning,
);

PulseSnackBar.show(
  context,
  message: '保存に失敗しました',
  description: '時間をおいて再試行してください',
  variant: PulseSnackBarVariant.error,
  actionLabel: '再試行',
  onAction: () => save(),
);
```

### 5.9 `PulseProgressIndicator`

| 引数 | 型 | 既定値 |
|---|---|---|
| `value` | `double?` | `null` = 不定（indeterminate）。指定時は **`0.0`〜`1.0`**（範囲外は `assert` で落ちる） |
| `minHeight` | `double` | `8` |
| `borderRadius` | `BorderRadiusGeometry?` | `null` → `minHeight / 2`（完全な丸） |
| `semanticsLabel` | `String?` | `null` |

> React DS の `Progress` は 0–100 スケール。Web から値を移植するときは **100 で割る**。

```dart
const PulseProgressIndicator(value: 0.65);
const PulseProgressIndicator(semanticsLabel: 'アップロード中'); // 不定
```

---

## 6. ブランド色の上書き

`ColorScheme` を差し替えるだけ。`Pulse*` コンポーネントは実行時に `Theme.of(context).colorScheme` を読むので、上書きがそのまま流れる。

```dart
MaterialApp(
  theme: PulseTheme.light().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB), // = PulsePrimitives.blue600
    ),
  ),
  darkTheme: PulseTheme.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
  home: const HomePage(),
);
```

`PulseButton` については、この上書きが効くことを本リポジトリのテストが保証している
（`test/pulse_button_test.dart` の `respects copyWith(colorScheme: ...) override`）。
`PulseButton` は自前で `backgroundColor: colors.primary` を実行時に注入するため、確実に追従する。

### ⚠ `copyWith(colorScheme:)` の効果範囲（重要）

`ThemeData.copyWith` は `colorScheme` フィールドを差し替えるだけで、**`PulseTheme` が構築時に焼き込んだ各コンポーネントテーマ（`filledButtonTheme` / `outlinedButtonTheme` / `chipTheme` / `inputDecorationTheme` など）は再計算されない**。
`_base()` はこれらを構築時の `colorScheme` から組み立てているため、上書き後も旧ブランド色が残る。

影響するのは「素の Material ウィジェット」および「内部で素の Material ウィジェットを使う PULSE コンポーネント」。具体的には:

- 素の `FilledButton` / `ElevatedButton` / `OutlinedButton` / `TextButton` / `Chip` / `TextField`
- `PulseEmptyState` の CTA（内部が `FilledButton.icon`）
- `PulseErrorState` の再試行ボタン（内部が `FilledButton`）とコピーボタン（`TextButton.icon`）

全面的に再ブランドしたい場合は、`colorScheme` と併せてボタン系テーマも上書きする。

```dart
final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB));

final theme = PulseTheme.light().copyWith(
  colorScheme: scheme,
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
  ),
  // 必要に応じて outlinedButtonTheme / textButtonTheme / chipTheme / inputDecorationTheme も
);
```

> **未確認**: 上記の「component theme が追従しない」はソース（`ThemeData.copyWith` の仕様 + `_base()` の実装）からの帰結であり、実機・テストでの実測はしていない。
> 再ブランドを行うアプリは、`PulseEmptyState` / `PulseErrorState` の CTA 色を必ず目視確認すること。

`PulseBrandTokens`（グラデーション / グロー）も差し替えたい場合は `extensions` を上書きする。

```dart
PulseTheme.light().copyWith(
  extensions: <ThemeExtension<dynamic>>[
    PulseBrandTokens.pulse.copyWith(
      brandGradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)]),
    ),
  ],
);
```

---

## 7. アクセシビリティ

### 7.1 PULSE が担保している（テストで守られている）こと

| 項目 | 内容 | 根拠 |
|---|---|---|
| タップターゲット 48dp | `PulseButton` の `small` / `medium` / `large` 全サイズが Android のタップターゲットガイドラインを満たす（`minimumSize: Size.zero` + Material の `padded` tap target を維持） | `test/pulse_button_test.dart` — `meetsGuideline(androidTapTargetGuideline)` を 3 サイズで実行 |
| ライブリージョン | `PulseErrorState` が `Semantics(container: true, liveRegion: true)`。エラーが表示された瞬間に読み上げられる | `test/harden_test.dart` D2 |
| 見出しロール | `PulseSectionCard.title` / `PulseBottomSheet.title` が `Semantics(header: true)` | `test/harden_test.dart` D2 |
| スピナーのラベル | `PulseLoadingState` が `semanticsLabel ?? message` を `CircularProgressIndicator.semanticsLabel` に渡す | `test/harden_test.dart` D2 |
| 送信中ボタンの名前 | `PulseButton(isLoading: true)` は `loadingSemanticsLabel` 無しでもボタン名（`child` のテキスト）を失わない | `test/pulse_button_test.dart` — 「keeps an accessible name when loadingSemanticsLabel is null」 |
| 塗りバリアントのコントラスト | `filled` / `danger` の (塗り, 文字) が light / dark とも WCAG AA 4.5:1 以上。実測: filled light 5.70 / danger light 4.83 / filled dark 5.70 / danger dark 5.36 | `test/a11y_contrast_test.dart` |
| 文字拡大耐性 | `PulseButton` / `PulseLoadingState` / `PulseEmptyState` / `PulseErrorState` / `PulseSectionCard` が **360×640 の画面 × TextScaler 2.0× / 3.0×** でオーバーフローしない（`PulseEmptyState` / `PulseErrorState` は収まらない場合スクロールする） | `test/harden_test.dart` D4 |
| 進捗の読み上げ | `PulseProgressIndicator` は `semanticsLabel` を受け取り、determinate 時は Flutter が％も読む | `lib/src/components/pulse_progress_indicator.dart` |

**未確認 / 保証範囲外**:
`PulseTabBar` / `PulseSnackBar` / `PulseBottomSheet` / `PulseProgressIndicator` は上記の TextScaler 無オーバーフロー試験の対象に**含まれていない**（D4 のケース一覧が 5 コンポーネントのみ）。

コントラストの自動検証は**塗りバリアントの (塗り, 文字) ペアだけ**に入っている（上表）。**面（surface）の上に載る文字色は対象外**で、既知の未達がある:

- **ダークの `outline` / `ghost` のラベル**（`primary` = brand600 `#7C3AED` を `surface` = `#020617` の上に描く）は **3.54:1** で、通常サイズ文字の AA（4.5:1）に届かない。ライトは 5.70:1 で問題ない。ダークで `outline` / `ghost` を主要導線に使うなら、アプリ側で `copyWith(colorScheme:)` の `primary` を明るくするか `filled` を使うこと。
- スナックバー / タブバー / 各種 muted テキストのコントラストは未測定。

これらは 0.5.0 時点の既知の状態であり、直近の変更で悪化したものではない（`danger` のダークだけは 0.5.0 で導入と同時に修正済み）。

### 7.2 アプリ側がやること

PULSE を入れただけでは満たせない。以下はアプリの責任。

1. **画像・アイコンの代替テキスト**
   - 意味を持つ画像は `Semantics(label: '...', image: true, child: Image...)` または `Image(semanticLabel: '...')`。
   - 装飾のみの画像は `ExcludeSemantics` で読み上げから除外する。
   - `PulseButton` の `leadingIcon` / `trailingIcon` は**アイコン単体のラベルを持たない**。ラベルが `child` のテキストだけになるので、アイコンのみのボタンを作る場合は自分で `Semantics(label: ...)` を巻く。
2. **フォーカス順序**
   - `FocusTraversalGroup` / `FocusTraversalOrder` で論理順を保証する。PULSE はレイアウト順以上の制御をしない。
   - モーダル（`PulseBottomSheet`）を開いたあとの初期フォーカス位置は、必要ならアプリ側で `FocusScope` を使って指定する。
3. **コントラスト検証**
   - `copyWith(colorScheme: ...)` でブランド色を差し替えた瞬間、PULSE 側のコントラスト前提は無効になる。差し替えたら WCAG AA（通常テキスト 4.5:1 / 大きい文字 3:1）を自分で測る。
   - ダークモードも別途測る。
4. **画面単位の文字拡大確認**
   - PULSE のコンポーネント単体は 3.0× まで検証済みだが、**画面全体の合成レイアウトは未検証**。`MediaQuery` の `textScaler` を上げた状態で主要画面を通しで確認する。
5. **フォーム要素のラベル / 状態**
   - `TextField` などは PULSE のスコープ外（`inputDecorationTheme` の見た目のみ提供）。`labelText` / エラー状態の読み上げはアプリ側で担保する。
6. **`isLoading` の読み上げラベル**
   - `PulseButton(isLoading: true)` は内部で `onPressed: null` になるため、**支援技術には disabled として報告される**。ボタン名は残る（見えないラベルがセマンティクスツリーに残るので「保存 / disabled」までは伝わる）が、`loadingSemanticsLabel` を渡さないと**処理中であること**が無音になる。送信ボタンには必ず付けること（例: `loadingSemanticsLabel: '保存中'`）。

---

## 8. `willink_theme` からの移行

### 8.1 位置づけ

- `willink_theme`（`Willink*` シンボル）は **discontinued**。PULSE が正統な後継。
- PULSE は `willink_theme` の Flutter 実装（i-Willink 自身の MIT ライセンスコード）をクリーンルームで再ブランドしたもの。
- Web 側（`@willink-labs/react` 等）は改名されていない。トークン SSOT（`@willink-labs/tokens`）も共通のまま。

> **未確認**: pub.dev 上で `willink_theme` に実際に discontinued フラグが立っているかは本ドキュメント作成時点で検証していない（社内方針としての discontinued は確定）。

### 8.2 シンボル対応表

引数シグネチャは全コンポーネントで同一。実質 **1:1 のシンボル rename** で移行できる。

| willink_theme (1.5.0) | pulse_theme (0.5.0) |
|---|---|
| `WillinkTheme.willink()` | `PulseTheme.light()` |
| `WillinkTheme.willinkDark()` | `PulseTheme.dark()` |
| `WillinkSpacing.{xs,sm,md,lg,xl,xxl}` | `PulseSpacing.{同名}`（値も 4/8/16/24/32/48 で同一） |
| `WillinkPrimitives` | `PulsePrimitives` |
| `WillinkSemantics` | `PulseSemantics` |
| `WillinkBrandTokens` | `PulseBrandTokens` |
| `WillinkButton` / `WillinkButtonVariant` / `WillinkButtonSize` | `PulseButton` / `PulseButtonVariant` / `PulseButtonSize` |
| `WillinkEmptyState` | `PulseEmptyState` |
| `WillinkErrorState` | `PulseErrorState` |
| `WillinkSectionCard` | `PulseSectionCard` |
| `WillinkTabBar` | `PulseTabBar` |
| `WillinkBottomSheet` / `.show<T>(...)` | `PulseBottomSheet` / `.show<T>(...)` |
| `WillinkProgressIndicator` | `PulseProgressIndicator` |
| `WillinkSnackBar.show(...)` / `WillinkSnackBarVariant` | `PulseSnackBar.show(...)` / `PulseSnackBarVariant` |

**PULSE でのみ使える追加 API**（移行による非破壊的な upside）:
`PulseSemanticsDark` / `PulseFontSize` / `PulseShadows` の公開 export、
`PulseBrandTokens.pulse` / `.pulseDark` の static プリセット、
`PulseLoadingState` の `semanticsLabel` 引数と `.compact` / `.inline` コンストラクタ、
`PulseButtonVariant.danger`、`PulseButton` の `isLoading` / `loadingSemanticsLabel`、
`PulseSnackBarVariant.warning`。

**PULSE で消えた willink API は無い**（`WillinkBrand` enum / `WillinkTheme.clublink()` は `willink_theme` 0.5.0 の時点で既に削除済み）。

> **出典の注記**: 右列（`Pulse*`）は本リポジトリのソースを直接読んで確認した。
> 左列（`Willink*`）は事前調査フェーズの監査結果（`willink-design-system/packages/flutter_theme` の barrel + 各コンポーネントのコンストラクタ突合）に基づく。本ドキュメント作成時に willink 側ソースを再読していない。

### 8.3 移行手順

```diff
 dependencies:
-  # i-Willink Design System (Material 3 ThemeData factory · WillinkBrand.clublink)
-  willink_theme: ^1.5.0
+  # PULSE — i-Willink mobile-first Design System (Material 3 ThemeData factory).
+  pulse_theme: ^0.5.0
```

```bash
flutter pub get   # pubspec.lock を再生成
```

コード側は sed 相当の置換で足りる。

```diff
-import 'package:willink_theme/willink_theme.dart';
+import 'package:pulse_theme/pulse_theme.dart';

-ThemeData get light => WillinkTheme.willink();
+ThemeData get light => PulseTheme.light();

-static const double md = WillinkSpacing.md;
+static const double md = PulseSpacing.md;
```

置換後に `flutter analyze` を通し、`flutter test` を回す。

### 8.4 社内の消費者監査（事前調査フェーズの結果）

- `willink_theme` に依存しているリポジトリは **clubhouse 1 本のみ**（`^1.5.0`）。
  影響範囲は `lib/theme/app_theme.dart` と `lib/theme/app_spacing.dart` の **2 ファイル 5 箇所**だけで、`Willink*` ウィジェットは 1 つも使われていない。アプリ内の 113 箇所の呼び出しは `AppTheme` / `AppSpacing` 経由なので無変更。
- 他の Flutter アプリ（tsuu / nami / willink-chess）は theme 系依存ゼロの greenfield。`pulse_theme: ^0.5.0` を追加するだけで採用できる。
- fit-ai（`apps/mobile`）は最大規模。独自 theme 実装との衝突有無は**未調査**なので、採用前に個別調査が必要。
  ただし独自ウィジェットの監査は済んでおり、その結果が `PulseButtonVariant.danger` / `PulseButton.isLoading` /
  `PulseSnackBarVariant.warning` の追加動機になっている（この 3 つが無いと、既存の `AppButton` /
  warning 系スナックバーを PULSE に置き換えた瞬間に機能後退する）。→ [8.6](#86-アプリ独自ウィジェットからの移行)
- SDK 制約は全アプリで互換（PULSE の `sdk: ^3.7.0` / `flutter: >=3.22.0` が、clubhouse `^3.11.4` / tsuu `^3.7.0` / nami・willink-chess `^3.11.4` / fit-ai `>=3.8.0 <4.0.0` / fit-ai-frontend `^3.8.1` のすべてと交差する）。

### 8.5 移行時に見た目が動く箇所

`PulseTheme.light()` は `TextTheme` を設定する（[3 章](#3-テーマ配線)の表）。
`willink_theme` が Material デフォルトのまま残していた title / headline サイズが **1〜2px 動く**。
許容するか、アプリ側 `AppTheme` で `textTheme` を上書きするかを判断すること。

### 8.6 アプリ独自ウィジェットからの移行

`willink_theme` を経由せず、自前の `AppButton` / `FeedbackSnackBar` を持っているアプリ（fit-ai がこの形）向け。
以下の 3 つは **PULSE 側に対応物があるので 1:1 で置き換えられる**。

| アプリ側によくある形 | PULSE |
|---|---|
| `AppButton(isLoading: true, ...)` | `PulseButton(isLoading: true, loadingSemanticsLabel: '...', ...)` |
| `AppButton(variant: destructive)` / `DangerButton` | `PulseButton(variant: PulseButtonVariant.danger, ...)` |
| `FeedbackSnackBar.showWarning(context, '...')` | `PulseSnackBar.show(context, message: '...', variant: PulseSnackBarVariant.warning)` |

**引数名は 1:1 ではない。** fit-ai の `AppButton`（`apps/mobile/lib/core/widgets/atoms/app_button.dart`）を例に、実際に書き換わるところ:

| `AppButton` | `PulseButton` | 注意 |
|---|---|---|
| `label: '保存'`（`String`・必須） | `child: const Text('保存')`（`Widget`・必須） | **型が変わる**。単純な引数リネームでは通らない |
| `icon: Icons.check`（`IconData?`） | `leadingIcon: const Icon(Icons.check)`（`Widget?`） | こちらも `IconData` → `Widget` |
| `isExpanded: true` | `fullWidth: true` | 名前のみ |
| `isLoading: _isSubmitting` | `isLoading: _isSubmitting` + `loadingSemanticsLabel: '保存中'` | 読み上げラベルは PULSE 側の追加引数（[7.2](#72-アプリ側がやること) の 6） |
| `variant: AppButtonVariant.danger` / `.destructive` | `variant: PulseButtonVariant.danger` | |
| `backgroundColor:` / `foregroundColor:` | **無い** | 色は `colorScheme` からのみ（[5.1 の「無いもの」](#無いもの設計判断)） |

`isLoading` の**見た目には 1 点だけ差がある**（同義ではない）:

- `AppButton._buildChild()` は `isLoading` のときスピナーの `SizedBox` だけを返し**ラベルを捨てる**ので、送信した瞬間にボタンがスピナーの幅まで縮む。
- `PulseButton` はラベルを `Opacity(opacity: 0)` で残すので**幅が変わらない**。

PULSE 側が改善である（フォームのレイアウトが跳ねなくなる）が、移行後に「ボタンが縮まなくなった」という**目に見える変化**として出るので、デザインレビューがあるなら先に伝えておくこと。タップ不可になる点（`isLoading` 中は `onPressed: null` が渡る）は両者同じ。

```diff
-AppButton(
+PulseButton(
   onPressed: _submit,
   isLoading: _isSubmitting,
-  label: '保存',
-  icon: Icons.check,
-  isExpanded: true,
+  loadingSemanticsLabel: '保存中',
+  child: const Text('保存'),
+  leadingIcon: const Icon(Icons.check),
+  fullWidth: true,
 )
```

#### まだ PULSE に無いもの（移行前に確認すること）

自前ウィジェットが以下に依存していると 1:1 では移せない。**回避策込みで先に洗い出すこと。**

| 無いもの | 状況 | 回避策 |
|---|---|---|
| `PulseButton` の任意色上書き（`backgroundColor` / `foregroundColor` / `style`） | **無い。設計判断として開けていない** | 再ブランドは `copyWith(colorScheme: ...)`（[6 章](#6-ブランド色の上書き)）。DS 外の色が必須の 1 箇所は素の `FilledButton` を書く |
| `outline` / `ghost` の danger 版 | **無い**（danger は solid のみ） | `ghost` + `Text(style: TextStyle(color: colors.error))` を呼び出し側で組む |
| アイコンのみのボタン（`IconButton` 相当） | **無い** | `Semantics(label: ...)` を巻いた素の `IconButton` |
| ボタン内の成功アニメーション / チェックマーク遷移 | **無い**（`isLoading` はスピナーのみ） | 呼び出し側で状態を持つ |
| snack bar の任意色 / 任意アイコン | **無い**（4 variant 固定） | 4 つのどれかに寄せる。寄らないものは素の `SnackBar` |

---

## 9. アップグレード方針

### 9.1 0.x のあいだの破壊的変更ポリシー

- PULSE は [SemVer 2.0](https://semver.org/) に従う。**公開 API は `1.0.0` まで凍結しない**。
- 0.x では **マイナー昇格（0.5 → 0.6）が破壊的変更を運ぶ**。pub の caret 意味論とも一致する（`^0.5.0` は `0.6.0` を取り込まない）。
- パッチ昇格（0.5.0 → 0.5.1）は後方互換。バグ修正・内部実装・トークン再生成のみ。
- PULSE は `@willink-labs/*` npm 群とも、レガシーの `willink_theme` とも**独立にバージョニング**される。

### 9.2 CHANGELOG の読み方

`CHANGELOG.md` は Keep a Changelog 形式。バージョンを上げる前に、**現在使っているバージョンの次から順に全節を読む**。

- `Added` — 新 API。既存コードには影響しない。
- `Changed` — 0.x のマイナー昇格の節にあれば**破壊的の可能性がある**。ここを最優先で読む。
- `Fixed` — 見た目が変わることがある（golden テストを持つアプリは差分を見込む）。
- `Removed` — 破壊的。置き換え先が併記されているはず。

`0.4.0` までの履歴は pub.dev には公開されていない（`0.5.0` が pub.dev 初版）が、リポジトリの `CHANGELOG.md` には残っている。

### 9.3 上げ方

```bash
# 現状の解決結果を確認
flutter pub deps --style=compact | grep pulse_theme

# パッチ / 制約内マイナーの取り込み
flutter pub upgrade pulse_theme

# メジャー相当（0.5 → 0.6）は pubspec を手で書き換えてから
#   pulse_theme: ^0.6.0
flutter pub get
flutter analyze
flutter test
```

### 9.4 不具合・要望の出し先

https://github.com/willink-oss/pulse_theme/issues

報告に含めてほしいもの:

- `flutter --version` の出力
- `pulse_theme` の解決済みバージョン（`pubspec.lock` の該当エントリ）
- 再現する最小コード（できれば `MaterialApp(theme: PulseTheme.light(), home: ...)` の形）
- ダーク / ライトどちらで起きるか、`copyWith(colorScheme: ...)` を使っているか
- アクセシビリティ関連なら、`TextScaler` の倍率と画面サイズ

---

## 10. トラブルシュート

### 10.1 バージョン解決の衝突

`pulse_theme` の実行時依存は Flutter SDK のみなので、**サードパーティ由来の衝突は原理的に起きない**。現実的な衝突源は SDK 制約だけ。

```
Because pulse_theme >=0.5.0 requires SDK version ^3.7.0 ...
```

→ アプリの `environment.sdk` が `3.7.0` 未満を許している。アプリ側を上げる。

```bash
# 何が制約を作っているか特定する
flutter pub deps --style=compact
dart pub upgrade --dry-run
```

`flutter_lints` のバージョン差（アプリ `^6.0.0` / PULSE `^5.0.0` 等）は**衝突しない**。
hosted パッケージの `dev_dependencies` は消費者側の解決に参加しないため。

### 10.2 Flutter バージョン不一致

- 要件は `flutter: ">=3.22.0"`。下回ると `pub get` の時点で落ちる。
- PULSE 本体の CI は **Flutter 3.44.2（stable）**にピン留めして検証されている。
  アプリ CI の Flutter を PULSE の検証バージョンと合わせておくと、レンダリング差分の切り分けが楽になる。
- ローカルと CI で Flutter バージョンがずれていると、golden 差分・レイアウト差分の原因が特定できなくなる。`fvm` などでピン留めすること。

### 10.3 golden テストを持つアプリでの注意

**これは実際に踏んだ問題なので必ず読むこと。**

- PULSE を導入 / アップグレードすると、`TextTheme` のサイズ・ボタン形状・角丸などが変わるため、**アプリ側の golden は必ず差分になる**。差分が出ること自体は異常ではない。差分の中身を目視で確認してから更新する。
- **golden PNG は OS / CPU アーキテクチャをまたいで bit-identical にならない。**
  macOS(arm64) で生成した golden は Linux(x64) の CI で一致しない（アンチエイリアスのラスタライズが異なる）。
  → **golden は CI と同じ環境で生成したものをコミットする**。ローカル macOS で `--update-goldens` して push すると CI が赤くなる。
  → PULSE 本体はこれを、Linux 上で golden を再生成する専用の GitHub Actions ワークフロー（`golden-update.yml`）で回避している。同じ構成をアプリ側にも用意するのが確実。
- PULSE 本体は [alchemist](https://pub.dev/packages/alchemist) の **CI golden のみ**（テキストをブロックに平坦化・影を無効化）を使い、ホストのフォント描画差に影響されないようにしている。アプリ側でも同じ方針を取ると差分が安定する。
- なお、PULSE リポジトリ自体を macOS で `flutter test` すると `test/golden/pulse_golden_test.dart` の `PulseButton — variants × sizes` が 1 件失敗する。これは**既知かつ想定内**（コミットされている golden が Linux CI 生成のため）。バグではないので golden を再生成しないこと。

### 10.4 `Theme.of(context).extension<PulseBrandTokens>()` が null

`PulseTheme.light()` / `dark()` を経由していない `ThemeData` の下でウィジェットが構築されている。
テストで `MaterialApp(home: ...)` とだけ書いた場合などに起きる。

```dart
// テストでも必ずテーマを渡す
MaterialApp(theme: PulseTheme.light(), home: Scaffold(body: myWidget));
```

`ThemeData.copyWith(extensions: [...])` で `extensions` を丸ごと差し替えると `PulseBrandTokens` が消えるので、上書きするときは `PulseBrandTokens.pulse.copyWith(...)` を必ずリストに含めること（[6 章](#6-ブランド色の上書き)参照）。

### 10.5 ダークモードで色が変わらない

`PulseSemantics.*` / `PulsePrimitives.*` を直接参照している可能性が高い。これらは `static const` の固定値でモードに追従しない。
`Theme.of(context).colorScheme` 経由に置き換える（[4.1](#41-まず-colorscheme-を使う)）。

### 10.6 `PulseEmptyState` の CTA が出ない

`actionLabel` と `onAction` の**両方**が必要。片方だけではボタンは描画されない。

### 10.7 `PulseSnackBar.show` が assert で落ちる

`actionLabel` と `onAction` は必ずセットで渡す（片方だけは禁止）。

### 10.8 `PulseProgressIndicator` が assert で落ちる

`value` は `0.0`〜`1.0`。Web の React DS は 0–100 スケールなので、移植時は 100 で割る。

---

## 参照

- README: https://github.com/willink-oss/pulse_theme/blob/main/README.md
- ADR: `doc/adr/0001-pulse-mobile-first-architecture.md`
- CHANGELOG: https://github.com/willink-oss/pulse_theme/blob/main/CHANGELOG.md
- Issues: https://github.com/willink-oss/pulse_theme/issues
