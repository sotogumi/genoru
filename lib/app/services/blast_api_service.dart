import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:genoru/app/screens/search_result_screen.dart';

/// NCBI BLAST REST API と通信するサービス
class BlastApiService {
  static const String _baseUrl =
      'https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi';
  static const String _tool = 'genoru_app';
  static const String _email = 'genoru_app_dummy@example.com';

  /// BLAST 検索へのジョブ送信を行い、JobID (RID) を返す
  Future<String> submitJob(String dnaSequence, {bool isRelaxed = false}) async {
    final uri = Uri.parse(_baseUrl);

    final body = <String, String>{
      'CMD': 'Put',
      'PROGRAM': 'blastn',
      'DATABASE': 'nt',
      'QUERY': dnaSequence,
      'TOOL': _tool,
      'EMAIL': _email,
    };

    if (isRelaxed) {
      body.addAll({
        'MEGABLAST': 'no',
        'WORD_SIZE': '7',
        'EXPECT': '100000',
        'NUCL_PENALTY': '-1',
        'NUCL_REWARD': '1',
        'GAPCOSTS': '2 1',
        'HITLIST_SIZE': '20',
        'FILTER': 'none',
      });
    }

    final response = await http.post(
      uri,
      headers: {'User-Agent': '$_tool/1.0'},
      body: body,
    );

    if (response.statusCode == 200) {
      final resBody = response.body;
      String? rid;
      for (final line in resBody.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('RID =')) {
          rid = trimmed.split('=')[1].trim();
          break;
        }
      }
      if (rid != null && rid.isNotEmpty) {
        return rid;
      } else {
        throw Exception(
          'Failed to extract RID from NCBI response: ${resBody.length > 500 ? resBody.substring(0, 500) : resBody}',
        );
      }
    } else {
      throw Exception('Failed to submit BLAST job: ${response.statusCode}');
    }
  }

  /// ジョブのステータスを確認する
  ///  'WAITING', 'FAILED', 'UNKNOWN', 'FINISHED'
  Future<String> checkStatus(String jobId) async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.post(
      uri,
      headers: {'User-Agent': '$_tool/1.0'},
      body: {'CMD': 'Get', 'FORMAT_OBJECT': 'SearchInfo', 'RID': jobId},
    );

    if (response.statusCode == 200) {
      final resBody = response.body;
      if (resBody.contains('Status=WAITING')) return 'WAITING';
      if (resBody.contains('Status=FAILED')) return 'FAILED';
      if (resBody.contains('Status=UNKNOWN')) return 'UNKNOWN';
      if (resBody.contains('Status=READY'))
        return 'FINISHED'; // Loading Screenは 'FINISHED' で待機を抜けるよう実装されている

      // Fallback
      return 'WAITING';
    } else {
      throw Exception(
        'Failed to check job status ($jobId): ${response.statusCode}',
      );
    }
  }

  /// 完了したジョブの結果 (XML) を取得しパースする
  Future<List<SearchResultItem>> getResults(
    String jobId, {
    int queryLen = 1,
  }) async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.post(
      uri,
      headers: {'User-Agent': '$_tool/1.0'},
      body: {'CMD': 'Get', 'FORMAT_TYPE': 'XML', 'RID': jobId},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get BLAST results ($jobId): ${response.statusCode}',
      );
    }

    return _parseXmlResults(response.body, queryLen: queryLen);
  }

  /// XML結果から [SearchResultItem] のリストを作成
  List<SearchResultItem> _parseXmlResults(
    String xmlString, {
    int queryLen = 1,
  }) {
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
          final coverage = queryLen > 0 ? (alignLen / queryLen) * 100 : 0.0;
          final clampedCoverage = coverage.clamp(0.0, 100.0);

          if (clampedCoverage >= 80.0) {
            hits.add(
              SearchResultItem(
                accession: accession,
                title: title,
                identity: identityPct,
                coverage: clampedCoverage, // gapにより100を超える場合への対処
                eValue: evalue,
              ),
            );
          }
        }
      }

      // カバレッジで降順、一致率で降順にソート（ncbi_api_test.pyと同じ）
      hits.sort((a, b) {
        final compCoverage = b.coverage.compareTo(a.coverage);
        if (compCoverage != 0) return compCoverage;
        return b.identity.compareTo(a.identity);
      });
    } catch (e) {
      print('XML parsing error: $e');
    }
    // 全件を返し、表示側で上位10件に絞る
    return hits;
  }
}
