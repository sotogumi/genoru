import 'package:flutter/material.dart';
import 'package:genoru/app/screens/result_screen.dart';
import 'package:genoru/app/theme/app_theme.dart';
import 'package:genoru/app/widgets/dna_background.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final int _maxLength = 200;
  String? _errorText;
  bool _isButtonEnabled = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    setState(() {
      if (text.isEmpty) {
        _errorText = null;
        _isButtonEnabled = false;
      } else if (text.length > _maxLength) {
        _errorText = '$_maxLength文字以内で入力してください';
        _isButtonEnabled = false;
      } else {
        _errorText = null;
        _isButtonEnabled = true;
      }
    });
  }

  void _onConvertPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = '文字を入力してください';
      });
      return;
    }
    if (text.length > _maxLength) {
      setState(() {
        _errorText = '$_maxLength文字以内で入力してください';
      });
      return;
    }

    // TODO: ATGC変換ロジックを実装する
    final dnaSequence = '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(inputText: text, dnaSequence: dnaSequence),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = _textController.text.length;

    return Scaffold(
      body: Stack(
        children: [
          // DNA螺旋アニメーション背景
          const DnaBackground(),

          // メインコンテンツ
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // ── ロゴ・タイトル ──
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.accentCyan,
                              ],
                            ).createShader(bounds),
                        child: Text(
                          '🧬 ゲノる',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'あなたの言葉をDNAに変換しよう',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 48),

                    // ── 入力カード ──
                    Container(
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
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.05,
                            ),
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
                              const Icon(
                                Icons.edit_note_rounded,
                                color: AppTheme.primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '文字列を入力',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 18),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // テキスト入力欄
                          TextField(
                            controller: _textController,
                            maxLines: 5,
                            minLines: 3,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.6),
                            decoration: InputDecoration(
                              hintText: '好きな言葉、名前、文章を入力…',
                              errorText: _errorText,
                              errorMaxLines: 2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 文字数カウンター
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$currentLength / $_maxLength',
                                style: TextStyle(
                                  color:
                                      currentLength > _maxLength
                                          ? AppTheme.errorRed
                                          : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight:
                                      currentLength > _maxLength
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── DNAに変換するボタン ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient:
                              _isButtonEnabled
                                  ? const LinearGradient(
                                    colors: [
                                      AppTheme.primaryGreen,
                                      AppTheme.accentCyan,
                                    ],
                                  )
                                  : LinearGradient(
                                    colors: [
                                      Colors.grey.shade800,
                                      Colors.grey.shade700,
                                    ],
                                  ),
                          boxShadow:
                              _isButtonEnabled
                                  ? [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: ElevatedButton.icon(
                          onPressed:
                              _isButtonEnabled ? _onConvertPressed : null,
                          icon: const Icon(Icons.transform_rounded, size: 22),
                          label: const Text(
                            'DNAに変換する',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 注意文 ──
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
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '個人情報は入力しないでください。\n同じ文字列は同じDNA配列に変換されます。',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
