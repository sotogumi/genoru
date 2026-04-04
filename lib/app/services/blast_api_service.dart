import 'dart:convert';
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

    final response = await http.post(uri, body: body);

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
      body: {'CMD': 'Get', 'FORMAT_TYPE': 'XML', 'RID': jobId},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get BLAST results ($jobId): ${response.statusCode}',
      );
    }

    return await _parseXmlResults(response.body, queryLen: queryLen);
  }

  /// XML結果から [SearchResultItem] のリストを作成
  Future<List<SearchResultItem>> _parseXmlResults(
    String xmlString, {
    int queryLen = 1,
  }) async {
    final allHits = <SearchResultItem>[];

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
            allHits.add(
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

      // まずカバレッジ＆一致率両方80%以上のものを抽出
      var hits = allHits.where((h) => h.identity >= 80.0).toList();
      int limitCount = 10;

      // 検索結果が０件だった場合のみ、カバレッジ80パーセントのものに緩和し、上位3つとする
      if (hits.isEmpty) {
        hits = allHits;
        limitCount = 3;
      }

      // ステップ1: カバレッジが高い順に並べる
      hits.sort((a, b) {
        final compCoverage = b.coverage.compareTo(a.coverage);
        if (compCoverage != 0) return compCoverage;
        return b.identity.compareTo(a.identity);
      });

      // ステップ2: 80%未満排除（パース時に if で事前処理済み）

      // ステップ3: 残ったものの中で一致率が高い順に並べる
      hits.sort((a, b) {
        final compIdentity = b.identity.compareTo(a.identity);
        if (compIdentity != 0) return compIdentity;
        return b.coverage.compareTo(a.coverage);
      });

      // ステップ4: 生物名が重なっているものは一番最初のもの（= 一致率最高）のみ残し、あとは排除する
      final uniqueHits = <SearchResultItem>[];
      final seenTitles = <String>{};

      for (final item in hits) {
        String cleanTitle = item.title;

        // ゲノムアセンブリなどの文言をカット
        final stopWords = [
          ' chromosome',
          ' isolate',
          ',',
          ' genome assembly',
          ' complete genome',
          ' dna',
          ' mrna',
          ' grch',
          ' clone',
          ' mutant',
          ' strain',
        ];

        for (final word in stopWords) {
          final lowerTitle = cleanTitle.toLowerCase();
          final idx = lowerTitle.indexOf(word);
          if (idx != -1) {
            cleanTitle = cleanTitle.substring(0, idx);
          }
        }
        cleanTitle = cleanTitle.trim();
        item.title = cleanTitle;

        if (!seenTitles.contains(cleanTitle)) {
          seenTitles.add(cleanTitle);
          uniqueHits.add(item);
        }
      }

      // ステップ5: 残ったものを順番に表示してリミットを超える場合は排除する
      final finalHitsCount =
          uniqueHits.length > limitCount ? limitCount : uniqueHits.length;
      final finalHits = uniqueHits.sublist(0, finalHitsCount);

      // 上位残ったものだけ日本語へ翻訳
      for (int i = 0; i < finalHits.length; i++) {
        final translated = await _translateToJapanese(finalHits[i].title);
        finalHits[i].translatedTitle = translated;
      }

      return finalHits;
    } catch (e) {
      print('XML parsing error: $e');
    }
    // エラー時は空のリストを返す
    return [];
  }

  /// Google Translate (非公式API) を用いて英語の生物名を日本語に翻訳
  Future<String> _translateToJapanese(String text) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ja&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonRes = json.decode(response.body);
        final List<dynamic> sentences = jsonRes[0];
        String translatedText = '';
        for (var s in sentences) {
          translatedText += s[0].toString();
        }
        return translatedText;
      }
    } catch (e) {
      print('Translation error: $e');
    }
    return text; // エラー時は元の英語をそのまま返す
  }
}
