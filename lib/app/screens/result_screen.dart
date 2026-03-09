import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genoru/app/screens/search_loading_screen.dart';
import 'package:genoru/app/theme/app_theme.dart';
import 'package:genoru/app/widgets/dna_background.dart';

/// DNA 変換結果を表示する画面
class ResultScreen extends StatelessWidget {
  final String inputText;
  final String dnaSequence;

  const ResultScreen({
    super.key,
    required this.inputText,
    required this.dnaSequence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // DNA螺旋アニメーション背景
          const DnaBackground(),

          // メインコンテンツ
          SafeArea(
            child: Column(
              children: [
                // ── AppBar 風ヘッダー ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.accentCyan,
                              ],
                            ).createShader(bounds),
                        child: Text(
                          '🧬 変換結果',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── スクロール可能なカードエリア ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── 入力テキストカード ──
                        _buildCard(
                          context,
                          icon: Icons.text_fields_rounded,
                          title: '入力テキスト',
                          child: SelectableText(
                            inputText,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.6),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── DNA 配列カード ──
                        _buildCard(
                          context,
                          icon: Icons.biotech_rounded,
                          title: 'DNA 配列',
                          trailing: IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: dnaSequence),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('DNA配列をコピーしました'),
                                  backgroundColor: AppTheme.surfaceDark,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: AppTheme.accentCyan,
                              size: 20,
                            ),
                            tooltip: 'コピー',
                          ),
                          child: SelectableText(
                            _formatDna(dnaSequence),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              letterSpacing: 2,
                              height: 1.8,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── 塩基組成カード ──
                        _buildCard(
                          context,
                          icon: Icons.pie_chart_rounded,
                          title: '塩基組成',
                          child: _buildComposition(context),
                        ),

                        const SizedBox(height: 20),

                        // ── 文字数情報 ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat(
                                context,
                                label: '入力文字数',
                                value: '${inputText.length}',
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              _buildStat(
                                context,
                                label: '塩基数',
                                value: '${dnaSequence.length}',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── 似ている塩基配列を探すボタン ──
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  AppTheme.accentCyan,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SearchLoadingScreen(
                                          dnaSequence: dnaSequence,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search_rounded, size: 22),
                              label: const Text(
                                '似ている塩基配列を探す',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// カード UI を構築するヘルパー
  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardDark.withValues(alpha: 0.8),
            AppTheme.surfaceDark.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 18),
              ),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// DNA 配列を 4 文字ごとにスペースで区切って見やすくする
  String _formatDna(String dna) {
    final buffer = StringBuffer();
    for (int i = 0; i < dna.length; i++) {
      buffer.write(dna[i]);
      if ((i + 1) % 4 == 0 && i + 1 != dna.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  /// 各塩基の割合を 2×2 グリッドで表示
  Widget _buildComposition(BuildContext context) {
    final total = dnaSequence.length;
    final counts = {'A': 0, 'T': 0, 'G': 0, 'C': 0};
    for (final ch in dnaSequence.split('')) {
      counts[ch] = (counts[ch] ?? 0) + 1;
    }

    const baseColors = {
      'A': Color(0xFF4CAF50),
      'T': Color(0xFFFF7043),
      'G': Color(0xFF42A5F5),
      'C': Color(0xFFAB47BC),
    };

    Widget cell(String base) {
      final ratio = total > 0 ? counts[base]! / total : 0.0;
      final pct = (ratio * 100).toStringAsFixed(1);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            base,
            style: TextStyle(
              color: baseColors[base],
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$pct%',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Center(child: cell('A'))),
            Expanded(child: Center(child: cell('T'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Center(child: cell('G'))),
            Expanded(child: Center(child: cell('C'))),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 22,
            color: AppTheme.accentCyan,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
