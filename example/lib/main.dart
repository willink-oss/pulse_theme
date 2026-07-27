// PULSE example — a single-file gallery of every component the package ships.
//
// Copy the `MaterialApp` wiring in [PulseExampleApp] into your own app and you
// are done: `PulseTheme.light()` / `PulseTheme.dark()` are plain Material 3
// `ThemeData`, and every `Pulse*` widget reads its colors from
// `Theme.of(context).colorScheme` — so a `copyWith(colorScheme: ...)` override
// re-brands the whole gallery.

import 'package:flutter/material.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() => runApp(const PulseExampleApp());

/// Root app: the only PULSE wiring a consumer app needs.
class PulseExampleApp extends StatelessWidget {
  const PulseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PULSE — pulse_theme example',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.light(),
      darkTheme: PulseTheme.dark(),
      // OS の外観設定に追従（ライト / ダークを自動で切り替える）。
      themeMode: ThemeMode.system,
      home: const GalleryPage(),
    );
  }
}

/// Tabbed gallery hosting the component / empty / error showcases.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // PulseTabBar は TabController を自前で持たない（TabBar と同じ契約）。
    // ここでは DefaultTabController を祖先に置いて委ねる。
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PULSE Gallery'),
          bottom: const PulseTabBar(
            tabs: [
              Tab(text: 'コンポーネント'),
              Tab(text: '空状態'),
              Tab(text: 'エラー'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ComponentsTab(), _EmptyStateTab(), _ErrorStateTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — PulseSectionCard / PulseButton / PulseProgressIndicator /
//         PulseLoadingState / PulseBottomSheet / PulseSnackBar
// ---------------------------------------------------------------------------

class _ComponentsTab extends StatelessWidget {
  const _ComponentsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: PulseSpacing.sm),
      children: const [
        PulseSectionCard(
          title: 'PulseButton — variant × size',
          child: _ButtonMatrix(),
        ),
        PulseSectionCard(
          title: 'PulseButton — isLoading',
          child: _LoadingButtonSample(),
        ),
        PulseSectionCard(
          title: 'PulseProgressIndicator',
          child: _ProgressSample(),
        ),
        PulseSectionCard(title: 'PulseLoadingState', child: _LoadingSample()),
        PulseSectionCard(
          title: 'オーバーレイ（BottomSheet / SnackBar）',
          trailing: Icon(Icons.layers_outlined),
          child: _OverlaySample(),
        ),
      ],
    );
  }
}

class _ButtonMatrix extends StatelessWidget {
  const _ButtonMatrix();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // values を回しているので、variant が増えてもこの表は自動で追従する
        // （danger もここに出る）。
        for (final variant in PulseButtonVariant.values) ...[
          Text(variant.name, style: labelStyle),
          const SizedBox(height: PulseSpacing.sm),
          Wrap(
            spacing: PulseSpacing.sm,
            runSpacing: PulseSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final size in PulseButtonSize.values)
                PulseButton(
                  onPressed: () {},
                  variant: variant,
                  size: size,
                  child: Text(size.name),
                ),
            ],
          ),
          const SizedBox(height: PulseSpacing.lg),
        ],
        Text('icons / disabled', style: labelStyle),
        const SizedBox(height: PulseSpacing.sm),
        Wrap(
          spacing: PulseSpacing.sm,
          runSpacing: PulseSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PulseButton(
              onPressed: () {},
              leadingIcon: const Icon(Icons.check),
              child: const Text('保存'),
            ),
            PulseButton(
              onPressed: () {},
              variant: PulseButtonVariant.outline,
              trailingIcon: const Icon(Icons.arrow_forward),
              child: const Text('次へ'),
            ),
            // danger は filled と同じ形・同じ重さで色だけ違う（破壊的操作に使う）。
            // 色は colorScheme.error なので copyWith(colorScheme:) で再ブランドできる。
            PulseButton(
              onPressed: () {},
              variant: PulseButtonVariant.danger,
              leadingIcon: const Icon(Icons.delete_outline),
              child: const Text('削除'),
            ),
            // onPressed: null で自動的に disabled 表示（opacity 0.5）。
            const PulseButton(onPressed: null, child: Text('無効')),
          ],
        ),
        const SizedBox(height: PulseSpacing.lg),
        Text('fullWidth', style: labelStyle),
        const SizedBox(height: PulseSpacing.sm),
        PulseButton(
          onPressed: () {},
          fullWidth: true,
          child: const Text('横幅いっぱい'),
        ),
      ],
    );
  }
}

/// `isLoading` の実演 — 押すと 3 秒だけ「送信中」になり、終わったら SnackBar で知らせる。
///
/// 見どころは **ボタンの幅が変わらない** こと: ラベルは透明のまま同じ場所に残り、
/// スピナーだけが上に重なるので、フォーム送信でレイアウトが跳ねない。
class _LoadingButtonSample extends StatefulWidget {
  const _LoadingButtonSample();

  @override
  State<_LoadingButtonSample> createState() => _LoadingButtonSampleState();
}

class _LoadingButtonSampleState extends State<_LoadingButtonSample> {
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);

    // 実アプリではここが API 呼び出し。
    await Future<void>.delayed(const Duration(seconds: 3));

    // await をまたぐので、context / setState の前に mounted を確認する。
    if (!mounted) return;
    setState(() => _saving = false);
    PulseSnackBar.show(
      context,
      message: 'プロフィールを保存しました',
      variant: PulseSnackBarVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'isLoading 中はラベルを隠してスピナーに差し替えるだけなので、ボタンの幅は変わらない。'
          'タップは効かなくなるが disabled（opacity 0.5）とは別状態なので減光しない。',
        ),
        const SizedBox(height: PulseSpacing.lg),
        PulseButton(
          // isLoading 側がタップを止めるので、ハンドラは外さなくてよい。
          onPressed: _submit,
          isLoading: _saving,
          leadingIcon: const Icon(Icons.cloud_upload_outlined),
          // 処理中はボタンが disabled として読み上げられるため、
          // これが無いと状態変化が無音になる。必ず渡すこと。
          loadingSemanticsLabel: '保存中',
          child: const Text('プロフィールを保存'),
        ),
      ],
    );
  }
}

class _ProgressSample extends StatelessWidget {
  const _ProgressSample();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('determinate — value は 0.0〜1.0（React 側の 0〜100 とは別スケール）'),
        SizedBox(height: PulseSpacing.sm),
        PulseProgressIndicator(value: 0.65, semanticsLabel: 'アップロード進捗'),
        SizedBox(height: PulseSpacing.lg),
        Text('indeterminate — value を省略'),
        SizedBox(height: PulseSpacing.sm),
        PulseProgressIndicator(semanticsLabel: '処理中'),
      ],
    );
  }
}

class _LoadingSample extends StatelessWidget {
  const _LoadingSample();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 132,
          height: 96,
          child: PulseLoadingState(message: '読み込み中...'),
        ),
        SizedBox(
          width: 64,
          height: 96,
          child: PulseLoadingState.compact(semanticsLabel: '読み込み中'),
        ),
        SizedBox(
          width: 64,
          height: 96,
          child: Center(child: PulseLoadingState.inline(semanticsLabel: '処理中')),
        ),
      ],
    );
  }
}

class _OverlaySample extends StatelessWidget {
  const _OverlaySample();

  /// `PulseBottomSheet.show<T>()` は `Navigator.pop(context, value)` に渡した
  /// 値で解決する（バリアタップ / ドラッグで閉じた場合は null）。
  Future<void> _openSheet(BuildContext context) async {
    final applied = await PulseBottomSheet.show<bool>(
      context,
      builder:
          (sheetContext) => PulseBottomSheet(
            title: 'フィルター',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ここに任意のコンテンツを置けます。'),
                const SizedBox(height: PulseSpacing.lg),
                PulseButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  fullWidth: true,
                  child: const Text('適用'),
                ),
              ],
            ),
          ),
    );

    // await をまたぐので、context を再利用する前に mounted を確認する。
    if (!context.mounted) return;
    final ok = applied ?? false;
    PulseSnackBar.show(
      context,
      message: ok ? 'フィルターを適用しました' : 'キャンセルしました',
      variant: ok ? PulseSnackBarVariant.success : PulseSnackBarVariant.info,
    );
  }

  void _showSnackBar(BuildContext context, PulseSnackBarVariant variant) {
    switch (variant) {
      case PulseSnackBarVariant.info:
        PulseSnackBar.show(context, message: '情報メッセージです');
      case PulseSnackBarVariant.success:
        PulseSnackBar.show(context, message: '保存しました', variant: variant);
      case PulseSnackBarVariant.warning:
        // warning は「処理は通ったが要注意」。
        // 何も起きなかった（＝やり直しが要る）ときは error を使う。
        PulseSnackBar.show(
          context,
          message: '一部の項目を同期できませんでした',
          description: '未同期の3件は次回の同期でまとめて再送されます',
          variant: variant,
        );
      case PulseSnackBarVariant.error:
        // actionLabel と onAction は必ずセットで渡す（片方だけは assert で落ちる）。
        PulseSnackBar.show(
          context,
          message: '保存に失敗しました',
          description: '時間をおいて再試行してください',
          variant: variant,
          actionLabel: '再試行',
          onAction: () {},
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PulseSpacing.sm,
      runSpacing: PulseSpacing.sm,
      children: [
        PulseButton(
          onPressed: () => _openSheet(context),
          variant: PulseButtonVariant.outline,
          leadingIcon: const Icon(Icons.tune),
          child: const Text('BottomSheet を開く'),
        ),
        for (final variant in PulseSnackBarVariant.values)
          PulseButton(
            onPressed: () => _showSnackBar(context, variant),
            variant: PulseButtonVariant.ghost,
            size: PulseButtonSize.small,
            child: Text('SnackBar: ${variant.name}'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 / 3 — 画面まるごとを占める状態コンポーネント
// ---------------------------------------------------------------------------

class _EmptyStateTab extends StatelessWidget {
  const _EmptyStateTab();

  @override
  Widget build(BuildContext context) {
    return PulseEmptyState(
      icon: Icons.inbox_outlined,
      title: 'まだデータがありません',
      description: '最初の項目を追加すると、ここに一覧が表示されます。',
      actionLabel: '項目を追加',
      actionIcon: Icons.add,
      onAction:
          () => PulseSnackBar.show(
            context,
            message: '追加しました',
            variant: PulseSnackBarVariant.success,
          ),
    );
  }
}

class _ErrorStateTab extends StatelessWidget {
  const _ErrorStateTab();

  @override
  Widget build(BuildContext context) {
    return PulseErrorState(
      title: '読み込みに失敗しました',
      // message を省略すると error.toString() が表示され、そのままコピーできる。
      error: 'SocketException: Failed host lookup (api.example.com)',
      onRetry:
          () => PulseSnackBar.show(
            context,
            message: '再試行しています…',
          ),
    );
  }
}
