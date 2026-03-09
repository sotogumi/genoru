import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:genoru/app/screens/search_result_screen.dart';

/// EBI BLAST REST API と通信するサービス
class BlastApiService {
  static const String _baseUrl =
      'https://www.ebi.ac.uk/Tools/services/rest/ncbiblast';
  static const String _email = 'genoru_app_dummy@example.com';

  /// BLAST 検索へのジョブ送信を行い、JobIDを返す
  Future<String> submitJob(String dnaSequence) async {
    final uri = Uri.parse('$_baseUrl/run');
    final response = await http.post(
      uri,
      headers: {'User-Agent': 'genoru_app/1.0'},
      body: {
        'email': _email,
        'stype': 'dna',
        'program': 'blastn',
        'database': 'em_vrl', // 高速化のためウイルスDBをデフォルトとする
        'sequence': '>query\n$dnaSequence',
        'exp': '10',
        'scores': '10',
        'alignments': '5',
      },
    );

    if (response.statusCode == 200) {
      return response.body.trim();
    } else {
      throw Exception(
        'Failed to submit BLAST job: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// ジョブのステータスを確認する
  Future<String> checkStatus(String jobId) async {
    final uri = Uri.parse('$_baseUrl/status/$jobId');
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'genoru_app/1.0'},
    );

    if (response.statusCode == 200) {
      return response.body.trim();
    } else {
      throw Exception(
        'Failed to check job status ($jobId): ${response.statusCode}',
      );
    }
  }

  /// 完了したジョブの結果 (XML) を取得しパースする
  Future<List<SearchResultItem>> getResults(String jobId) async {
    final uri = Uri.parse('$_baseUrl/result/$jobId/xml');
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'genoru_app/1.0'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get BLAST results ($jobId): ${response.statusCode}',
      );
    }

    return _parseXmlResults(response.body);
  }

  /// XML結果から [SearchResultItem] のリストを作成
  List<SearchResultItem> _parseXmlResults(String xmlString) {
    final hits = <SearchResultItem>[];

    try {
      final document = XmlDocument.parse(xmlString);
      final hitElements = document.findAllElements('Hit');

      for (var hitElement in hitElements) {
        final accession =
            hitElement.findElements('Hit_accession').firstOrNull?.innerText ??
            'Unknown';
        final title =
            hitElement.findElements('Hit_def').firstOrNull?.innerText ??
            'No Description';

        final hspElements = hitElement.findAllElements('Hsp');
        for (var hspElement in hspElements) {
          final identityStr =
              hspElement.findElements('Hsp_identity').firstOrNull?.innerText ??
              '0';
          final alignLenStr =
              hspElement.findElements('Hsp_align-len').firstOrNull?.innerText ??
              '1';
          final evalueStr =
              hspElement.findElements('Hsp_evalue').firstOrNull?.innerText ??
              '0';

          final identity = int.tryParse(identityStr) ?? 0;
          final alignLen = int.tryParse(alignLenStr) ?? 1;
          final evalue = double.tryParse(evalueStr) ?? 0.0;

          final identityPct = alignLen > 0 ? (identity / alignLen) * 100 : 0.0;
          // カバレッジ計算は手元の情報がないため、ここでは100.0とする
          final coverage = 100.0;

          hits.add(
            SearchResultItem(
              accession: accession,
              title: title,
              identity: identityPct,
              coverage: coverage,
              eValue: evalue,
            ),
          );
        }
      }

      // 一致率でソート（降順）
      hits.sort((a, b) => b.identity.compareTo(a.identity));
    } catch (e) {
      print('XML parsing error: $e');
    }

    return hits;
  }
}
