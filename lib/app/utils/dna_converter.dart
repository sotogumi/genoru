/// 文字列を DNA 塩基配列 (ATGC) に変換するユーティリティ
///
/// 変換手順:
///   1. 各文字の Unicode コードポイントを取得
///   2. 各コードポイントを 8 ビット（以上）のバイナリ文字列に変換
///   3. バイナリ文字列を 2 ビットずつ区切る
///   4. 00 → A, 01 → T, 10 → G, 11 → C にマッピング
class DnaConverter {
  DnaConverter._();

  static const _baseMap = {'00': 'A', '01': 'T', '10': 'G', '11': 'C'};

  /// [input] を DNA 配列に変換して返す
  static String convertToDna(String input) {
    final buffer = StringBuffer();

    for (final codeUnit in input.codeUnits) {
      // 8 ビット以上のバイナリ文字列（偶数桁になるよう左をゼロ埋め）
      String binary = codeUnit.toRadixString(2);
      if (binary.length % 2 != 0) {
        binary = '0$binary';
      }

      // 2 ビットずつ塩基に変換
      for (int i = 0; i < binary.length; i += 2) {
        final pair = binary.substring(i, i + 2);
        buffer.write(_baseMap[pair]);
      }
    }

    return buffer.toString();
  }
}
