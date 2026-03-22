import 'package:flutter/material.dart';
import 'package:genoru/app/theme/app_theme.dart';
import 'package:genoru/app/widgets/dna_background.dart';

/// 検索結果のモックモデル
class SearchResultItem {
  final String accession;
  String title; // 外部APIで翻訳するためミュータブルに変更
  final double identity;
  final double coverage;
  final double eValue;

  SearchResultItem({
    required this.accession,
    required this.title,
    required this.identity,
    required this.coverage,
    required this.eValue,
  });
}

/// BLAST検索結果を表示する画面
class SearchResultScreen extends StatelessWidget {
  final String searchSequence;
  final List<SearchResultItem> results;

  const SearchResultScreen({
    super.key,
    required this.searchSequence,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final int displayCount = results.length > 10 ? 10 : results.length;
    final bool hasMoreThan10 = results.length >= 10;

    return Scaffold(
      body: Stack(
        children: [
          const DnaBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── ヘッダー ──
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
                          '📊 検索結果',
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

                // ── 結果リスト ──
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount:
                        displayCount +
                        2, // +1 for the header, +1 for the footer
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasMoreThan10
                                    ? '10件以上の類似配列が見つかりました\n上位10件を表示します'
                                    : '${results.length}件の類似配列が見つかりました',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  fontSize: 18,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '検索クエリ: ${_previewSequence(searchSequence)}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (index == displayCount + 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 40),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              icon: const Icon(Icons.home_rounded, size: 22),
                              label: const Text(
                                '最初の画面に戻る',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentCyan,
                                side: BorderSide(
                                  color: AppTheme.accentCyan.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final item = results[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildResultCard(context, item: item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 結果アイテムのカードUI
  Widget _buildResultCard(
    BuildContext context, {
    required SearchResultItem item,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardDark.withValues(alpha: 0.8),
            AppTheme.surfaceDark.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMetric(
                label: '一致率 (Identity)',
                value: '${item.identity.toStringAsFixed(1)}%',
                color: _getColorForPercentage(item.identity),
                valueSize: 24,
                labelSize: 12,
              ),
              Container(
                width: 1,
                height: 35,
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
              _buildStatMetric(
                label: 'カバレッジ',
                value: '${item.coverage.toStringAsFixed(1)}%',
                color: _getColorForPercentage(item.coverage),
                valueSize: 14,
                labelSize: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric({
    required String label,
    required String value,
    required Color color,
    double valueSize = 16,
    double labelSize = 11,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontSize: labelSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 100.0) return AppTheme.accentCyan; // 100%
    if (percentage >= 90.0) return const Color(0xFF4CAF50); // 90~99% (Green)
    if (percentage >= 80.0) return const Color(0xFFFFB300); // 80~89% (Amber)
    return const Color(0xFFE53935); // 79%以下 (Red)
  }

  /// 配列の先頭と末尾を表示し、長い場合は中間を省略
  String _previewSequence(String seq) {
    if (seq.length <= 20) return seq;
    final head = seq.substring(0, 8);
    final tail = seq.substring(seq.length - 8);
    return '$head...$tail';
  }
}
