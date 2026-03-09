import 'package:flutter/material.dart';
import 'package:genoru/app/screens/search_result_screen.dart';
import 'package:genoru/app/services/blast_api_service.dart';
import 'package:genoru/app/theme/app_theme.dart';
import 'package:genoru/app/widgets/dna_background.dart';

/// BLAST 検索中に表示するローディング画面
class SearchLoadingScreen extends StatefulWidget {
  final String dnaSequence;

  const SearchLoadingScreen({super.key, required this.dnaSequence});

  @override
  State<SearchLoadingScreen> createState() => _SearchLoadingScreenState();
}

class _SearchLoadingScreenState extends State<SearchLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;

  final List<String> _statusMessages = [
    'NCBI データベースに接続中…',
    '塩基配列を送信中…',
    'BLAST 検索を実行中…',
    '類似配列を解析中…',
    '結果を取得中…',
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    // DNA アイコン回転
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // パルスアニメーション
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ステータスメッセージ切り替え
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _dotsController.addListener(() {
      final newIndex =
          (_dotsController.value * _statusMessages.length).floor() %
          _statusMessages.length;
      if (newIndex != _currentMessageIndex) {
        setState(() {
          _currentMessageIndex = newIndex;
        });
      }
    });

    _startBlastSearch();
  }

  Future<void> _startBlastSearch() async {
    try {
      final apiService = BlastApiService();

      setState(() {
        _currentMessageIndex = 0; // 'NCBI データベースに接続中…'
      });

      // 1. ジョブを送信
      setState(() {
        _currentMessageIndex = 1; // '塩基配列を送信中…'
      });
      final jobId = await apiService.submitJob(widget.dnaSequence);
      if (!mounted) return;

      // 2. ステータスポーリング
      setState(() {
        _currentMessageIndex = 2; // 'BLAST 検索を実行中…'
      });

      String status = '';
      int retryCount = 0;
      const maxRetries = 60; // 60 * 5s = 5分

      while (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 5));
        if (!mounted) return;

        status = await apiService.checkStatus(jobId);

        if (status == 'FINISHED') {
          break;
        } else if (status == 'ERROR' ||
            status == 'FAILURE' ||
            status == 'NOT_FOUND') {
          throw Exception('BLAST job failed with status: $status');
        }

        retryCount++;
      }

      if (status != 'FINISHED') {
        throw Exception('BLAST job timed out');
      }

      // 3. 結果の取得とパース
      setState(() {
        _currentMessageIndex = 4; // '結果を取得中…'
      });
      final results = await apiService.getResults(jobId);
      if (!mounted) return;

      // 4. 結果画面へ遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => SearchResultScreen(
                searchSequence: widget.dnaSequence,
                results: results,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // エラー時の処理（スナックバーで通知して元の画面に戻る等）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('検索中にエラーが発生しました:\n$e'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          '🔍 検索中',
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

                // ── ローディングコンテンツ ──
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 回転する DNA アイコン
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: RotationTransition(
                              turns: _rotateController,
                              child: ShaderMask(
                                shaderCallback:
                                    (bounds) => const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.primaryGreen,
                                        AppTheme.accentCyan,
                                      ],
                                    ).createShader(bounds),
                                child: const Icon(
                                  Icons.biotech_rounded,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ステータスメッセージ
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              _statusMessages[_currentMessageIndex],
                              key: ValueKey<int>(_currentMessageIndex),
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // プログレスバー
                          SizedBox(
                            width: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                backgroundColor: AppTheme.cardDark.withValues(
                                  alpha: 0.8,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // 検索中の配列プレビュー
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppTheme.cardDark.withValues(alpha: 0.6),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '検索配列',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _previewSequence(widget.dnaSequence),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.dnaSequence.length} bp',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 注意テキスト
                          Text(
                            'NCBI BLAST で類似配列を検索しています\n通常 30 秒〜数分かかります',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
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

  /// 配列の先頭と末尾を表示し、長い場合は中間を省略
  String _previewSequence(String seq) {
    if (seq.length <= 24) return seq;
    final head = seq.substring(0, 12);
    final tail = seq.substring(seq.length - 12);
    return '$head … $tail';
  }
}
